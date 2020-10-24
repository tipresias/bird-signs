ROSTER_URL <- "https://www.footywire.com/afl/footy/afl_team_selections"
FIXTURE_URL <- "https://www.footywire.com/afl/footy/ft_match_list"

PLAYER_COL_NAMES <- c(
  "player_name",
  "playing_for",
  "home_team",
  "away_team",
  "match_id"
)

HOME_AWAY <- c("home", "away")


.clean_data_frame <- function(roster_df) {
  roster_df %>%
    dplyr::mutate_all(., as.character) %>%
    dplyr::mutate(
      .,
      player_name = stringr::str_extract(player_name, "[:alpha:]+(?:[:blank:][:alpha:]+)+"),
      round_number = as.numeric(round_number),
      season = lubridate::now() %>% lubridate::year(.)
    )
}


.get_round_number <- function(roster_page) {
  round_label <- roster_page %>%
    rvest::html_node("h1.centertitle") %>%
    rvest::html_text()

  round_number <- round_label %>%
    stringr::str_match(., "Round (\\d+)") %>%
    .[[2]] %>%
    as.numeric(.)

  if (is.na(round_number)) {
    return(NULL)
  }

  max_regular_round <- xml2::read_html(FIXTURE_URL) %>%
    rvest::html_nodes(".tbtitle") %>%
    rvest::html_text() %>%
    purrr::map(~ stringr::str_match(.x, "Round (\\d+)") %>% .[[2]] %>% as.numeric) %>%
    unlist() %>%
    max(., na.rm = TRUE)

  finals_week <- round_label %>%
    stringr::str_match("Finals Week (\\d+)") %>%
    .[[2]] %>%
    as.numeric()

  max_regular_round + finals_week
}


.pivot_data_frame <- function(matches) {
  matches %>%
  tidyr::pivot_wider(
    .,
    id_cols = c(player_name, playing_for, match_id),
    names_from = team_type,
    values_from = team
  ) %>%
  tidyr::fill(., tidyselect::all_of(HOME_AWAY), .direction = "downup") %>%
  dplyr::rename(., home_team = home, away_team = away)
}


.fetch_player_name <- function(link_element) {
  BASE_FOOTYWIRE_URL <- "https://www.footywire.com/afl/footy/"
  link_element %>%
    rvest::html_attr(., "href") %>%
    paste0(BASE_FOOTYWIRE_URL, .) %>%
    xml2::read_html(.) %>%
    rvest::html_node(., "#playerProfileName") %>%
    rvest::html_text(.)
}


.parse_team_data <- function(match_tables) {
  function(team_name, index) {
    ROSTER_TABLE_INDEX <- 2

    team_type <- HOME_AWAY[[index]]
    # We need to reverse table order for "away", because tables are ordered:
    # home interchange -> both rosters -> away interchange.
    interchange_index <- if (team_type == "home") 1 else 3
    row_modulo_remainder <- if (team_type == "home") 1 else 0

    interchange_players <- match_tables[[interchange_index]] %>%
      rvest::html_nodes(., "a") %>%
      # Only first four players listed are for interchange;
      # others are emergencies, ins, or outs.
      .[1:4] %>%
      purrr::map(., .fetch_player_name) %>%
      unlist(.)

    roster_players <- match_tables[[ROSTER_TABLE_INDEX]] %>%
      rvest::html_nodes("tr") %>%
      purrr::imap(
        ~ if (.y %% 2 == row_modulo_remainder) rvest::html_nodes(.x, "a") else NULL
      ) %>%
      unlist(., recursive = FALSE) %>%
      purrr::map(., .fetch_player_name) %>%
      unlist(.)

    team_roster <- c(roster_players, interchange_players)

    tibble::tibble(player_name = team_roster) %>%
      dplyr::mutate(
        playing_for = team_name,
        team_type = team_type,
        team = playing_for
      )
  }
}

.extract_team_names <- function(match_element) {
  # Match label has the format <home team> v <away team> (<venue>)
  UNTIL_VENUE_REGEX <- "[^(]+"

  match_element %>%
      # There are multiple nodes that match this selector, but team names
      # will always be in the first.
      rvest::html_node(., '.tbtitle') %>%
      rvest::html_text(.) %>%
      stringr::str_extract(., UNTIL_VENUE_REGEX) %>%
      stringr::str_split(., ' v ') %>%
      unlist(.) %>%
      stringr::str_trim(.)
}

.parse_match_element <- function(match_element, index) {
  match_tables <- match_element %>%
    rvest::html_nodes('table') %>%
    # Super janky, but only the table with summary statistics
    # (and no player names) has cellpadding=0
    purrr::discard(
      ~ rvest::html_attr(., "cellpadding") %>% as.numeric(.) == 0
    )

  match_element %>%
    .extract_team_names(.) %>%
    purrr::imap(., .parse_team_data(match_tables)) %>%
    dplyr::bind_rows(.) %>%
    dplyr::mutate(match_id = index)
}

.collect_match_elements <- function(page) {
  match_roster_elements <- page %>%
    rvest::html_nodes("table[align='CENTER']")

  stopifnot(length(match_roster_elements) > 0)

  match_roster_elements
}

#' Scrapes team roster data (i.e. which players are playing for each team) for
#' a given round from afl.com.au, cleans it, and returns it as a dataframe.
#' @importFrom magrittr %>%
#' @param round_number Fetch the rosters from this round. Required,
#'  because it is assigned to the round_number column of the returned data set.
#' @export
fetch_rosters <- function(round_number) {
  roster_page <- xml2::read_html(ROSTER_URL)
  page_round_number <- .get_round_number(roster_page)

  # If we have mismatched round numbers, it means that the roster page
  # hasn't been updated for the upcoming round yet.
  round_numbers_match <- is.null(round_number) ||
    # If roster_round_number is NULL, it means that the page is using
    # some finals round label that we can't parse for a round number,
    # so we just shrug and hope it's been updated for the current round.
    is.null(page_round_number) ||
    page_round_number == as.numeric(round_number)

  roster_round_number <- if (is.null(page_round_number)) {
    if (is.null(round_number)) 0 else round_number
  } else {
    page_round_number
  }

  if (!round_numbers_match || is.null(roster_round_number)) {
    return(list())
  }


  fixture <- fitzRoy::get_fixture() %>%
    dplyr::select(c('Date', 'Home.Team', 'Away.Team', 'Round')) %>%
    dplyr::rename(
      date = Date,
      home_team = Home.Team,
      away_team = Away.Team,
      round_number = Round
    )

  rosters <- .collect_match_elements(roster_page) %>%
    purrr::imap(.parse_match_element) %>%
    dplyr::bind_rows(.) %>%
    .pivot_data_frame(.) %>%
    dplyr::mutate(., round_number = roster_round_number) %>%
    .clean_data_frame(.) %>%
    dplyr::inner_join(fixture, by = c('round_number', 'home_team', 'away_team'))
}
