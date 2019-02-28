if (templating = Package.templating)?
  {Template} = templating

  Template.registerHelper "xssGuard", (input) ->
    # Important, the reason we don't worry about enclosing_char here, is
    # because on blaze a triple curly braces helper {{{}}} can't appear
    # inside an attribute value - compilation will fail for:
    # <div title="{{{}}}"></div>
    return JustdoHelpers.xssGuard input, {allow_html_parsing: true, enclosing_char: ''}