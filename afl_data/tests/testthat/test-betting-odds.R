describe("scrape_betting_odds()", {
  splash_host <- "http://splash:8050"

  it("returns a data frame with the correct columns", {
    betting_data <- scrape_betting_odds(splash_host)

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
  })
})