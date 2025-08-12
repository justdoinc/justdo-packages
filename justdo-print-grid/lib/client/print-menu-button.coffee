Template.print_menu_button.helpers
  isMainGc: ->
    if not (gc = @getGridControl())?
      return false
    
    if not (gcm = APP.modules.project_page.getCurrentGcm())?
      return false
    
    return gc.getDomain() is gcm.getDomain()

  taskIsSelectedNotInMultiSelectMode: ->
    if not (gc = @getGridControl())?
      return false

    return not gc.isMultiSelectMode() and gc.getCurrentPath()