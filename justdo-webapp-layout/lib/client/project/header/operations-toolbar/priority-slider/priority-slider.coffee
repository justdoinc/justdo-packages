APP.executeAfterAppLibCode ->
  tpl_instances = {}

  Template.justdo_priority_slider.getInstance = (id) ->
    return tpl_instances[id]

  Template.justdo_priority_slider.onCreated ->
    @_is_enabled = false
    @_value = null
    @_onChangeCallbacks = []
    @_id_rv = new ReactiveVar ""
    @getId = -> @_id_rv.get()
    @getIdNonReactive = -> Tracker.nonreactive => @_id_rv.get()
    @setId = (id) => @_id_rv.set id

    @autorun (computation) =>
      if not (gc = @data.getGridControl())?
        return

      _id = "operations_toolbar_priority_slider_#{gc.getGridUid()}"
      @setId _id
      tpl_instances[@getIdNonReactive()] = @

      computation.stop()
      return

    @setValue = (value, trigger_callbacks = true) =>
      if _.isEmpty(_id = @getIdNonReactive())
        return

      if (not value?) or @_value == value
        return

      @_value = value
      if @is_enabled()
        $("##{_id} .jd-priority-slider").slider "value", value
        $("##{_id} .jd-priority-slider-handle").css "left", value + "%"
        $("##{_id} .ui-slider-range").attr("style", "background: " + JustdoColorGradient.getColorRgbString(value) + " !important; width: " + value + "%")
        if trigger_callbacks
          for callback in @_onChangeCallbacks
            callback value, @
      return

    @getValue = =>
      return @_value

    @enable = =>
      if _.isEmpty(_id = @getIdNonReactive())
        return

      @_is_enabled = true
      $("##{_id} .jd-priority-slider").slider "enable"
      return
    
    @disable = =>
      if _.isEmpty(_id = @getIdNonReactive())
        return

      @_is_enabled = false
      $("##{_id} .jd-priority-slider").slider "disable"
      return
    
    @is_enabled = =>
      return @_is_enabled

    @onChange = (callback) =>
      @_onChangeCallbacks.push callback
      return


  Template.justdo_priority_slider.onRendered ->
    tpl = @

    @autorun (computation) =>
      if _.isEmpty(_id = tpl.getId())
        return

      $("##{_id} .jd-priority-slider").slider
        range: 'min'
        value: 0
        min: 0
        max: 100
        create: ->
          $("##{_id} .jd-priority-slider-handle")
        slide: (event, ui) ->
          $("##{_id} .ui-slider-range").attr("style", "background: " + JustdoColorGradient.getColorRgbString(ui.value or 0) + " !important")
          $("##{_id} .jd-priority-value").text ui.value
        start: (event, ui) ->
          $("##{_id} .jd-priority-value").fadeIn()
        stop: (event, ui) ->
          $("##{_id} .jd-priority-value").fadeOut()
        change: (event, ui) ->
          tpl.setValue ui.value
        
      computation.stop()
      return
    
    return

  Template.justdo_priority_slider.helpers
    getId: ->
      return Template.instance().getId()

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
        $("##{tpl.getIdNonReactive()} .jd-priority-value").text(value).fadeIn().fadeOut()
  
  Template.justdo_priority_slider.onDestroyed ->
    delete tpl_instances[Template.instance().getIdNonReactive()]