_.extend JustdoHelpers,
  initModule: (module_name, module_human_readable_name) ->
    APP.modules[module_name] = ->
      EventEmitter.call @

      return @

    Util.inherits APP.modules[module_name], EventEmitter

    APP.modules[module_name] = new APP.modules[module_name]() # Singelton

    APP.modules[module_name].logger = Logger.get "#{module_human_readable_name} Module"

    APP.modules[module_name]._error = JustdoHelpers.constructor_error

    return APP.modules[module_name]