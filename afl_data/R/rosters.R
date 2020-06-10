PLAYER_COL_NAMES = c(
  "player_name",
  "playing_for",
  "home_team",
  "away_team",
  "date",
  "match_id"
)


.parse_date_time <- function(date_time_string) {
  lubridate::parse_date_time(
    date_time_string, "%A %b %d %I:%M %p %y",
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
    dplyr::mutate(
      .,
      date = .parse_date_time(date),
      round_number = as.numeric(round_number)
    ) %>%
    dplyr::mutate(., season = lubridate::year(date))
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


.parse_team_data <- function(match_roster_element, team_type) {
  team_name <- match_roster_element$findChildElement(
    using = "css",
    value = paste0(".team-lineups__team-name--", team_type)
  )$getElementText() %>%
    unlist

  # For team name containers, they use "--home" and "--away"
  # to differentiate between team types, but for player containers,
  # they use "--home" and a blank suffix indicates 'away'
  player_team_type <- if(team_type == "home") "--home" else ""
  team_roster <- match_roster_element$findChildElements(
    using = "css",
    value = paste0(".team-lineups__positions-players-container", player_team_type, " .team-lineups__player")
  ) %>%
    purrr::map(., ~ .x$getElementText()) %>%
    unlist %>%
    stringr::str_extract(., "[:alpha:]+(?:[:blank:][:alpha:]+)+")

  tibble::tibble(
    player_name = team_roster,
    playing_for = rep_len(team_name, length(team_roster)),
    team_type = rep_len(team_type, length(team_roster))
  ) %>%
    dplyr::mutate(team = playing_for)
}

.parse_match_data <- function(index, match_date_time, match_roster_element) {
  HOME_AWAY <- c("home", "away")
  # We assume that we only scrape rosters for matches from this year,
  # because any data from past matches are better retrieved from AFL Tables.
  this_year <- lubridate::today() %>% lubridate::year(.)

  purrr::map(HOME_AWAY, ~ .parse_team_data(match_roster_element, .)) %>%
    dplyr::bind_rows(.) %>%
    tidyr::pivot_wider(
      .,
      id_cols = c(player_name, playing_for),
      names_from = team_type,
      values_from = team
    ) %>%
    tidyr::fill(., tidyselect::all_of(HOME_AWAY), .direction = "downup") %>%
    dplyr::rename(., home_team = home, away_team = away) %>%
    dplyr::mutate(
      .,
      match_id = rep_len(index, nrow(.)),
      date = rep_len(paste(paste(match_date_time, collapse = " "), this_year), nrow(.))
    )
}

.collect_team_rosters <- function(browser) {
  match_roster_elements <- browser$findElements(
    using = "css", value = ".team-lineups__wrapper"
  )

  stopifnot(length(match_roster_elements) > 0)

  match_indices <- 1:length(match_roster_elements)

  match_date_times <- browser$findElements(
    using = "css",
    value = ".match-list__group-date, .match-list-alt__header-time"
  ) %>%
    purrr::map(~ .x$getElementText()) %>%
    unlist %>%
    dplyr::bind_cols(
      date_time = .,
      label = ifelse(grepl("PM|AM", .), "time", "date"),
      # Need column of unique IDs or else pivot_wider blows up
      id = 1:length(.)
    ) %>%
    tidyr::pivot_wider(names_from = label, values_from = date_time) %>%
    # Dates are displayed per match day and times per match, so we need
    # to fill in the missing dates for matches after the first of the day.
    tidyr::fill(date) %>%
    dplyr::filter(!is.na(time)) %>%
    dplyr::select(c(date, time)) %>%
    purrr::transpose(.)


  list(match_indices, match_date_times, match_roster_elements)
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

  .collect_team_rosters(browser) %>%
    purrr::pmap(.parse_match_data) %>%
    dplyr::bind_rows(.) %>%
    dplyr::mutate(., round_number = .get_round_number(browser)) %>%
    .clean_data_frame(.)
}
