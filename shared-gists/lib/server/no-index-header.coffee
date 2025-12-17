WebApp.connectHandlers.use (req, res, next) =>
  # Note that a page might be indexed already by the crawler, hence adding it to robots.txt
  # won't prevent it from being indexed, it will just prevent it from being indexed again
  #
  # From: https://developers.google.com/search/docs/crawling-indexing/block-indexing | https://archive.is/wip/hNBHz :
  #
  #    "Important: For the noindex rule to be effective, the page or resource must not be blocked by a
  #    robots.txt file, and it has to be otherwise accessible to the crawler. If the page is blocked
  #    by a robots.txt file or the crawler can't access the page, the crawler will never see the noindex
  #    rule, and the page can still appear in search results, for example if other pages link to it."

  req.dynamicHead = req.dynamicHead or ""

  if process.env.ALLOW_SEARCH_ENGINES_INDEXING isnt "true"
    req.dynamicHead += """
      <meta name="robots" content="noindex">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    """

  next()

  return
