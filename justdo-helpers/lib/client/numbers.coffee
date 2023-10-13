_.extend JustdoHelpers,
  localeAwareNumberRepresentation: (number) ->
    if not number?
      return
    browser_locale = navigator.languages?[0] or navigator.language or navigator.userLanguage or navigator.browserLanguage
    return new Intl.NumberFormat(browser_locale).format number

if (templating = Package.templating)?
  {Template} = templating
  
  Template.registerHelper "localeAwareNumberRepresentation", (number) ->
    return JustdoHelpers.localeAwareNumberRepresentation number