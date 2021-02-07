source(here::here("R", "helpers.R"))

future::plan(future::multicore)

.fetch_season_player_results <- function(season) {
  tryCatch(
    {
      fitzRoy::fetch_player_stats_afltables(season)
    },
    error = function(err) {
      this_year <- lubridate::year(lubridate::today())

      if (season > this_year) {
        warning(
          paste0(
            "Skipping season ",
            season,
            ", because it does not have a player data yet"
          )
        )
        return(NULL)
      }

      stop(err)
    }
  )
}

.async_fetch_season_player_results <- function(season) {
  future::future({ .fetch_season_player_results(season) }, seed = TRUE)
}

#' Fetches player data via the fitzRoy package and filters by date range.
#' @importFrom magrittr %>%
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @export
fetch_player_results <- function(start_date, end_date) {
  start_season = lubridate::year(start_date)
  end_season = lubridate::year(end_date)

  player_results <- start_season:end_season %>%
    purrr::map(.async_fetch_season_player_results) %>%
    future::value() %>%
    purrr::compact()

  if (length(player_results) == 0) {
    return(list())
  }

  player_results %>%
    dplyr::bind_rows() %>%
    dplyr::filter(.data$Date >= start_date & .data$Date <= end_date) %>%
    dplyr::rename_all(~ stringr::str_to_lower(.) %>% stringr::str_replace_all(., "\\.", "_"))
}
