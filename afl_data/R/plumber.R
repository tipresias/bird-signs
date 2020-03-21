source(paste0(getwd(), "/R/matches.R"))
source(paste0(getwd(), "/R/players.R"))
source(paste0(getwd(), "/R/betting-odds.R"))
source(paste0(getwd(), "/R/fixtures.R"))
source(paste0(getwd(), "/R/rosters.R"))

FIRST_AFL_SEASON <- "1897-01-01"
END_OF_YEAR <- paste0(lubridate::year(Sys.Date()), "-12-31")

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

#' Return match results data
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @get /matches
function(start_date = FIRST_AFL_SEASON, end_date = Sys.Date()) {
  fetch_match_results(start_date, end_date) %>%
    list(data = .)
}

#' Return player data
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @get /players
function(start_date = FIRST_AFL_SEASON, end_date = Sys.Date()) {
  fetch_player_results(start_date, end_date) %>%
    list(data = .)
}

#' Return betting data along with some basic match data
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @get /betting_odds
function(start_date = FIRST_AFL_SEASON, end_date = Sys.Date()) {
  fetch_betting_odds(start_date, end_date) %>%
    list(data = .)
}

#' Return fixture data (match data without results)
#' @param start_date Minimum match date for fetched data
#' @param end_date Maximum match date for fetched data
#' @get /fixtures
function(start_date = FIRST_AFL_SEASON, end_date = END_OF_YEAR) {
  fetch_fixtures(start_date, end_date) %>%
    list(data = .)
}

#' Return team rosters for a given round (current season only)
#' @param round_number Fetch the rosters from this round. Note that missing param defaults to current round
#' @get /rosters
function(round_number = NULL) {
  PRODUCTION_HOST <- "https://selenium-firefox-acta2grrga-de.a.run.app"
  server_address <- if(.is_production()) PRODUCTION_HOST else "browser"
  print(server_address)
  browser <- RSelenium::remoteDriver(
    remoteServerAddr = server_address,
    port = 4444L,
    extraCapabilities = list(
      "moz:firefoxOptions" = list(
        args = list('--headless')
      )
    ),
  )

  fetch_rosters(round_number, browser) %>%
    list(data = .)
}
