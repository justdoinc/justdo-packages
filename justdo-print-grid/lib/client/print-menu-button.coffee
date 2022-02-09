Template.print_menu_button.helpers
  taskIsSelectedNotInMultiSelectMode: ->
    if not (gc = APP.modules.project_page.gridControl())?
      return false

    return not gc.isMultiSelectMode() and gc.getCurrentPath()