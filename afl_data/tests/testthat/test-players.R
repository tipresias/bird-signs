describe("fetch_player_results()", {
  today <- lubridate::today()

  describe("when there are no fixtures in the date range", {
    # We add two years, because it's possible to have next year's fixtures
    start_date <- today + lubridate::years(1)
    end_date <- today + lubridate::years(2)
    data <- fetch_player_results(start_date, end_date)

    it("returns an empty data frame", {
      expect_true("list" %in% class(data))
      expect_equal(length(data), 0)
    })
  })

  describe("when some seasons have fixtures but others don't", {
    start_date <- today - lubridate::years(1)
    end_date <- today + lubridate::years(2)
    data <- fetch_player_results(start_date, end_date)

    it("returns all available data", {
      expect_true("data.frame" %in% class(data))
      expect_gt(nrow(data), 0)
    })
  })
})