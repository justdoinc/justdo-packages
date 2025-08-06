Template.project_operations_toolbar.onRendered ->
  priority_slider = Template.justdo_priority_slider.getInstance "operations_toolbar_priority_slider"

  priority_slider.onChange (value, tpl) ->
    task_id = APP.modules.project_page.activeItemId()
    if task_id?
      APP.collections.Tasks.update task_id, {$set: {priority: value}}

    return

  @autorun =>
    if not (gc = @data.getGridControl())?
      return

    if not gc.isMultiSelectMode() and (task = APP.modules.project_page.activeItemObj())?
      priority_slider.enable()
      priority_slider.setValue task.priority, false
    else
      priority_slider.disable()

    return

  return


Template.project_operations_toolbar.helpers
  itemDuplicateControlExist: -> Template.item_duplicate_control?

  displayPrioritySlider: ->
    if not (item_id = JD.activeItemId())?
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

Template.project_operations_toolbar.events
  "click .tab-switcher-exit-btn": (e, tpl) ->
    gcm = APP.modules.project_page.getCurrentGcm()
    gcm.activateTabWithSectionsState("main")

    return
