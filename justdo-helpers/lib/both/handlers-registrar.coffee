_.extend JustdoHelpers,
  setupHandlersRegistry: (target_object) ->
    handlers_regisrtry = {}

    # Note, we can't use on/off as the event emitter already using those.
    #
    # We don't use the event emitter as we want more control over handlers changes reactivity,
    # and, potentially, in the future, we might want to extend the capabilities further and
    # take slight different direction then the event emitter.

    for method_name in ["register", "unregister", "getHandlers"]
      if method_name of target_object
        throw new Error("Can't set a handlers registry on the provided object, method name #{method_name} already set.")

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

    return