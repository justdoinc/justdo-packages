# We don't use head.html since it doesn't support blaze helpers which we need to set the CDN
# prefix
WebApp.connectHandlers.use (req, res, next) =>
  req.dynamicHead = req.dynamicHead or ""

  if process.env.ALLOW_SEARCH_ENGINES_INDEXING isnt "true"
    req.dynamicHead += """
      <meta name="robots" content="noindex">
    """

  next()

  return
