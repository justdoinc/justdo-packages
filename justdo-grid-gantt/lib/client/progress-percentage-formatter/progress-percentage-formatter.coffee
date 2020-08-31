GridControl.installFormatter JustdoGridGantt.progress_percentage_pseudo_field_formatter_id,
  slick_grid: ->
    {schema, doc, path} = @getFriendlyArgs()
    if (percentage = doc[JustdoGridGantt.progress_percentage_pseudo_field_id])?
      return "<div class='progress-percentage-slick-grid'>#{percentage}%</div>"
    return ""
  
  print: ->
    return ""