source(here::here("R", "helpers.R"))

future::plan(future::multicore)

.fetch_season_match_results <- function(season) {
  fitzRoy::fetch_results_afltables(season)
}

.async_fetch_season_match_results <- function(season) {
  future::future({ .fetch_season_match_results(season) }, seed = TRUE)
}

#' Fetches match data via the fitzRoy package and filters by date range.
#' @importFrom magrittr %>%
#' @importFrom rlang .data
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @export
fetch_matches <- function(start_date, end_date) {
  start_season <- lubridate::year(start_date)
  end_season <- lubridate::year(end_date)

  matches <- start_season:end_season %>%
    purrr::map(.async_fetch_season_match_results) %>%
    future::value() %>%
    purrr::discard(is_empty)

  if (length(matches) == 0) {
    return(matches)
  }

  matches %>%
    dplyr::bind_rows() %>%
    dplyr::filter(.data$Date >= start_date & .data$Date <= end_date) %>%
    dplyr::rename_all(convert_to_snake_case)
}

#' Fetch match results data from the Squiggle API.
#' @importFrom magrittr %>%
#' @param round_number Fetch matches from the given round
#' @export
fetch_match_results <- function(round_number) {
  squiggle_api <- "https://api.squiggle.com.au"
  year <- lubridate::now() %>% lubridate::year()
  round_param <- ifelse(is.null(round_number), "", paste0(";round=", round_number))
  url <- paste0(squiggle_api, "/?q=games;year=", year, round_param)

  RCurl::getURL(url) %>% jsonlite::fromJSON() %>% magrittr::use_series(games)
}
