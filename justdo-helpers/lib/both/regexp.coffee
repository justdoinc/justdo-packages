_.extend JustdoHelpers,
  escapeRegExp: (str) ->
    return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")