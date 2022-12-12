getDisplayName = (user_id) ->
  return JustdoHelpers.displayName(user_id)

GridControl.installFormatter "display_name_formatter",
  slickGridColumnStateMaintainer: ->
    # current_baseline = APP.justdo_planning_utilities.getCurrentBaseline() 
    # JustdoHelpers.getUserPreferredDateFormat()

    return

  slick_grid: ->
    {value} = @getFriendlyArgs()

    display_name = getDisplayName(value) or ""

    formatter_html = """
      <div class="grid-formatter display-name-formatter">
        #{display_name}
      </div>
    """

    return formatter_html
  
  print: ->
    {value} = @getFriendlyArgs()

    return getDisplayName(value)