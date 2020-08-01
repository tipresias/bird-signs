source(here::here("R", "matches.R"))
source(here::here("R", "players.R"))
source(here::here("R", "betting-odds.R"))
source(here::here("R", "fixtures.R"))
source(here::here("R", "rosters.R"))

FIRST_AFL_SEASON <- "1897-01-01"
END_OF_YEAR <- paste0(lubridate::year(Sys.Date()), "-12-31")
AFL_DOMAIN <- "https://www.afl.com.au"
TEAMS_PATH <- "/matches/team-lineups"

.is_production <- function() {
  PRODUCTION <- "production"

  tolower(Sys.getenv("R_ENV")) == PRODUCTION
}

#* @filter checkAuth
function(req, res){
  request_token <- ifelse(
    is.null(req$HTTP_AUTHORIZATION), '', req$HTTP_AUTHORIZATION
  )
  valid_token <- paste0("Bearer ", Sys.getenv("GCR_TOKEN"))

  if (.is_production() && request_token != valid_token && req$PATH_INFO != "/") {
    res$status <- 401
    return(list(error="Not authorized"))
  }

  plumber::forward()
}

#' Return a basic message for site health checks
#' @get /
function() {
  "Welcome to BirdSigns, the AFL data service!"
}

#' Return data for completed matches.
#' @importFrom magrittr %>%
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @get /matches
function(start_date = FIRST_AFL_SEASON, end_date = Sys.Date()) {
  fetch_matches(start_date, end_date) %>%
    list(data = .)
}

#' Return player data
#' @importFrom magrittr %>%
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @get /players
function(start_date = FIRST_AFL_SEASON, end_date = Sys.Date()) {
  fetch_player_results(start_date, end_date) %>%
    list(data = .)
}

#' Return betting data along with some basic match data
#' @importFrom magrittr %>%
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @param fallback_for_upcoming_round Whether to scrape a betting site
#'  in the case of missing data
#' @get /betting_odds
function(
  start_date = FIRST_AFL_SEASON,
  end_date = Sys.Date(),
  fallback_for_upcoming_round = FALSE
) {
  betting_data <- fetch_betting_odds(start_date, end_date)
  is_empty <- length(betting_data) == 0 || nrow(betting_data) == 0

  if (is_empty && as.logical(fallback_for_upcoming_round)) {
    splash_host <- ifelse(
      .is_production(),
      Sys.getenv("SPLASH_SERVICE"),
      "http://splash:8050"
    )

    betting_data <- scrape_betting_odds(splash_host)
  }

  betting_data %>% list(data = .)
}

#' Return fixture data (match data without results)
#' @importFrom magrittr %>%
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @get /fixtures
function(start_date = FIRST_AFL_SEASON, end_date = END_OF_YEAR) {
  fetch_fixtures(start_date, end_date) %>%
    list(data = .)
}

#' Return team rosters for a given round (current season only)
#' @importFrom magrittr %>%
#' @param round_number Fetch the rosters from this round. Note that missing param defaults to current round
#' @get /rosters
function(round_number = NULL) {
  server_address <- "browser"
  port <- 4444L

  browser <- RSelenium::remoteDriver(
    remoteServerAddr = server_address,
    browser = 'chrome',
    port = port,
    extraCapabilities = list(
      "goog:chromeOptions" = list(
        args = list(
          "--headless",
          "--no-sandbox",
          "--disable-gpu",
          "--disable-dev-shm-usage",
          "window-size=1024,768"
        )
      )
    )
  )

  tryCatch({
    browser$open()

    browser$navigate(paste0(AFL_DOMAIN, TEAMS_PATH, "?GameWeeks=", round_number))
    roster_data <- fetch_rosters(browser) %>% list(data = .)
  }, finally = {
    browser$close()
    browser$closeServer()
  })
}
