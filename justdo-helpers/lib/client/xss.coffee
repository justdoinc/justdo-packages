if (templating = Package.templating)?
  {Template} = templating

  Template.registerHelper "xssGuard", JustdoHelpers.xssGuard