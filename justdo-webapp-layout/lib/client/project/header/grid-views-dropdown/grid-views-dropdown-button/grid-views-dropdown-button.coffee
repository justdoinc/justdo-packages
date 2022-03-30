APP.executeAfterAppLibCode ->
  Template.grid_views_dropdown_button.onCreated ->
    APP.justdo_grid_views.subscribeGridViews({type: "justdo", justdo_id: JD.activeJustdoId()})

    return

  Template.grid_views_dropdown_button.onRendered ->
    # defined in ./grid-views-dropdown-menu/grid-views-dropdown-menu.coffee
    @grid_views_dropdown = new share.GridViewsDropdown @find("#grid-views-dropdown-button")

    return

  Template.grid_views_dropdown_button.onDestroyed ->
    @grid_views_dropdown?.destroy()
    APP.justdo_grid_views.unsubscribeGridViews()

    return

  return
