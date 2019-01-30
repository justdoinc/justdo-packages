_.extend JustdoPluginStore.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  getPluginsStoreManager_default_options:
    use_bootstrap_layout: false

  getPluginsStoreManager: (options) ->
    options = _.extend {}, @getPluginsStoreManager_default_options, options

    default_category = "featured"
    active_category_rv = new ReactiveVar default_category

    active_plugin_page_rv = new ReactiveVar null

    store_manager =
      useBootstrapLayout: ->
        return options.use_bootstrap_layout

      listCategories: ->
        categories = share.store_db.categories

        if not (cur_proj = APP?.modules?.project_page?.curProj())?
          return categories

        categories = categories.slice()

        categories.splice(1, 0, share.store_db.installed_category_def)

        return categories

      getDefaultCategory: -> default_category

      getActiveCategory: -> active_category_rv.get()

      clearActiveCategory: ->
        active_category_rv.set default_category

        return

      setActiveCategory: (category) ->
        active_category_rv.set category

        return

      setActivePluginPage: (plugin_id) -> active_plugin_page_rv.set plugin_id

      getActivePluginPage: -> active_plugin_page_rv.get()

      getPluginIdPluginObject: (plugin_id) -> _.find share.store_db.plugins, (plugin_def) -> plugin_def.id is plugin_id

      getActivePluginPageObject: -> @getPluginIdPluginObject(active_plugin_page_rv.get())

      clearActivePluginPage: -> active_plugin_page_rv.set null

      showPluginPageMode: -> @getActivePluginPage() is null

      isActivePluginPageIsInstalledCategory: ->
        return @getActiveCategory() == share.store_db.installed_category_def.id

      listActiveCategoryPlugins: ->
        if @isActivePluginPageIsInstalledCategory()
          return _.filter share.store_db.plugins, (plugin) =>
            return @isPluginInstalled(plugin.id)

        return _.filter share.store_db.plugins, (plugin) =>
          return @getActiveCategory() in plugin.categories

      activePluginPagePluginInstallable: ->
        active_plugin_page_object = @getActivePluginPageObject()

        cur_proj = APP?.modules?.project_page?.curProj()

        if not active_plugin_page_object? or not cur_proj? or not Package[active_plugin_page_object.package_name]? or not cur_proj.isAdmin()
          return false

        return true

      activePluginPagePluginEnabledForEnvironment: ->
        active_plugin_page_object = @getActivePluginPageObject()

        return active_plugin_page_object.isPluginEnabledForEnvironment()

      isPluginInstalled: (plugin_id) ->
        if not (cur_proj = APP?.modules?.project_page?.curProj())?
          return 

        if not (plugin_obj = @getPluginIdPluginObject(plugin_id))?
          throw new Error("Unknown plugin ID")

        return cur_proj.isCustomFeatureEnabled(plugin_obj.package_project_custom_feature_id)

      activePluginPagePluginInstalled: ->
        active_plugin_page_object = @getActivePluginPageObject()

        cur_proj = APP?.modules?.project_page?.curProj()

        return cur_proj.isCustomFeatureEnabled(active_plugin_page_object.package_project_custom_feature_id)

      activePluginPagePluginToggleInstallPage: ->
        active_plugin_page_object = @getActivePluginPageObject()

        if not @activePluginPagePluginInstallable()
          throw new Error("Can't toggle install state for plugin #{active_plugin_page_object.id}")

        cur_proj = APP?.modules?.project_page?.curProj()

        module_id = active_plugin_page_object.package_project_custom_feature_id

        if cur_proj.isCustomFeatureEnabled(module_id)
          cur_proj.disableCustomFeatures(module_id)
        else
          cur_proj.enableCustomFeatures(module_id)

        return

    return store_manager