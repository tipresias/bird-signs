describe("fetch_matches()", {
  today <- lubridate::today()

  describe("when there are no matches in the date range", {
    # We add two years, because it's possible to have next year's matches
    start_date <- today + lubridate::years(2)
    end_date <- today + lubridate::years(3)
    data <- fetch_matches(start_date, end_date)

    it("returns an empty list", {
      expect_true("list" %in% class(data))
      expect_equal(length(data), 0)
    })
  })

  describe("when some seasons have matches but others don't", {
    start_date <- today - lubridate::years(1)
    end_date <- today + lubridate::years(3)
    data <- fetch_matches(start_date, end_date)

    it("returns all available data", {
      expect_true("data.frame" %in% class(data))
      expect_gt(nrow(data), 0)
    })
  })
})