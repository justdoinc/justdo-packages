APP.executeAfterAppLibCode ->
  tpl_instances = {}

  Template.justdo_priority_slider.getInstance = (id) ->
    return tpl_instances[id]

  Template.justdo_priority_slider.onCreated ->
    if @data?.id?
      @_id = @data.id
    else
      @_id = "jd-priority-slider-#{Math.floor(Math.random() * 1000000)}"

    tpl_instances[@_id] = @

    @_value = null
    @_onChangeCallbacks = []
    @_is_enabled = true

    @setValue = (value, trigger_callbacks = true) =>
      if (not value?) or @_value == value
        return

      @_value = value
      if @is_enabled()
        $("##{@_id} .jd-priority-slider").slider "value", value
        $("##{@_id} .jd-priority-slider-handle").css "left", value + "%"
        $("##{@_id} .ui-slider-range").attr("style", "background: " + JustdoColorGradient.getColorRgbString(value) + " !important; width: " + value + "%")
        if trigger_callbacks
          for callback in @_onChangeCallbacks
            callback value, @
      return

    @getValue = =>
      return @_value

    @enable = =>
      @_is_enabled = true
      $("##{@_id} .jd-priority-slider").slider "enable"
      return
    
    @disable = =>
      @_is_enabled = false
      $("##{@_id} .jd-priority-slider").slider "disable"
      return
    
    @is_enabled = =>
      return @_is_enabled
      
    @onChange = (callback) =>
      @_onChangeCallbacks.push callback
      return


  Template.justdo_priority_slider.onRendered ->
    tpl = @
    $("##{tpl._id} .jd-priority-slider").slider
      range: 'min'
      value: 0
      min: 0
      max: 100
      create: ->
        $("##{tpl._id} .jd-priority-slider-handle")
      slide: (event, ui) ->
        $("##{tpl._id} .ui-slider-range").attr("style", "background: " + JustdoColorGradient.getColorRgbString(ui.value or 0) + " !important")
        $("##{tpl._id} .jd-priority-value").text ui.value
      start: (event, ui) ->
        $("##{tpl._id} .jd-priority-value").fadeIn()
      stop: (event, ui) ->
        $("##{tpl._id} .jd-priority-value").fadeOut()
      change: (event, ui) ->
        tpl.setValue ui.value

  Template.justdo_priority_slider.helpers
    getId: ->
      return Template.instance()._id

    active_is_slider: ->
      return Template.instance().is_enabled()


  Template.justdo_priority_slider.events
    "click .tick": (e ,tpl) ->
      if tpl.is_enabled()
        $ui = $(e.target)
        while not $ui.hasClass "tick"
          $ui = $ui.parent() 
        value = $ui.data "value"
        tpl.setValue value
        $("##{tpl._id} .jd-priority-value").text(value).fadeIn().fadeOut()
  
  Template.justdo_priority_slider.onDestroyed ->
    delete tpl_instances[@_id]