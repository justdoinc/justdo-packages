APP.executeAfterAppLibCode ->
  Template.grid_views_dropdown_button.onRendered ->
    # defined in ./grid-views-dropdown-menu/grid-views-dropdown-menu.coffee
    @grid_views_dropdown = new share.GridViewsDropdown @find("#grid-views-dropdown-button"), {getGridControl: @data.getGridControl}

    return

  Template.grid_views_dropdown_button.onDestroyed ->
    @grid_views_dropdown?.destroy()

    return

  return
