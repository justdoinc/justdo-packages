GridControl.installFormatter JustdoCustomPlugins.justdo_task_duration_pseudo_field_formatter_id,
  slick_grid: ->
    {schema, doc, path} = @getFriendlyArgs()
    if (duration_days = doc[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id])?
      duration_str = "#{duration_days} day"
      if duration_days > 1
        duration_str += "s"
      return "<div class='justdo-task-duration-slick-grid'>#{duration_str}</div>"
    return ""
  
  print: ->
    {schema, doc, path} = @getFriendlyArgs()
    if (duration_days = doc[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id])?
      duration_str = "#{duration_days} day"
      if duration_days > 1
        duration_str += "s"
      return duration_str
    return ""