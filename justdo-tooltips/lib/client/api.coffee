_.extend JustdoTooltips.prototype,
  _immediateInit: ->
    @_initStateMachine()

    @registered_tooltips = {}

    @_is_enabled = true

    return

  _deferredInit: ->
    if @destroyed
      return

    @$tooltip_container = $(@options.tooltip_container_selector)

    @registerWindowEvents()

    @registerEventsOnNode($("body"))

    return

  jd_tt_regexp: new RegExp("([^?]+)\\??(.*)?$")

  tooltip_conf_prefix: "tt-"

  getTooltipDef: (tooltip_id) -> @registered_tooltips[tooltip_id]

  isEnabled: -> @_is_enabled

  _initStateMachine: ->
    self = @

    @state_machine = new JustdoHelpers.StateMachine
      events:
        "insignificant-area": -> # An area that isn't interesting to us
          current_state = @getState()

          if current_state is "nil"
            # Nothing to do
            return

          if current_state is "showing-tooltip-insignificant-area"
            @extendStateAttr({queued_in_target_pre_show: undefined})

            return

          if "showing-tooltip-insignificant-area" of @map[current_state].allowed_next_states
            @setState("showing-tooltip-insignificant-area")
          else
            @setState("nil")

          return

        "in-target": ($target_container, tooltip_id, raw_options) ->
          current_state = @getState()
          state_attr = @getStateAttr()

          setTargetPreShowToCurrent = =>
            @setState("in-target-pre-show", {$target_container, tooltip_id, raw_options})

            return

          if current_state is "nil" # The simplest case, just change to in-target-pre-show
            setTargetPreShowToCurrent()

            return
          
          is_same_target = state_attr.$target_container.is($target_container)
          
          if is_same_target
            if current_state is "in-target-pre-show"
              # Nothing to do.
              return

            @setState("showing-tooltip-in-target")
          else
            if current_state is "showing-tooltip-insignificant-area"
              @extendStateAttr({queued_in_target_pre_show: {mouseenter_on: new Date(), $target_container, tooltip_id, raw_options}})

          return

        "in-tooltip": ->
          current_state = @getState()

          if "showing-tooltip-in-tooltip" of @map[current_state].allowed_next_states
            @setState("showing-tooltip-in-tooltip")

          return

        "mousedown-outside-tooltip": ->
          @trigger("terminate-tooltip-request")

          return

        "terminate-tooltip-request": ->
          current_state = @getState()

          if current_state is "nil"
            # Nothing to do
            return

          if "close-tooltip" of @map[current_state].allowed_next_states
            @setState("close-tooltip")
          else
            @setState("nil")

          return

      states_map:
        "nil":
          init_state: true

          allowed_next_states:
            "in-target-pre-show": {}

          stateSetter: ->
            @clearStateAttr()

            return

          stateDestroyer: ->
            return

        "in-target-pre-show":
          allowed_next_states:
            "nil": {} # Do nothing
            "in-target-pre-show": {} # Replacing target
            "show-tooltip": {} # Show tooltip

          stateEnteringValidator: (state_options) ->
            if not self.getTooltipDef(state_options.tooltip_id)?
              return "Unknown tooltip_id: #{state_options.tooltip_id}"

            return undefined

          stateSetter: (state_options) ->
            @replaceStateAttr(state_options)

            tooltip_def = self.getTooltipDef(state_options.tooltip_id) # Existence verified in the stateEnteringValidator

            display_delay = tooltip_def.display_delay

            if state_options.mouseenter_on?
              display_delay_offset = (new Date()) - state_options.mouseenter_on

              offsetted_display_delay = display_delay - display_delay_offset

              if offsetted_display_delay < 0
                offsetted_display_delay = 0

              display_delay = offsetted_display_delay

            tooltip_display_timeout = setTimeout =>
              @extendStateAttr({tooltip_display_timeout: undefined})

              @setState("show-tooltip")

              return
            , display_delay

            @extendStateAttr({tooltip_display_timeout: tooltip_display_timeout})

            return

          stateDestroyer: ->
            if (tooltip_display_timeout = @getStateAttr().tooltip_display_timeout)?
              clearTimeout @getStateAttr().tooltip_display_timeout

              @extendStateAttr({tooltip_display_timeout: undefined})

            return

        "show-tooltip":
          allowed_next_states:
            "showing-tooltip-in-target": {} # Show tooltip
            "nil": {}

          stateSetter: ->
            {tooltip_id, raw_options} = @getStateAttr()

            {tooltip_conf, raw_tooltip_template_options} = self.parseRawOptions(raw_options)

            tooltip_def = self.getTooltipDef(tooltip_id)

            configured_tooltip_def = _.extend {}, tooltip_def, tooltip_conf

            raw_tooltip_template_options = _.extend {}, configured_tooltip_def.raw_default_options, raw_tooltip_template_options
            tooltip_template_options = configured_tooltip_def.rawOptionsLoader raw_tooltip_template_options

            @extendStateAttr({configured_tooltip_def, tooltip_template_options})

            tooltip_template_obj = self.renderTooltip()

            @extendStateAttr({tooltip_template_obj})

            self.updateTooltipPosition()

            @setState("showing-tooltip-in-target") # Immediately set the follow-up state

            return

        "showing-tooltip-in-target":
          allowed_next_states:
            "showing-tooltip-insignificant-area": {}
            "showing-tooltip-in-tooltip": {}
            "close-tooltip": {}

          stateSetter: -> return

        "showing-tooltip-in-tooltip":
          allowed_next_states:
            "showing-tooltip-insignificant-area": {}
            "showing-tooltip-in-target": {}
            "close-tooltip": {}

          stateSetter: ->
            return

        "showing-tooltip-insignificant-area":
          allowed_next_states:
            "showing-tooltip-in-target": {}
            "showing-tooltip-in-tooltip": {}
            "close-tooltip": {}

          stateSetter: ->
            {configured_tooltip_def} = @getStateAttr()

            tooltip_close_timeout = setTimeout =>
              @extendStateAttr({tooltip_close_timeout: undefined})

              # After @setState("close-tooltip") , the transition to the "nil" state will clear the state attrs
              # so we pick it up before calling @setState("close-tooltip")
              {queued_in_target_pre_show} = @getStateAttr()

              @setState("close-tooltip")

              # close-tooltip will close the tooltip on the same tick,
              # when the following lines will run we'll already be in "nil"
              # state.
              #
              # If a queued_in_target_pre_show request was pending, trigger it now
              if queued_in_target_pre_show?
                @setState("in-target-pre-show", queued_in_target_pre_show)

              return
            , configured_tooltip_def.hide_delay

            @extendStateAttr({tooltip_close_timeout: tooltip_close_timeout})

            return

          stateDestroyer: ->
            if (tooltip_close_timeout = @getStateAttr().tooltip_close_timeout)?
              clearTimeout @getStateAttr().tooltip_close_timeout

              @extendStateAttr({tooltip_close_timeout: undefined})

            return

        "close-tooltip":
          allowed_next_states:
            "nil": {}

          stateSetter: ->
            {tooltip_template_obj, $target_container} = @getStateAttr()

            tooltip_template_obj.$node.fadeOut JustdoTooltips.tooltip_fadeout_duration, -> tooltip_template_obj.destroy()

            @setState("nil") # Immediately set the follow-up state

            return

    return

  getState: -> @state_machine.getState()

  registerWindowEvents: ->
    self = @

    window.addEventListener "scroll", ->
      self.updateTooltipPosition()
    , true

    return

  registerEventsOnNode: ($container) ->
    self = @

    $container.on "mousedown", (e) ->
      if not self.isEnabled()
        return

      $target = $(e.target)

      if self.getState() is "nil"
        return

      # If state is nil, skip any work, since mousedown can't change the state

      if $target.closest(".jd-tt-container").length is 0
        self.state_machine.trigger("mousedown-outside-tooltip")

      return

    $container.on "mouseenter", "[jd-tt]", (e) ->
      if not self.isEnabled()
        return

      $target_container = $(e.target).closest("[jd-tt]")

      jd_tt_attr = $target_container.attr("jd-tt")

      [, tooltip_id, raw_options] = self.jd_tt_regexp.exec(jd_tt_attr)

      self.state_machine.trigger("in-target", $target_container, tooltip_id, raw_options)

      return

    $container.on "mouseleave", "[jd-tt]", (e) ->
      if not self.isEnabled()
        return

      self.state_machine.trigger("insignificant-area")

      return

    $container.on "mouseenter", ".jd-tt-container", (e) ->
      if not self.isEnabled()
        return

      self.state_machine.trigger("in-tooltip")

      return

    $container.on "mouseleave", ".jd-tt-container", (e) ->
      if not self.isEnabled()
        return

      self.state_machine.trigger("insignificant-area")

      return

    return

  parseRawOptions: (raw_options) ->
    if not raw_options?
      raw_options = ""

    raw_options = raw_options.trim()

    if raw_options is ""
      return {tooltip_conf: {}, raw_tooltip_template_options: {}}

    tooltip_conf = {}
    raw_tooltip_template_options = {}

    _.each raw_options.split("&"), (raw_option) =>
      [option, val] = raw_option.split("=")

      if option.substr(0, @tooltip_conf_prefix.length) == @tooltip_conf_prefix
        tooltip_conf[decodeURIComponent(option.substr(@tooltip_conf_prefix.length))] = decodeURIComponent(val)
      else
        raw_tooltip_template_options[decodeURIComponent(option)] = decodeURIComponent(val)
      
      return 

    return {tooltip_conf, raw_tooltip_template_options}

  closeTooltip: ->
    @state_machine.trigger("terminate-tooltip-request")

    return

  renderTooltip: ->
    {tooltip_id, configured_tooltip_def, tooltip_template_options} = @state_machine.getStateAttr()

    tooltip_controller =
      closeTooltip: =>
        @closeTooltip()

        return

    template_data = {tooltip_controller, options: tooltip_template_options}

    template_obj = JustdoHelpers.renderTemplateInNewNode(configured_tooltip_def.template, template_data)

    $node = $(template_obj.node)

    $node
      .attr("id", @options.tooltip_element_id)
      .addClass("jd-tt-container jd-tt-#{tooltip_id}-container")

    template_obj.$node = $node

    @$tooltip_container.append($node)

    return template_obj

  updateTooltipPosition: ->
    if @getState() is "nil"
      # For efficiency! do nothing if in nil state. This method is called while scrolling
      # and needs to be as efficient as possible!
      return

    {$target_container, configured_tooltip_def, tooltip_template_obj} = @state_machine.getStateAttr()

    if not $target_container.is(":visible")
      @closeTooltip()
      
      return

    if not tooltip_template_obj?.$node?
      return

    tooltip_template_obj.$node
      .position
        of: $target_container
        my: configured_tooltip_def["pos_my"]
        at: configured_tooltip_def["pos_at"]
        collision: configured_tooltip_def["pos_collision"]

    return

  disable: ->
    @_is_enabled = false

    return

  enable: ->
    @_is_enabled = true

    return