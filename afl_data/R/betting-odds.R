#' Fetches betting data via the fitzRoy package and filters by date range.
#' @importFrom magrittr %>%
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @export
fetch_betting_odds <- function(start_date, end_date) {
  fitzRoy::get_footywire_betting_odds(
    start_season = lubridate::year(start_date),
    end_season = lubridate::year(end_date)
  ) %>%
    dplyr::filter(., Date >= start_date & Date <= end_date) %>%
    dplyr::rename_all(
      ~ stringr::str_to_lower(.) %>% stringr::str_replace_all(., "\\.", "_")
    )
}


.append_match_cols_to_betting_data <- function(betting_data, fixture_data) {
    dplyr::inner_join(
    betting_data,
    fixture_data,
    by = c('Join.Date', 'Home.Team', 'Away.Team')
  ) %>%
    dplyr::select(!c('Join.Date'))
}


.fetch_fixture_data <- function() {
  fitzRoy::get_fixture() %>%
      dplyr::mutate(Join.Date = lubridate::as_date(Date)) %>%
      # We use betting data's Date column, and Season.Game is not
      # a betting data column
      dplyr::select(!c('Date', 'Season.Game'))
}


.extract_line_odds <- function(line_odds_col) {
  line_odds_col %>%
    # Example of raw line odds string: (+5.5)1.90
    stringr::str_extract(., "(?:\\+|\\-)\\d+\\.\\d+") %>%
    as.numeric
}


.map_team_names_to_fitzroy_conventions <- function(value) {
  dplyr::case_when(
    value == "Wst Bulldogs" ~ "Footscray",
    value == "Brisbane" ~ "Brisbane Lions",
    TRUE ~ value
  )
}


.clean_betting_data <- function(raw_betting_data) {
  # Lua returns a JSONified version of its table structure, which R
  # has a difficult time with. This seems to be the easiest way to get it
  # into the shape of a list of named lists
  purrr::map(1:length(raw_betting_data), ~ unlist(raw_betting_data[[.x]])) %>%
      tibble::tibble(data = .) %>%
      tidyr::unnest_wider(data) %>%
      dplyr::transmute(
        Date = lubridate::parse_date_time(start_date_time, c("admHM")),
        Join.Date = lubridate::as_date(Date),
        Home.Team = home_team,
        Away.Team = away_team,
        Home.Win.Odds = as.numeric(home_win_odds),
        Away.Win.Odds = as.numeric(away_win_odds),
        Home.Line.Odds = .extract_line_odds(home_line_odds),
        Away.Line.Odds = .extract_line_odds(away_line_odds),
        # All data from this source are for future matches, so these values
        # will alway be uknown when fetching data.
        Home.Score = as.numeric(NA),
        Away.Score = as.numeric(NA),
        Home.Margin = as.numeric(NA),
        Away.Margin = as.numeric(NA),
        Home.Win.Paid = as.numeric(NA),
        Away.Win.Paid = as.numeric(NA),
        Home.Line.Paid = as.numeric(NA),
        Away.Line.Paid = as.numeric(NA),
      ) %>%
      dplyr::mutate_at(
        c('Home.Team', 'Away.Team'),
        .map_team_names_to_fitzroy_conventions
      )
}


.fetch_raw_odds_data <- function(splash_host) {
  betting_website <- "https://www.tab.com.au/sports/betting/AFL%20Football"
  lua_filepath <- here::here("R", "betting-odds.lua")
  lua_source <- readLines(lua_filepath) %>% paste(., collapse = "\n")
  fields <- jsonlite::toJSON(
    list(
      lua_source = lua_source,
      url = betting_website
    ),
    auto_unbox = TRUE
  )

  header <- c(`Content-Type`="application/json")

  response <- RCurl::postForm(
    paste0(splash_host, "/execute"),
    .opts=list(httpheader = header, postfields=fields)
  ) %>%
    jsonlite::fromJSON(.)
}


#' Scrapes betting data for the latest round from a betting site.
#' @importFrom magrittr %>%
#' @param splash_host Hostname of the splash server to use
#' @export
scrape_betting_odds <- function(splash_host) {
  raw_betting_data <- tryCatch(
    {
      .fetch_raw_odds_data(splash_host)
    },
    error = function(cond) {
      message(cond)
      list()
    }
  )

  if (length(raw_betting_data) == 0) {
    return(raw_betting_data)
  }

  betting_data <- .clean_betting_data(raw_betting_data)
  fixture_data <- .fetch_fixture_data()

  .append_match_cols_to_betting_data(betting_data, fixture_data)
}
