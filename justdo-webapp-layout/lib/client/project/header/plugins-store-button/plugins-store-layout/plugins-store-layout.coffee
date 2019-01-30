Template.plugins_store_layout.onCreated ->
  @store_manager = @data.store_manager

  return

Template.plugins_store_layout.helpers
  showPluginPageMode: ->
    tpl = Template.instance()

    return tpl.store_manager.showPluginPageMode()
