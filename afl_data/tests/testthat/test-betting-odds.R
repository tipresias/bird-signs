describe("scrape_betting_odds()", {
  splash_host <- "http://splash:8050"

  it("returns a data frame with the correct columns or empty list", {
    betting_data <- scrape_betting_odds(splash_host)

    # Sometimes the roster page is blank, so we have to accept an empty list
    # as a legitimate result
    if (length(betting_data) == 0) {
      expect_true("list" %in% class(betting_data))
    } else {
      expect_true("data.frame" %in% class(betting_data))

      expect_type(betting_data$date, "double")
      expect_type(betting_data$home_team, "character")
      expect_type(betting_data$away_team, "character")
      expect_type(betting_data$home_win_odds, "double")
      expect_type(betting_data$away_win_odds, "double")
      expect_type(betting_data$home_line_odds, "double")
      expect_type(betting_data$away_line_odds, "double")
      expect_type(betting_data$home_score, "double")
      expect_type(betting_data$away_score, "double")
      expect_type(betting_data$home_margin, "double")
      expect_type(betting_data$away_margin, "double")
      expect_type(betting_data$home_win_paid, "double")
      expect_type(betting_data$away_win_paid, "double")
      expect_type(betting_data$home_line_paid, "double")
      expect_type(betting_data$away_line_paid, "double")
    }
  })
})
