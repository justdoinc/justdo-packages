_.extend JustdoHelpers,
  localeAwareNumberRepresentation: (number) ->
    if not number?
      return
    if _.isString number
      number = parseInt number, 10
      
    return number.toLocaleString()

if (templating = Package.templating)?
  {Template} = templating
  
  Template.registerHelper "localeAwareNumberRepresentation", (number) ->
    return JustdoHelpers.localeAwareNumberRepresentation number