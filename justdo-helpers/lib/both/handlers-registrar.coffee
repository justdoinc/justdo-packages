_.extend JustdoHelpers,
  setupHandlersRegistry: (target_object) ->
    handlers_regisrtry = {}

    # Note, we can't use on/off as the event emitter already using those.
    #
    # We don't use the event emitter as we want more control over handlers changes reactivity,
    # and, potentially, in the future, we might want to extend the capabilities further and
    # take slight different direction then the event emitter.

    for method_name in ["register", "unregister", "getHandlers", "processHandlers", "processHandlersWithBreakCondition"]
      if method_name of target_object
        throw new Error("Can't set a handlers registry on the provided object, method name #{method_name} already set.")

    processHandlers_default_conf =
      __breakCondition: () => return false

    ensureDomainExists = (domain_name) ->
      if not (domain = handlers_regisrtry[domain_name])?
        domain = handlers_regisrtry[domain_name] =
          handlers: []
          handlers_dep: new Tracker.Dependency()

      return domain

    target_object.getHandlers = (domain_name) =>
      domain = ensureDomainExists(domain_name)

      domain.handlers_dep.depend()

      return domain.handlers.slice() # slice to create a shallow copy

    target_object.register = (domain_name, handler) => # event is reserved word
      domain = ensureDomainExists(domain_name)

      if not _.isFunction handler
        throw new Error("Handler has to be a function")

      if handler in domain.handlers
        return

      domain.handlers.push handler
      domain.handlers_dep.changed()

      return

    target_object.unregister = (domain_name, handler) =>
      domain = ensureDomainExists(domain_name)

      if not _.isFunction handler
        throw new Error("Handler has to be a function")

      domain.handlers = _.without domain.handlers, handler
      domain.handlers_dep.changed()

      return

    target_object.processHandlers = (domain_name, args...) =>
      handlers = target_object.getHandlers(domain_name)

      # We determine whether or not the last arg should be treated as a configuration object
      # according to whether or not it is and object that has any field of our default conf
      # object.
      #
      # If any field found, we regard it as a configuration object, and avoid passing it to
      # the handlers.
      #
      # That's why we prefix the conf fields with __ , to avoid accidentaly recognising an object
      # as configuration object when the developer didn't intend it to be.
      custom_confs = {}
      last_arg = _.last(args)
      if _.isObject(last_arg)
        for default_conf_field_id, val of processHandlers_default_conf
          if default_conf_field_id of last_arg
            custom_confs = last_arg

            break

      conf = _.extend({}, processHandlers_default_conf, custom_confs)

      ret = true
      for handler in handlers
        res = handler.apply(@, args)

        if res == false
          ret = false

        if conf.__breakCondition()
          return ret

      return ret

    target_object.processHandlersWithBreakCondition = (domain_name, breakCondition, args...) =>
      process_handlers_arguments = [].concat(domain_name, args, {__breakCondition: breakCondition})

      return target_object.processHandlers.apply(@, process_handlers_arguments)

    return

