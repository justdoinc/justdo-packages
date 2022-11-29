GridControl.installFormatter "owner_fullname_formatter",
  slickGridColumnStateMaintainer: ->
    # current_baseline = APP.justdo_planning_utilities.getCurrentBaseline() 
    # JustdoHelpers.getUserPreferredDateFormat()

    return

  slick_grid: ->
    {schema, doc, path} = @getFriendlyArgs()

    # # baseline = @getCurrentColumnData "baseline"
    # baseline = APP.justdo_planning_utilities.getCurrentBaseline() 
    # if not (baseline_start_date = baseline?.data?[doc._id]?.start_date)?
    #   return ""

    # return "<div class='grid-formatter uni-date-formatter'>#{moment(baseline_start_date).format(JustdoHelpers.getUserPreferredDateFormat())}</div>"
    return JustdoHelpers.displayName(doc.owner_id)


  
  print: ->
    {schema, doc, path} = @getFriendlyArgs()

    # baseline = APP.justdo_planning_utilities.getCurrentBaseline() 
    # if not (baseline_start_date = baseline?.data?[doc._id]?.start_date)?
    #   return ""

    # return moment(baseline_start_date).format(JustdoHelpers.getUserPreferredDateFormat())
    return JustdoHelpers.displayName(doc.owner_id)