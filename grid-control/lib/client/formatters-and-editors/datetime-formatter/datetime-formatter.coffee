GridControl.installFormatter "datetimeFormatter",
  getDateTimeString: (value) -> JustdoHelpers.getDateTimeStringInUserPreferenceFormat(value)

  slickGridColumnStateMaintainer: ->
    if not Tracker.active
      @logger.warn "slickGridColumnStateMaintainer: called outside of computation, skipping"

      return

    # Create a dependency and depend on it.
    dep = new Tracker.Dependency()
    dep.depend()

    profile_date_format_computation = null
    Tracker.nonreactive =>
      # Run in an isolated reactivity scope
      profile_date_format_computation = Tracker.autorun =>
        current_val = JustdoHelpers.getUserPreferredDateFormat() # Reactive
        cached_val = @getCurrentColumnData("user_preferred_date_format") # non reactive

        if current_val != cached_val
          @setCurrentColumnData("user_preferred_date_format", current_val)

          dep.changed()

        return

    Tracker.onInvalidate ->
      profile_date_format_computation.stop()

    return

  slick_grid: ->
    {value, formatter_obj} = @getFriendlyArgs()

    formatter = """
      <div class="grid-formatter datetime-formatter">#{formatter_obj.getDateTimeString(value)}</div>
    """

    return formatter

  print: (doc, field, path) ->
    {value, options, formatter_obj} = @getFriendlyArgs()

    return formatter_obj.getDateTimeString(value)
