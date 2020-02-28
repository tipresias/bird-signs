AFL_DOMAIN = "https://www.afl.com.au"
TEAMS_PATH = "/matches/team-lineups"
PLAYER_COL_NAMES = c(
  "player_name",
  "playing_for",
  "home_team",
  "away_team",
  "date",
  "match_id"
)
# As of 30-05-2019 afl.com.au has seen fit to change the structure of the HTML
# on the /news/teams page, adding promotional links to the last 3 positions,
# shifting the match datetime to 4th from last. This only applies to matches
# that haven't been played yet.
PREMATCH_LINKS_COUNT = 3


.parse_date_time <- function(date_time_string) {
  lubridate::parse_date_time(
    date_time_string, "%A %b %d %I:%M %p",
    tz = "Australia/Melbourne",
    quiet = TRUE
  )
}


.clean_data_frame <- function(roster_df) {
  roster_df %>%
    dplyr::mutate_all(., as.character) %>%
    dplyr::mutate(., date = .parse_date_time(date)) %>%
    dplyr::mutate(., season = lubridate::year(date))
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
    tidyr::fill(., HOME_AWAY, .direction = "downup") %>%
    dplyr::rename(., home_team = home, away_team = away) %>%
    dplyr::mutate(
      .,
      match_id = rep_len(index, nrow(.)),
      date = rep_len(paste(match_date_time, this_year, collapse = " "), nrow(.))
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

#' Scrapes team roster data (i.e. which players are playing for each team) for
#' a given round from afl.com.au, cleans it, and returns it as a dataframe.
#' @param round_number Which round to get rosters for
#' @export
fetch_rosters <- function(round_number, driver = RSelenium::rsDriver(browser = "firefox")) {
  browser <- driver$client
  browser$navigate(paste0(AFL_DOMAIN, TEAMS_PATH, "?GameWeeks=", round_number))

  expand_roster_elements <- list()
  attempts <- 0

  # afl.com.au is using some sort of javascript framework for rendering
  # any data-based elements, and they lazy-load those elements
  # (probably some sort of componentDidMount -> API call),
  # which means that data-based elements load a second or two
  # after the rest of the page, which means we need to retry
  # accessing the relevant DOM elements a few times before they finally load.
  while (length(expand_roster_elements) == 0 && attempts < 5) {
    Sys.sleep(1)

    expand_roster_elements <- browser$findElements(
      using = "css",
      value = ".team-lineups__expandable-trigger.js-expand-trigger.is-hidden"
    )
    attempts <- attempts + 1
  }

  # If we can't find anything, we're probably trying to get rosters for a round
  # for which they haven't been announced yet.
  if (length(expand_roster_elements) == 0) {
    return(expand_roster_elements)
  }

  # We need to expand all of the hidden roster elements before collecting text,
  # because Selenium can't interact with hidden elements,
  # and sticking with RSelenium interactions rather than resorting
  # to arbitrary JavaScript seems slightly less hacky.
  expand_roster_elements %>% purrr::map(~ .x$clickElement())

  roster_data <- .collect_team_rosters(browser) %>%
    purrr::pmap(.parse_match_data) %>%
    dplyr::bind_rows(.) %>%
    .clean_data_frame(.)

  browser$closeall()

  roster_data
}
