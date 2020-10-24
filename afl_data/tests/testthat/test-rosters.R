# These tests aren't super useful given the sort of flexibility we have to allow
# for different round headers/params and different times of year,
# but it's better than nothing I guess
describe("fetch_rosters()", {
  describe("with a non-matching round_number", {
    nonexistent_round_number <- -1
    roster_data <- fetch_rosters(nonexistent_round_number)

    if ("list" %in% class(roster_data))
      it("is empty", {
        expect_equal(length(roster_data), 0)
      })
    else {
      it("returns a data.frame", {
        expect_true("data.frame" %in% class(roster_data))
      })

      it("has the correct data type for each column", {
        expect_type(roster_data$player_name, "character")
        expect_type(roster_data$playing_for, "character")
        expect_type(roster_data$home_team, "character")
        expect_type(roster_data$away_team, "character")
        expect_type(roster_data$date, "double")
        expect_type(roster_data$season, "double")
        expect_type(roster_data$match_id, "character")
        expect_type(roster_data$round_number, "double")
      })
    }
  })

  describe("with a NULL round_number", {
    roster_data <- fetch_rosters(NULL)

    if ("list" %in% class(roster_data))
      it("is empty", {
        expect_equal(length(roster_data), 0)
      })
    else {
      it("returns a data.frame", {
        expect_true("data.frame" %in% class(roster_data))
      })

      it("has the correct data type for each column", {
        expect_type(roster_data$player_name, "character")
        expect_type(roster_data$playing_for, "character")
        expect_type(roster_data$home_team, "character")
        expect_type(roster_data$away_team, "character")
        expect_type(roster_data$date, "double")
        expect_type(roster_data$season, "double")
        expect_type(roster_data$match_id, "character")
        expect_type(roster_data$round_number, "double")
      })
    }
  })
})
