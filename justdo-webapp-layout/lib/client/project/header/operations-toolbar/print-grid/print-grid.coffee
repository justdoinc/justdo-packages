APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  getActiveGridControl = ->
    gcm = project_page_module.getCurrentGcm()

    return gcm?.getActiveGridControl(true) # `true` means require_ready

  setPrintGridMode = ->
    return

  exitPrintGridMode = ->
    return

  Template.project_operations_print_grid.rendered = ->
    onceAddPrintMode = _.once ->
      if (addPrintMode = APP.justdo_print_grid.addPrintMode)?
        addPrintMode()
      else
        project_page_module.logger.error "Can't find addPrintMode() reload the page and try again"

    @autorun ->
      gcm = project_page_module.getCurrentGcm()
      if gcm?.getActiveGridControl(true)?
        onceAddPrintMode()


  #Template.project_operations_print_grid.helpers
  #  isPrintPossible: ->
  #    return getActiveGridControl()?


  # Template.project_operations_print_grid.events
  #   "click #operations-print": ->
