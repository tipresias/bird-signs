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

      expect_type(betting_data$Date, "double")
      expect_type(betting_data$Home.Team, "character")
      expect_type(betting_data$Away.Team, "character")
      expect_type(betting_data$Home.Win.Odds, "double")
      expect_type(betting_data$Away.Win.Odds, "double")
      expect_type(betting_data$Home.Line.Odds, "double")
      expect_type(betting_data$Away.Line.Odds, "double")
      expect_type(betting_data$Home.Score, "double")
      expect_type(betting_data$Away.Score, "double")
      expect_type(betting_data$Home.Margin, "double")
      expect_type(betting_data$Away.Margin, "double")
      expect_type(betting_data$Home.Win.Paid, "double")
      expect_type(betting_data$Away.Win.Paid, "double")
      expect_type(betting_data$Home.Line.Paid, "double")
      expect_type(betting_data$Away.Line.Paid, "double")
    }
  })
})
