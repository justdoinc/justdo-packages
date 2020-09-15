_.extend JustdoGridGantt.prototype,
  _immediateInit: ->
    self = @

    return
      
  _deferredInit: ->
    self = @
    
    if @destroyed
      return
    
    @registerConfigTemplate()
    @setupCustomFeatureMaintainer()

    return

  setupCustomFeatureMaintainer: ->
    self = @
    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoGridGantt.project_custom_feature_id,
        installer: =>

          return
    
        destroyer: =>

          return

    @onDestroy =>
      custom_feature_maintainer.stop()

      return

    return

  setupContextMenu: ->
    self = @

    context_menu = APP.justdo_tasks_context_menu
    
    return

  unsetContextMenu: ->
    context_menu = APP.justdo_tasks_context_menu

    return
  
