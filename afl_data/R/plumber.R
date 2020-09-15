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

#' Return match results data without in-game stats. Current season only
#' (for earlier seasons use the /matches endpoint).
#' @importFrom magrittr %>%
#' @param round_number Fetch matches from the given round
#' @get /match_results
function(round_number = NULL) {
  fetch_match_results(round_number) %>% list(data = .)
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
#' @get /betting_odds
function(start_date = FIRST_AFL_SEASON, end_date = Sys.Date()) {
  fetch_betting_odds(start_date, end_date) %>% list(data = .)
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

#' Return team rosters for the current round.
#' @importFrom magrittr %>%
#' @param round_number Fetch the rosters from this round. Serves as a check
#'  to make sure available roster data matches the requested round.
#'  Leave blank to accept whatever the current round is.
#' @get /rosters
function(round_number = NULL) {
  fetch_rosters(round_number) %>% list(data = .)
}
