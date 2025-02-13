# Note: This is a custom helper that we use to guard translations in Handlebars templates.
# We can't simply add a xssGuard helper and chain it with the translation helper because
# Handlebars doesn't support chaining helpers.
OriginalHandlebars.registerHelper "xssGuardTranslation", (key, options) ->
  options = options?.hash or options or {}
  
  # First get the translation
  translated = TAPi18n.__(key, options)
  
  # Then apply XSS guard with HTML parsing enabled
  xssOptions = 
    allow_html_parsing: true
    enclosing_char: ""
    noFormatting: true
  
  return JustdoHelpers.xssGuard(translated, xssOptions)
