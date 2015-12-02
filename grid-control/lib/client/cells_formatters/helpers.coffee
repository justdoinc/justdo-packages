helpers = PACK.FormattersHelpers

_.extend helpers,
  nl2br: (text) -> text.replace(/\n/g, "<br>")

  xssGuard: (text) -> (text + "").replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;")