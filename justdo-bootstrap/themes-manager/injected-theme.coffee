WebApp.connectHandlers.use (req, res, next) =>
  req.dynamicHead = req.dynamicHead or ""

  # We inject a theme to head on load to avoid no-design-flickering, in the
  # future, we should allow setting predefined theme for the user, to avoid
  # themes flickering
  if (cdn_domain = JustdoHelpers.getCDNDomain())?
    req.dynamicHead += """
      <link id="bootstrap-theme" rel="stylesheet" href="#{JustdoHelpers.getCDNUrl("/packages/justdoinc_bootstrap-themes/default/bootstrap.css")}">
    """

  next()