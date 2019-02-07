Template.justdo_plugins_store_plugins_list.onCreated ->
  @store_manager = @data.store_manager

  return

Template.justdo_plugins_store_plugins_list.helpers
  isInstalledCateogry: ->
    tpl = Template.instance()

    return tpl.store_manager.isActivePluginPageIsInstalledCategory()

  listActiveCategoryPlugins: ->
    tpl = Template.instance()

    return tpl.store_manager.listActiveCategoryPlugins()

  isActiveCategoryPluginsEmpty: ->
    tpl = Template.instance()

    return _.isEmpty tpl.store_manager.listActiveCategoryPlugins()

  useBootstrapLayout: ->
    tpl = Template.instance()

    return tpl.store_manager.useBootstrapLayout()

  isPluginInstalled: ->
    plugin = @

    tpl = Template.instance()

    return tpl.store_manager.isPluginInstalled(plugin.id)

Template.justdo_plugins_store_plugins_list.events
  "click .plugin-tile": ->
    tpl = Template.instance()

    tpl.store_manager.setActivePluginPage @id

    Tracker.flush()

    $(".store-front").scrollTop(0)
    $(document).scrollTop(0)

    return


  "click .browse-our-featured-plugins": (e) ->
    e.preventDefault()

    tpl = Template.instance()

    tpl.store_manager.setActiveCategory "featured"

    return