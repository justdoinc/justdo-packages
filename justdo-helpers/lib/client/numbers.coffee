_.extend JustdoHelpers,
  localeAwareNumberRepresentation: (number) ->
    if not number?
      return ""

    if _.isString number
      number = parseFloat number
    
    if _.isNaN number
      return ""
      
    return number.toLocaleString()

if (templating = Package.templating)?
  {Template} = templating
  
  Template.registerHelper "localeAwareNumberRepresentation", (number) ->
    return JustdoHelpers.localeAwareNumberRepresentation number