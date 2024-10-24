_.extend JustdoHelpers,
  escapeRegExp: (str) ->
    return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")

  convertToValidFilename: (str) -> 
    # Based on: https://stackoverflow.com/questions/35511331 
    return str.replace(/[\/|\\:*?"<>]/g, " ")
  
  createUnicodeSupportedSearchTermRegex: (search_term) ->
    return new RegExp "(^|\\W|_)#{@escapeRegExp(search_term)}", "i"