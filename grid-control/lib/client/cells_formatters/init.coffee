PACK.Formatters = {}
PACK.FormattersInit = {}
PACK.FormattersHelpers = {}

_.extend GridControl.prototype,
  _formatters: null
  _load_formatters: ->
    @_formatters = {}

    for formatter_name, formatter of PACK.Formatters
      do (formatter) =>
        @_formatters[formatter_name] = =>
          formatter.apply(@, arguments)

  _init_formatters: ->
    for formatter_name, formatter of @_formatters
      if formatter_name of PACK.FormattersInit
        if PACK.FormattersInit[formatter_name]?
          PACK.FormattersInit[formatter_name].call(@)
