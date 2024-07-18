if (templating = Package.templating)?
  {Template} = templating

  Template.registerHelper "xssGuard", (input, options) ->
    # Important, the reason we don't worry about enclosing_char here, is
    # because on blaze a triple curly braces helper {{{}}} can't appear
    # inside an attribute value - compilation will fail for:
    # <div title="{{{}}}"></div>

    options = options?.hash or {}
    options = _.extend {}, options, 
      allow_html_parsing: true
      enclosing_char: ""
        
    return JustdoHelpers.xssGuard input, options