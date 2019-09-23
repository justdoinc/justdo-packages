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
        $(".jd-priority-value").text ui.value
      start: (event, ui) ->
        $(".jd-priority-value").fadeIn()
      stop: (event, ui) ->
        $(".jd-priority-value").fadeOut()
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


  Template.project_operations_priority_slider.events
    "click .tick-0": (e, tmpl) ->
      task_id = APP.modules.project_page.activeItemId()
      if task_id?
        APP.collections.Tasks.update task_id, {$set: {priority: 0}}
        $(".jd-priority-value").text("0").fadeIn().fadeOut()

    "click .tick-25": (e, tmpl) ->
      task_id = APP.modules.project_page.activeItemId()
      if task_id?
        APP.collections.Tasks.update task_id, {$set: {priority: 25}}
        $(".jd-priority-value").text("25").fadeIn().fadeOut()

    "click .tick-50": (e, tmpl) ->
      task_id = APP.modules.project_page.activeItemId()
      if task_id?
        APP.collections.Tasks.update task_id, {$set: {priority: 50}}
        $(".jd-priority-value").text("50").fadeIn().fadeOut()

    "click .tick-75": (e, tmpl) ->
      task_id = APP.modules.project_page.activeItemId()
      if task_id?
        APP.collections.Tasks.update task_id, {$set: {priority: 75}}
        $(".jd-priority-value").text("75").fadeIn().fadeOut()

    "click .tick-100": (e, tmpl) ->
      task_id = APP.modules.project_page.activeItemId()
      if task_id?
        APP.collections.Tasks.update task_id, {$set: {priority: 100}}
        $(".jd-priority-value").text("100").fadeIn().fadeOut()
