# Plugins allow adding functionality to the grid-control that, while being
# very common, we don't see it as a core feature of grid-control.
# The plugins infrastructure allows us to avoid introducing a new dependent package
# for that functionality in that case, but still maintain a good seperation of concern.

PACK.Plugins = {}

_.extend GridControl.prototype,
  _loaded_plugins = null

  _init_plugins: ->
    @_loaded_plugins = []

    for plugin_name, plugin of PACK.Plugins
      if plugin.init?
        @_loaded_plugins.push plugin_name

        plugin.init.call(@)

  _destroy_plugins: ->
    if @_loaded_plugins?
      # if initiated
      for plugin_name in @_loaded_plugins
        plugin = PACK.Plugins[plugin_name]

        if plugin.destroy?
          plugin.destroy.call(@)