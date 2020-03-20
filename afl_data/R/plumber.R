source(paste0(getwd(), "/R/matches.R"))
source(paste0(getwd(), "/R/players.R"))
source(paste0(getwd(), "/R/betting-odds.R"))
source(paste0(getwd(), "/R/fixtures.R"))
source(paste0(getwd(), "/R/rosters.R"))

FIRST_AFL_SEASON <- "1897-01-01"
END_OF_YEAR <- paste0(lubridate::year(Sys.Date()), "-12-31")
PRODUCTION <- "production"

#* @filter checkAuth
function(req, res){
  request_token <- ifelse(
    is.null(req$HTTP_AUTHORIZATION), '', req$HTTP_AUTHORIZATION
  )
  valid_token <- paste0("Bearer ", Sys.getenv("GCR_TOKEN"))
  is_production <- tolower(Sys.getenv("R_ENV")) == PRODUCTION

  if (is_production && request_token != valid_token) {
    res$status <- 401
    return(list(error="Not authorized"))
  }

  plumber::forward()
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
  fetch_rosters(round_number) %>%
    list(data = .)
}
