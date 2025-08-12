Template.project_operations_toolbar.onRendered ->
  priority_slider = null
  
  @autorun (computation) =>
    if not (gc = @data.getGridControl())?
      return

    grid_uid = gc.getGridUid()
    priority_slider = Template.justdo_priority_slider.getInstance "operations_toolbar_priority_slider_#{grid_uid}"

    priority_slider.onChange (value, tpl) ->
      task_id = gc.activeItemId()
      if task_id?
        APP.collections.Tasks.update task_id, {$set: {priority: value}}

      return
    
    computation.stop()
    return

  @autorun =>
    if not (gc = @data.getGridControl())? or not priority_slider?
      return

    if not gc.isMultiSelectMode() and (task = gc?.activeItemObj())?
      priority_slider.enable()
      priority_slider.setValue task.priority, false
    else
      priority_slider.disable()

    return

  return


Template.project_operations_toolbar.helpers
  itemDuplicateControlExist: -> Template.item_duplicate_control?

  displayPrioritySlider: ->
    gc = @getGridControl()
    if not (item_id = gc?.activeItemId())?
      # If no item is selected - display
      return true

    return APP.justdo_permissions?.checkTaskPermissions("task-field-edit.priority", item_id)

  isQuickAddDisabled: ->
    return APP.modules.project_page.curProj()?.isCustomFeatureEnabled share.disable_quick_add_custom_plugin_id

  showTabExit: ->
    active_tab = APP.modules.project_page.tab_switcher_manager.getCurrentSectionItem()

    if active_tab.tab_id == "main" or active_tab.tab_id == "loading"
      return false

    return true
  
  getGridControl: ->
    return @getGridControl
  
  gridUid: ->
    return @getGridControl()?.getGridUid()

Template.project_operations_toolbar.events
  "click .tab-switcher-exit-btn": (e, tpl) ->
    gcm = APP.modules.project_page.getCurrentGcm()
    gcm.activateTabWithSectionsState("main")

    return
