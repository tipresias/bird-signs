#' Fetches match data via the fitzRoy package and filters by date range.
#' @importFrom magrittr %>%
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @export
fetch_match_results <- function(start_date, end_date) {
  fitzRoy::get_match_results() %>%
    dplyr::filter(., Date >= start_date & Date <= end_date) %>%
    dplyr::rename_all(~ stringr::str_to_lower(.) %>% stringr::str_replace_all(., "\\.", "_"))
}
