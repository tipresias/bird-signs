describe("fetch_rosters()", {
  browser <- RSelenium::remoteDriver(
    remoteServerAddr = server_address,
    browser = 'chrome',
    port = port,
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
  roster_data <- fetch_rosters(NULL, browser)

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
  })
})
