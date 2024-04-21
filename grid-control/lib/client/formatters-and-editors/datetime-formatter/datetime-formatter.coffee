GridControl.installFormatter "datetimeFormatter",
  getDateTimeString: (value) -> JustdoHelpers.getDateTimeStringInUserPreferenceFormat(value, undefined, true) # undefined is to use the default show_seconds; true is to use the non-reactive version

  slickGridColumnStateMaintainer: ->
    if not Tracker.active
      @logger.warn "slickGridColumnStateMaintainer: called outside of computation, skipping"

      return

    # Create a dependency and depend on it.
    dep = new Tracker.Dependency()
    dep.depend()

    profile_date_format_computation = null
    profile_use_am_pm_computation = null
    Tracker.nonreactive =>
      # Run in an isolated reactivity scope
      profile_date_format_computation = Tracker.autorun =>
        current_val = JustdoHelpers.getUserPreferredDateFormat() # Reactive
        cached_val = @getCurrentColumnData("user_preferred_date_format") # non reactive

        if current_val != cached_val
          @setCurrentColumnData("user_preferred_date_format", current_val)

          dep.changed()

        return

      # Run in an isolated reactivity scope
      profile_use_am_pm_computation = Tracker.autorun =>
        current_val = JustdoHelpers.getUserPreferredUseAmPm() # Reactive
        cached_val = @getCurrentColumnData("user_preferred_use_am_pm") # non reactive

        if current_val != cached_val
          @setCurrentColumnData("user_preferred_use_am_pm", current_val)

          dep.changed()

        return

    Tracker.onInvalidate ->
      profile_date_format_computation.stop()
      profile_use_am_pm_computation.stop()

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
