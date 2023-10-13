_.extend JustdoHelpers,
  localeAwareNumberRepresentation: (number) ->
    if not number?
      return
    if not _.isNumber number
      throw new Error "invalid-argument"
      
    return number.toLocaleString()

if (templating = Package.templating)?
  {Template} = templating
  
  Template.registerHelper "localeAwareNumberRepresentation", (number) ->
    return JustdoHelpers.localeAwareNumberRepresentation number