describe("scrape_betting_odds()", {
  splash_host <- "http://splash:8050"

  it("runs the Lua script without error", {
    scrape_betting_odds(splash_host)
  })
})