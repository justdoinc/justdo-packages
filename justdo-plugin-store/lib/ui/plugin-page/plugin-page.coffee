Template.justdo_plugins_store_plugin_page.onCreated ->
  @store_manager = @data.store_manager

  return

Template.justdo_plugins_store_plugin_page.helpers
  getActivePluginPageObject: ->
    tpl = Template.instance()

    return tpl.store_manager.getActivePluginPageObject()

  activePluginPagePluginInstallable: ->
    tpl = Template.instance()

    return tpl.store_manager.activePluginPagePluginInstallable()

  activePluginPagePluginInstalled: ->
    tpl = Template.instance()

    return tpl.store_manager.activePluginPagePluginInstalled()

  activePluginPagePluginEnabledForEnvironment: ->
    tpl = Template.instance()

    return tpl.store_manager.activePluginPagePluginEnabledForEnvironment()

  isProjectPage: ->
    if (cur_proj = APP?.modules?.project_page?.curProj())?
      return true

    return false

  isProjectPageAdmin: ->
    if (cur_proj = APP?.modules?.project_page?.curProj())?
      if cur_proj.isAdmin()
        return true

    return false

  categories: ->
    tpl = Template.instance()

    cat_names = _.map @categories, (cat_id) ->
      cat_def = _.find tpl.store_manager.listCategories(), (c) -> c.id is cat_id
      return cat_def?.label?.en or "Unknown"

    return cat_names.join(" &bull; ")

  hasMoreThanOneSliderItems: ->
    tpl = Template.instance()

    plugin_def = tpl.store_manager.getActivePluginPageObject()

    if not (slider = plugin_def.slider)?
      return false

    return slider.length > 1

Template.justdo_plugins_store_plugin_page.events
  "click .install-toggle-btn": (e, tpl) ->
    return tpl.store_manager.activePluginPagePluginToggleInstallPage()

  "click .return-to-menu": (e, tpl) ->
    tpl.store_manager.clearActivePluginPage()

    Tracker.flush()

    $(".store-front").scrollTop(0)
    $(document).scrollTop(0)

    return
