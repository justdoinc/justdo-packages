Template.print_menu_button.helpers
  taskIsSelectedNotInMultiSelectMode: ->
    if not (gc = @getGridControl())?
      return false

    return not gc.isMultiSelectMode() and gc.getCurrentPath()