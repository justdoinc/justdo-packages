_.extend JustdoHelpers,
  normaliseUrl: (url) ->
    # Typically URL exists in all modern browsers, and it's in the server that's missing.
    URL = URL or JustdoHelpers.url.URL

    # URL constructor will throw error if url isn't a valid url
    # Note that it also accepts URL object instead of string
    url = new URL url

    url.searchParams.sort()

    # Remove trailing slash
    url.pathname = url.pathname.replace /\/$/, ""

    return url

  getNormalisedUrlPathname: (url_pathname) ->
    URL = URL or JustdoHelpers.url.URL

    url = new URL url_pathname, "https://justdo.com/"
    url = @normaliseUrl url

    return url.pathname + url.search

  getRootUrl: ->
    if not (root_url = document?.location?.origin)? and not (root_url = process.env.ROOT_URL)?
      return undefined

    return root_url
