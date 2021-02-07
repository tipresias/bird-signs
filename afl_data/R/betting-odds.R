source(here::here("R", "helpers.R"))

#' Fetches betting data via the fitzRoy package and filters by date range.
#' @importFrom magrittr %>%
#' @importFrom rlang .data
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @export
fetch_betting_odds <- function(start_date, end_date) {
  fitzRoy::fetch_betting_odds_footywire(
    start_season = lubridate::year(start_date),
    end_season = lubridate::year(end_date)
  ) %>%
    dplyr::filter(.data$Date >= start_date & .data$Date <= end_date) %>%
    dplyr::rename_all(convert_to_snake_case)
}
