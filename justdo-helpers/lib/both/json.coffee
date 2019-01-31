_.extend JustdoHelpers,
  jsonComp: (x, y, options) ->
    if (exclude_fields = options?.exclude_fields)? and
        _.isArray exclude_fields
      # Make a shallow copy
      x = _.extend x
      y = _.extend y

      for field in exclude_fields
        delete x[field]
        delete y[field]

    return JSON.sortify(x) == JSON.sortify(y)

  getCircularReplacer: ->
    # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Errors/Cyclic_object_value

    # Usage: JSON.stringify(circularReference, JustdoHelpers.getCircularReplacer());
    seen = new WeakSet()

    return (key, value) ->
      if typeof value == 'object' and value != null
        if seen.has(value)
          return
        seen.add value
      return value