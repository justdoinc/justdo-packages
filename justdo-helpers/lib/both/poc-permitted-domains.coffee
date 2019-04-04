poc_permitted_domains = [
  # alpha
  "https://alpha.justdo.today", "https://app-alpha.justdo.today",
  "https://alpha-beta.justdo.today", "https://app-alpha-beta.justdo.today",

  # Daniel's
  "http://daniel-dev.justdo.today:3000", "http://daniel-dev.justdo.today:4000",

  # local http
  "http://local.justdo.today", "http://app-local.justdo.today",
  "http://alpha-local.justdo.today", "http://app-local-beta.justdo.today",

  # local https
  "https://local.justdo.today", "https://app-local.justdo.today",
  "https://alpha-local.justdo.today", "https://app-local-beta.justdo.today",

  # alpha .com
  "https://alpha.justdo.com", "https://app-alpha.justdo.com",
  "https://alpha-beta.justdo.com", "https://app-alpha-beta.justdo.com",

  # Daniel's .com
  "http://daniel-dev.justdo.com:3000", "http://daniel-dev.justdo.com:4000",

  # local http .com
  "http://local.justdo.com", "http://app-local.justdo.com",
  "http://alpha-local.justdo.com", "http://app-local-beta.justdo.com",

  # local https .com
  "https://local.justdo.com", "https://app-local.justdo.com",
  "https://alpha-local.justdo.com", "https://app-local-beta.justdo.com",
]

first_call = true

_.extend JustdoHelpers,
  isPocPermittedDomains: (root_url) ->
    if root_url in poc_permitted_domains
      if first_call
        console.info "IMPORTANT NOTE!!! this environment is running under root_url #{root_url} which is considered, POC permitted domain, running justdo under such a domain ISN'T SECURE! don't use for production purposes."
        first_call = false

      return true

    return false