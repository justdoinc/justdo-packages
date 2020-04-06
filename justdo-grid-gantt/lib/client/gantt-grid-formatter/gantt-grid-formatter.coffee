GridControl.installFormatter JustdoGridGantt.pseudo_field_formatter_id,
  slickGridColumnStateMaintainer: ->
    # The following is responsible for full column invalidation upon column width resize.
    if not Tracker.active
      @logger.warn "slickGridColumnStateMaintainer: called outside of computation, skipping"

      return

    # Create a dependency and depend on it.
    dep = new Tracker.Dependency()
    dep.depend()

    column_width_changed_comp = null
    Tracker.nonreactive =>
      # Run in an isolated reactivity scope
      column_width_changed_comp = Tracker.autorun =>
        current_val = _.find(@getViewReactive(), (field) => field.field == @getColumnFieldId())?.width # Reactive
        cached_val = @getCurrentColumnData("column_width") # non reactive

        if current_val != cached_val
          @setCurrentColumnData("column_width", current_val)

          dep.changed()

        return

    Tracker.onInvalidate ->
      column_width_changed_comp.stop()
      return

    return

  slick_grid: ->
    {grid_control, field, path} = @getFriendlyArgs()

    return "When this # change I am being re-rendered: " + Math.ceil(Math.random() * 1000) + "; My width is: " + @getCurrentColumnData("column_width")

  # REMINDER! REMINDER! REMINDER! as this formatter will evolve, definitions of events should be centralized
  # and not redefined for every cell separately. Below is an example from the checklist formatter

  # slick_grid_jquery_events: [
  #   {
  #     args: ["click", ".checklist-field-formatter"]
  #     handler: (e) ->
  #       APP.justdo_checklist_field.toggleItemState(@, @getEventPath(e), @getEventFormatterDetails(e).field_name, allowNaOnCurrentProject())

  #       return
  #   }
  # ]

  print: (doc, field, path) ->
    {grid_control, path, field} = @getFriendlyArgs()

    return ""
