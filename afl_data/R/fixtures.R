future::plan(future::multicore)

EARLIEST_VALID_SEASON = 2004

.fetch_season_fixture <- function(season) {
  tryCatch({
        fitzRoy::fetch_fixture_footywire(season)
      },
      error = function(err) {
        # fitzRoy returns 404 response errors if we try to fetch
        # fixtures that don't exist yet
        if (stringr::str_detect(toString(err), "HTTP error 404")) {
          warning(
            paste0(
              "Skipping season ",
              season,
              ", because it does not have a fixture yet"
            )
          )
          return(NULL)
        }

        stop(err)
      }
    )
}

#' Fetches fixture data via the fitzRoy package and filters by date range.
#' @importFrom magrittr %>%
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @export
fetch_fixtures <- function(start_date, end_date) {
  first_season = lubridate::year(start_date)
  last_season = lubridate::year(end_date)

  if (first_season < EARLIEST_VALID_SEASON) {
    warning(
      paste0(
        first_season,
        " is earlier than available data. Fetching fixture data between ",
        EARLIEST_VALID_SEASON, " and ", last_season
      )
    )
  }

  fixtures <- max(first_season, EARLIEST_VALID_SEASON):last_season %>%
    purrr::map(.async_fetch_season_fixture) %>%
    future::value() %>%
    purrr::compact()

  if (length(fixtures) == 0) {
    return(list())
  }

  fixtures %>%
    dplyr::bind_rows(.) %>%
    dplyr::filter(., Date >= start_date & Date <= end_date) %>%
    dplyr::rename_all(
      ~ stringr::str_to_lower(.) %>% stringr::str_replace_all(., "\\.", "_")
    )
}
