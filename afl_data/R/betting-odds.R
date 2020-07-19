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


#' Scrapes betting data for the latest round from a betting site.
#' @importFrom magrittr %>%
#' @param splash_host Hostname of the splash server to use
#' @export
scrape_betting_odds <- function(splash_host) {
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

  # Lua returns a JSONified version of its table structure, which R
  # has a difficult time with. This seems to be the easiest way to get it
  # into the shape of a list of named lists
  purrr::map(1:length(response), ~ unlist(response[[.x]])) %>%
    tibble::tibble(data = .) %>%
    tidyr::unnest_wider(data)
}
