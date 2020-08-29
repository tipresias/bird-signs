PLAYER_COL_NAMES = c(
  "player_name",
  "playing_for",
  "home_team",
  "away_team",
  "date",
  "match_id"
)

HOME_AWAY <- c("home", "away")


.parse_date_time <- function(date_time_string) {
  lubridate::parse_date_time(
    date_time_string, "%A %b %d %I:%M %p",
    quiet = TRUE
  ) %>%
    # afl.com.au must detect timezone via the browser to display the match times
    # in the user's local time, so they return UTC to our scraper.
    # We convert everything to Melbourne time, because it's close enough,
    # and I don't want to bother figuring out local time for all the venues,
    # even though those are the timezones for raw match data.
    lubridate::with_tz(., tzone = "Australia/Melbourne")
}


.clean_data_frame <- function(roster_df) {
  roster_df %>%
    dplyr::mutate_all(., as.character) %>%
    tidyr::unite("date", c("date", "time"), remove = TRUE, sep = " ") %>%
    dplyr::mutate(
      .,
      player_name = stringr::str_extract(player_name, "[:alpha:]+(?:[:blank:][:alpha:]+)+"),
      # We assume that we only scrape rosters for matches from this year,
      # because any data from past matches are better retrieved from AFL Tables.
      date = .parse_date_time(date),
      round_number = as.numeric(round_number),
      season = lubridate::year(date)
    )
}


.get_round_number <- function(browser) {
  roster_url <- browser$getCurrentUrl()
  # For now, the easiest way to get the round number for the current page is
  # from the URL parameter GameWeeks=<round number>, because the relevant
  # elements are buried under a mountain non-semantic JavaScript rendering.
  # We double extract in the hopes of making it somewhat more robust to potential
  # changes in the URL structure.
  roster_url %>%
    stringr::str_extract(., "GameWeeks=\\d+") %>%
    stringr::str_extract(., "\\d+")
}


.convert_to_data_frame <- function(matches) {
  matches %>%
  dplyr::bind_rows(.) %>%
  tidyr::pivot_wider(
    .,
    id_cols = c(player_name, playing_for, date, time, match_id),
    names_from = team_type,
    values_from = team
  ) %>%
  tidyr::fill(., tidyselect::all_of(HOME_AWAY), .direction = "downup") %>%
  dplyr::rename(., home_team = home, away_team = away)
}


.parse_team_data <- function(match_element, team_type) {
  team_name <- match_element$findChildElement(
    using = "css",
    value = paste0(".team-lineups__team-name--", team_type)
  )$getElementText() %>%
    unlist

  # For team name containers, they use "--home" and "--away"
  # to differentiate between team types, but for player containers,
  # they use "--home" and a blank suffix indicates 'away'
  player_team_type <- if(team_type == "home") "--home" else ""

  team_roster <- match_element$findChildElements(
    using = "css",
    value = paste0(".team-lineups__positions-players-container", player_team_type, " .team-lineups__player")
  ) %>%
    purrr::map(., ~ .x$getElementText()) %>%
    unlist

  tibble::tibble(
    player_name = team_roster,
    playing_for = rep_len(team_name, length(team_roster)),
    team_type = rep_len(team_type, length(team_roster)),
    round_number = rep_len(round_number, length(team_roster))
  ) %>%
    dplyr::mutate(team = playing_for)
}

.parse_match_elements <- function(cumulative_roster_data, match_element) {
  DATE_CLASS <- "match-list__group-date"
  TIME_CLASS <- "match-list-alt__header-time"

  roster_data = rlang::duplicate(cumulative_roster_data)

  element_class <- match_element$getElementAttribute("class")

  if (element_class == DATE_CLASS) {
    roster_data$current_date <- match_element$getElementText() %>% unlist
    return(roster_data)
  }

  if (element_class == TIME_CLASS) {
    roster_data$current_time <- match_element$getElementText() %>% unlist
    return(roster_data)
  }

  current_date <- cumulative_roster_data$current_date
  current_time <- cumulative_roster_data$current_time
  match_id <- cumulative_roster_data$match_id

  current_roster_data <- purrr::map(
    HOME_AWAY, ~ .parse_team_data(match_element, .)
  ) %>%
    purrr::map(., ~ dplyr::mutate(
      .x,
      date = current_date,
      time = current_time,
      match_id = match_id
    ))

  roster_data$roster_data <- c(roster_data$roster_data, current_roster_data)
  roster_data$match_id <- match_id + 1

  return(roster_data)
}

.collect_match_elements <- function(browser) {
  match_roster_elements <- browser$findElements(
    using = "css",
    value = ".match-list__group-date, .match-list-alt__header-time, .team-lineups__wrapper"
  )

  stopifnot(length(match_roster_elements) > 0)

  match_roster_elements
}

.expand_roster_elements <- function(expandable_roster_elements) {
  # We need to wait a second between clicking, because otherwise
  # the browser gets confused and skips some of them.
  click_expand_element <- function(el) {
    el$clickElement()
    Sys.sleep(1)
  }

  # We need to expand all of the hidden roster elements before collecting text,
  # because Selenium can't interact with hidden elements,
  # and sticking with RSelenium interactions rather than resorting
  # to arbitrary JavaScript seems slightly less hacky.
  expandable_roster_elements %>% purrr::map(click_expand_element)
}

.find_expandable_roster_elements <- function(browser) {
  expandable_roster_elements <- list()
  attempts <- 0

  # afl.com.au is using some sort of javascript framework for rendering
  # any data-based elements, and they lazy-load those elements
  # (probably some sort of componentDidMount -> API call),
  # which means that data-based elements load a second or two
  # after the rest of the page, which means we need to retry
  # accessing the relevant DOM elements a few times before they finally load.
  while (length(expandable_roster_elements) == 0 && attempts < 5) {
    Sys.sleep(1)

    expandable_roster_elements <- browser$findElements(
      using = "css",
      value = ".team-lineups__expandable-trigger.js-expand-trigger.is-hidden"
    )
    attempts <- attempts + 1
  }

  expandable_roster_elements
}

#' Scrapes team roster data (i.e. which players are playing for each team) for
#' a given round from afl.com.au, cleans it, and returns it as a dataframe.
#' @importFrom magrittr %>%
#' @param browser Selenium browser object for navigating to pages and crawling the DOM.
#' @export
fetch_rosters <- function(browser) {
  expandable_roster_elements <- .find_expandable_roster_elements(browser)

  # If we can't find anything, we're probably trying to get rosters for a round
  # for which they haven't been announced yet.
  if (length(expandable_roster_elements) == 0) {
    return(expandable_roster_elements)
  }

  .expand_roster_elements(expandable_roster_elements)

  .collect_match_elements(browser) %>%
    purrr::reduce(.parse_match_elements, .init = list(match_id = 1)) %>%
    .$roster_data %>%
    .convert_to_data_frame(.) %>%
    dplyr::mutate(., round_number = .get_round_number(browser)) %>%
    .clean_data_frame(.)
}
