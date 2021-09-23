APP.justdo_tooltips.registerTooltip
  id: "expand-grid"

  template: "expand_grid_tooltip"

Template.expand_grid_tooltip.onCreated ->
  @tooltip_controller = @data.tooltip_controller

Template.expand_grid_tooltip.helpers
  levels: ->
    return [1, 2, 3]

Template.expand_grid_tooltip.events
  "click .expand-grid-all": (e, tpl) ->
    console.log "Expand all"

    return

  "click .expand-grid-level": (e, tpl) ->
    level = $(e.currentTarget).attr "level"

    console.log level

    return

  "click .dropdown-item": (e, tpl) ->
    tpl.tooltip_controller.closeTooltip()

    return
