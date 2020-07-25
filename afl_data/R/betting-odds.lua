function main(splash)
  local url = splash.args.url
  assert(splash:go(url))
  splash:wait(1.0)

  local response = {}

  for i, match_element in ipairs(splash:select_all('.template-item')) do
    local is_upcoming_match_element = true

    for _, class_name in ipairs(match_element.classList) do
      -- default-template is used for divs with betting on things other than
      -- match results
      if class_name == 'live' or class_name == 'default-template' then
        is_upcoming_match_element = false
      end
    end

    if is_upcoming_match_element then
      local match = {}

      match["start_date_time"] = match_element:querySelector(
        '.meta-data li[data-test="close-time"]'
      ):text()

      local team_name_element = match_element:querySelector('.match-name-text')
      for home_team, away_team in string.gmatch(team_name_element:text(), "(.+) v (.+)") do
        match["home_team"] = home_team
        match["away_team"] = away_team
      end

      local betting_elements = match_element:querySelectorAll('.proposition-wrapper')
      for j, betting_element in ipairs(betting_elements) do
        local team_label
        local odds_label

        if j <= 2 then team_label = "home" else team_label = "away" end
        if j == 1 or j == 4 then odds_label = "line_odds" else odds_label = "win_odds" end

        match[team_label .. "_" .. odds_label] = betting_element:text()
      end

      table.insert(response, match)
    end
  end

  return response
end
