function main(splash)
  local url = splash.args.url
  assert(splash:go(url))
  splash:wait(1.0)

  return url
end
