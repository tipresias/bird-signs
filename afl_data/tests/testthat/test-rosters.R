describe("fetch_rosters()", {
  browser <- RSelenium::remoteDriver(
    remoteServerAddr = "browser",
    browser = 'chrome',
    port = 4444L,
    extraCapabilities = list(
      "goog:chromeOptions" = list(
        args = list(
          "--headless",
          "--no-sandbox",
          "--disable-gpu",
          "--disable-dev-shm-usage",
          "window-size=1024,768"
        )
      )
    )
  )

  # Fetching data takes awhile, so we do it once for all tests
  browser$open()
  browser$navigate(paste0(AFL_DOMAIN, TEAMS_PATH))
  roster_data <- fetch_rosters(browser)
  browser$close()

  it("returns a data.frame or empty list", {
    if (length(roster_data) == 0) {
      expect_true("list" %in% class(roster_data))
    } else {
      expect_true("data.frame" %in% class(roster_data))
    }
  })

  it("has the correct data type for each column", {
    if (length(roster_data) > 0) {
      expect_type(roster_data$player_name, "character")
      expect_type(roster_data$playing_for, "character")
      expect_type(roster_data$home_team, "character")
      expect_type(roster_data$away_team, "character")
      expect_type(roster_data$date, "double")
      expect_type(roster_data$season, "double")
      expect_type(roster_data$match_id, "character")
    }
  })
})
