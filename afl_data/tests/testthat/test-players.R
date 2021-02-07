describe("fetch_player_results()", {
  describe("when data is empty", {
    today <- lubridate::today()
    future_start_date <- today + lubridate::years(1)
    future_end_date <- today + lubridate::years(2)
    future_data <- fetch_player_results(future_start_date, future_end_date)

    it("returns empty data", {
      expect_true("data.frame" %in% class(future_data))
      expect_equal(nrow(future_data), 0)
    })
  })
})