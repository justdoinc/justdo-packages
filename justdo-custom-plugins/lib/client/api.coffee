_.extend JustdoCustomPlugins.prototype,
  _immediateInit: ->
    @_installed_custom_plugins = {}
    return

  _deferredInit: ->
    if @destroyed
      return

    @registerConfigTemplate()

    return

  installCustomPlugin: (custom_plugin_obj) ->
    if not (custom_plugin_id = custom_plugin_obj.custom_plugin_id)? or not _.isString(custom_plugin_id)
      throw @_error("invalid-argument", "custom_plugin_obj.custom_plugin_id must be a string")
    
    {installer, destroyer} = custom_plugin_obj
    for cb in [installer, destroyer]
      if not cb? or not _.isFunction(cb)
        throw @_error("invalid-argument", "custom_plugin_obj.installer/destroyer must be a function")

    if custom_plugin_id of @_installed_custom_plugins
      throw @_error("invalid-argument", "A custom plugin with custom_plugin_id '#{custom_plugin_id}' already exists")

    @_installed_custom_plugins[custom_plugin_id] =
      # Make a shallow copy to avoid the primitives such as custom_plugin_id to change
      # without us knowing.
      # AND to allow us to add extra items (e.g. the custom_feature_maintainer)
      _.extend {}, custom_plugin_obj 

    @_installed_custom_plugins[custom_plugin_id].original_custom_plugin_obj = custom_plugin_obj

    APP.executeAfterAppLibCode =>
      @_installed_custom_plugins[custom_plugin_id].custom_feature_maintainer =
        APP.modules.project_page.setupProjectCustomFeatureOnProjectPage custom_plugin_id,
          installer: =>
            @_installed_custom_plugins[custom_plugin_id].is_running = true

            installer.call(custom_plugin_obj)

            return

          destroyer: =>
            @_installed_custom_plugins[custom_plugin_id].is_running = false

            destroyer.call(custom_plugin_obj)

            return

      return

    @onDestroy =>
      @uninstallCustomPlugin(custom_plugin_id)

      return

    return

  getCustomPlugins: ->
    return _.extend {}, @_installed_custom_plugins # Shallow copy

  uninstallCustomPlugin: (custom_plugin_id) ->
    if not (custom_plugin_obj = @_installed_custom_plugins[custom_plugin_id])?
      console.warn "No such custom plugin: #{custom_plugin_id}"

      return
    
    custom_plugin_obj.custom_feature_maintainer.stop()

    if custom_plugin_obj.is_running
      custom_plugin_obj.destroyer.call(custom_plugin_obj.original_custom_plugin_obj)

      custom_plugin_obj.is_running = false

    delete @_installed_custom_plugins[custom_plugin_id]

    return