APP.executeAfterAppLibCode ->
  Template.project_operations_priority_slider.onRendered ->
    $(".jd-priority-slider").slider
      range: 'min'
      value: 0
      min: 0
      max: 100
      create: ->
        $(".jd-priority-slider-handle")
      slide: (event, ui) ->
        $(".ui-slider-range").attr("style", "background: " + JustdoColorGradient.getColorRgbString(ui.value or 0) + " !important")
      stop: (event, ui) ->
        task_id = APP.modules.project_page.activeItemId()
        if task_id?
          APP.collections.Tasks.update task_id, {$set: {priority: ui.value}}

    # Make the task_priority_slider reactive
    @autorun ->
      task_id = APP.modules.project_page.activeItemId()
      if task_id?
        $(".jd-priority-slider").slider "enable"
        item = APP.collections.Tasks.findOne task_id
        if item?
          priority = item.priority
          $(".jd-priority-slider-handle").css "left", priority + "%"
          $(".ui-slider-range").attr("style", "background: " + JustdoColorGradient.getColorRgbString(priority) + " !important; width: " + priority + "%")
      else
        $(".jd-priority-slider").slider "disable"
