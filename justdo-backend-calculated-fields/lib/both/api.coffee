_.extend JustdoBackendCalculatedFields.prototype,
  isParamsValueIsSystemMessage: (value) ->
    if value?.substr(0, 6) == "Error:"
      return true

    if value?.substr(0, 6) == "Usage:"
      return true

    return false