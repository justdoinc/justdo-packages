_.extend JustdoHelpers,

  getURL: JustdoCoreHelpers.getURL

  getRootUrl: JustdoCoreHelpers.getRootUrl

  normaliseUrl: (url) ->
    # Returns a normalized URL object (not a url string !)
    #
    # The purpose of this function is to normalize a given URL by performing a
    # series of modifications to make it more consistent and standardized.
    #
    # An example usecase is caching. Where we want to consider all these urls as the
    # same: /a?x=1&y=2 ; /a/?x=1&y=2 ; /a/?y=2&x=1 ; 
    #
    # Normalization consists of:
    #
    # * Remove trailing slash from path part
    # * sort get params lexicographically

    URL = @getURL()

    # URL constructor will throw error if url isn't a valid url
    # Note that it also accepts URL object instead of string
    url = new URL url

    url.searchParams.sort()

    # Remove trailing slash
    url.pathname = url.pathname.replace /\/$/, ""

    return url

  getNormalisedUrlPathname: (url_pathname) ->
    URL = @getURL()

    url = new URL url_pathname, "https://x.com/" # The domain doesn't matter, we do nothing with it
    url = @normaliseUrl url

    return url.pathname + url.search

  getNormalisedUrlPathnameWithoutSearchPart: (url_pathname) ->
    URL = @getURL()

    url = new URL url_pathname, "https://x.com/" # The domain doesn't matter, we do nothing with it
    url = @normaliseUrl url

    return url.pathname
