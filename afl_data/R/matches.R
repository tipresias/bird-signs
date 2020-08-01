#' Fetches match data via the fitzRoy package and filters by date range.
#' @importFrom magrittr %>%
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @export
fetch_matches <- function(start_date, end_date) {
  fitzRoy::get_match_results() %>%
    dplyr::filter(., Date >= start_date & Date <= end_date) %>%
    dplyr::rename_all(~ stringr::str_to_lower(.) %>%
    stringr::str_replace_all(., "\\.", "_"))
}

#' Fetch match results data from the Squiggle API.
#' @importFrom magrittr %>%
#' @param round_number Fetch matches from the given round
#' @export
fetch_match_results <- function(round_number) {
  squiggle_api <- "https://api.squiggle.com.au"
  year <- lubridate::now() %>% lubridate::year(.)
  round_param <- ifelse(is.null(round_number), "", paste0(";round=", round_number))
  url <- paste0(squiggle_api, "/?q=games;year=", year, round_param)

  RCurl::getURL(url) %>% jsonlite::fromJSON(.) %>% .$games
}
