_.extend JustdoCoreHelpers,
  getURL: ->
    # JustdoCoreHelpers.url.URL is a fallback for the server
    return window?.URL or JustdoCoreHelpers.url.URL

  getRootUrl: ->
    if not (root_url = document?.location?.origin)? and not (root_url = process.env.ROOT_URL)?
      return undefined

    return root_url
