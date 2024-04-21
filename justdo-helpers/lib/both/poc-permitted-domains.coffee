poc_permitted_domains = [
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

  # localhosts
  "http://localhost:3000", "http://localhost:4000"
]

beta_domains = [
  # beta
  "https://beta.justdo.com", "https://app-beta.justdo.com",
  # test22
  "https://test22.justdo.com", "https://app-test22.justdo.com"
]

first_call = true

_.extend JustdoHelpers,
  isPocPermittedDomains: (root_url) ->
    if not root_url?
      if not (root_url = @getRootUrl())?
        return false
    
    if root_url in poc_permitted_domains
      if first_call
        console.info "IMPORTANT NOTE!!! this environment is running under root_url #{root_url} which is considered, POC permitted domain, running justdo under such a domain ISN'T SECURE! don't use for production purposes."
        first_call = false

      return true

    return false

  requirePocPermittedDomains: (root_url) ->
    if not @isPocPermittedDomains root_url
      throw new Meteor.Error "not-supported", "Supported only from POC permitted domains"
    return

  isPocPermittedDomainsOrBeta: (root_url) ->
    if not root_url?
      if not (root_url = @getRootUrl())?
        return false

    if root_url in beta_domains
      return true

    return JustdoHelpers.isPocPermittedDomains(root_url)
