_.extend JustdoSplitView.prototype,
  setup: ->
    @enabled = new ReactiveVar false
    @size = new ReactiveVar 0
    @position = new ReactiveVar "left"
    @template = new ReactiveVar null

    @_loaded_template = null

    @split_view_support_state_computation = Tracker.autorun =>
      enabled = @enabled.get()

      # Reactive only to @enabled
      Tracker.nonreactive =>
        if enabled == true
          @logger.debug "JustdoSplitView: enabled, initiating"

          @setupSplitView()

          @logger.debug "JustdoSplitView: init complete"
        else
          @removeSplitView()

          @logger.debug "JustdoSplitView: disabled"

      return

    @split_view_size_and_position_computation = Tracker.autorun =>
      enabled = @enabled.get()

      if enabled
        @size.get() # read only for reactivity
        @position.get() # read only for reactivity

        # Reactive only to @enabled, @size, @position
        Tracker.nonreactive =>
          @updateWindowDimToRequiredGravity()
          @updateWindowDimToRequiredOffset()
          @updateSplitViewSizeAndPosition()

      return

    @split_view_template_computation = Tracker.autorun =>
      if not @enabled.get()
        @_destroyTemplate()

        return

      if not @template.get()?
        @_destroyTemplate()
      else
        @_updateTemplate()

      return

    return

  _destroyTemplate: ->
    if @_loaded_template == null
      # Nothing to do
      return

    @_loaded_template.destroy()
    @_loaded_template = null

    return

  _updateTemplate: ->
    # This method assumes @enabled is true and @template is not null

    Tracker.nonreactive =>
      # We don't want the template to trigger reactivity
      if @_loaded_template != null
        @_destroyTemplate()

      @_loaded_template = JustdoHelpers.renderTemplateInNewNode(@template.get())

      $node = $(@_loaded_template.node)

      $node.addClass("justdo-project-pane-container")

      @container.append $node

      return

    return

  setupSplitView: ->
    if @container?
      @logger.warn "Container already exists, skipping setup"

      return
    
    @container = $("<div>")
      .addClass("justdo-split-view")
      .appendTo(".global-wrapper")
      # .html("""<div class="place-holder"></div><iframe class="split-view-iframe" frameborder="0" width="100%" height="100%" src="#{@url.get()}"></iframe>""")

    @updateWindowDimToRequiredGravity()
    @updateWindowDimToRequiredOffset()
    @updateSplitViewSizeAndPosition()

    return

  removeSplitView: ->
    if not @container?
      @logger.debug "Nothing to remove"

      return

    @container.remove()
    @container = null

    @updateWindowDimToRequiredOffset(0) # force 0 size

    return

  getRequiredWindowDimOffset: (size) ->
    # size can either take size as parameter, or take size
    # from @size (the default behavior)
    window_dim_offset = {width: 0, height: 0}

    if not size?
      size = @size.get()

    if @enabled.get() == false or size == 0
      return window_dim_offset

    if @position.get() in ["left", "right"]
      window_dim_offset.width = size
    else
      window_dim_offset.height = size

    return window_dim_offset

  updateWindowDimToRequiredOffset: (size) ->
    # size can either take size as parameter, or take size
    # from @size (the default behavior)

    required_custom_window_dim_offset = @getRequiredWindowDimOffset(size)
    APP.modules.main.custom_window_dim_offset.set(required_custom_window_dim_offset)

    return

  getRequiredWindowDimGravity: ->
    pos = @position.get()

    # pos is the position of the split view, gravity is the
    # .app-wrapper's gravity

    gravity = "nw" # default val to work with

    if pos == "top"
      # note js strings aren't mutable, we can't do gravity[0] = "s"
      gravity = "sw"
    else if pos == "left"
      gravity = "ne"
    
    return gravity

  updateWindowDimToRequiredGravity: ->
    required_window_dim_gravity = @getRequiredWindowDimGravity()
    APP.modules.main.custom_window_dim_gravity.set(required_window_dim_gravity)

    return

  updateSplitViewSizeAndPosition: ->
    split_view_size_css =
      width: "100%"
      height: "100%"
      position: "fixed"
      top: "auto"
      right: "auto"
      bottom: "auto"
      left: "auto"

    # position
    pos = @position.get()

    if pos in ["left", "right"]
      split_view_size_css.top = "0"
      split_view_size_css.bottom = "0"

      if pos == "left"
        split_view_size_css.left = "0"
      else
        split_view_size_css.right = "0"

    if pos in ["bottom", "top"]
      split_view_size_css.right = "0"
      split_view_size_css.left = "0"

      if pos == "top"
        split_view_size_css.top = "0"
      else
        split_view_size_css.bottom = "0"

    # size
    required_window_dim_offset =
      @getRequiredWindowDimOffset()

    if (width = required_window_dim_offset.width) != 0
      split_view_size_css.width = "#{width}px"

    if (height = required_window_dim_offset.height) != 0
      split_view_size_css.height = "#{height}px"

    # special case, if both 0, size should be 0
    if width == 0 and height == 0
      split_view_size_css.width = 0
      split_view_size_css.height = 0

    @container.css split_view_size_css

    @container
      .removeClass("top-side")
      .removeClass("right-side")
      .removeClass("bottpm-side")
      .removeClass("left-side")

    @container
      .addClass("#{pos}-side")

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @split_view_support_state_computation.stop()
    @split_view_size_and_position_computation.stop()
    @split_view_template_computation.stop()

    @removeSplitView()

    @logger.debug "Destroyed"

    return