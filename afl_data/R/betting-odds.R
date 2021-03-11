source(here::here("R", "helpers.R"))

# Footywire doesn't have any betting odds after the 2020 season
MAX_SEASON <- 2020

#' Fetches betting data via the fitzRoy package and filters by date range.
#' @importFrom magrittr %>%
#' @importFrom rlang .data
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @export
fetch_betting_odds <- function(start_date, end_date) {
  end_season <- min(lubridate::year(end_date), MAX_SEASON)

  fitzRoy::fetch_betting_odds_footywire(
    start_season = lubridate::year(start_date),
    end_season = end_season
  ) %>%
    dplyr::filter(.data$Date >= start_date & .data$Date <= end_date) %>%
    dplyr::rename_all(convert_to_snake_case)
}
