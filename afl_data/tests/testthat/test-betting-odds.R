describe("fetch_betting_odds()", {
  today <- lubridate::today()

  describe("when data is empty", {
    start_date <- today + lubridate::years(1)
    end_date <- today + lubridate::years(2)
    data <- fetch_betting_odds(start_date, end_date)

    it("returns an empty data frame", {
      expect_true("data.frame" %in% class(data))
      expect_equal(nrow(data), 0)
    })
  })

  describe("when some seasons have betting data but others don't", {
    it("returns available betting data", {
      # We can use hard-coded dates, because betting data stopped
      # getting populated around mid-2020
      start_date <- '2020-01-01'
      end_date <- '2021-12-31'
      data <- fetch_betting_odds(start_date, end_date)

      expect_true("data.frame" %in% class(data))
      expect_gt(nrow(data), 0)
    })
  })
})