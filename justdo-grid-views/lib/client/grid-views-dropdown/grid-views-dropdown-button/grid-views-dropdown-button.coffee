APP.executeAfterAppLibCode ->
  Template.grid_views_dropdown_button.onCreated ->
    @autorun ->
      if (active_project_id = JD.activeJustdoId())?
        APP.justdo_grid_views.subscribeGridViews({type: "justdo", justdo_id: JD.activeJustdoId()})
      else
        APP.justdo_grid_views.unsubscribeGridViews()

  Template.grid_views_dropdown_button.onRendered ->
    # defined in ./grid-views-dropdown-menu/grid-views-dropdown-menu.coffee
    @grid_views_dropdown = new share.GridViewsDropdown @find("#grid-views-dropdown-button")

    return

  Template.grid_views_dropdown_button.onDestroyed ->
    @grid_views_dropdown?.destroy()
    APP.justdo_grid_views.unsubscribeGridViews()

    return

  return
