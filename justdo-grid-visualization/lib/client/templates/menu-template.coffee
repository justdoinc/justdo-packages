Template.grid_visualization_menu.helpers
  ready: () ->
    gcm = APP.modules.project_page.getCurrentGcm() # reactive
    gc = gcm?.getActiveGridControl(true) # reactive, the true means to return the grid control only when it's ready (with grid data sub object). will return null if no grid control exists, or if not ready.

    return gc?

Template.grid_visualization_menu.events
  "click .btn-grid-visualization": (e, tmpl) ->
    APP.justdo_grid_visualization.showVisualization()
