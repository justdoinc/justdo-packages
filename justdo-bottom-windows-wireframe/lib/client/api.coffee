_.extend BottomWindowsWireframe.prototype,
  _immediateInit: ->
    #
    # Init dom
    #
    @$container = $("""<div class="bottom-windows #{@options.window_container_classes}" style="margin-right: #{@options.right_margin}px"></div>""")
    $("body").append(@$container)

    @onDestroy =>
      @$container.remove()

      return

    @extra_windows_btn_tpl_obj = null
    @chat_windows_hide_btn = null
    @extra_windows_ids_rv = new ReactiveVar null, (a, b) -> JSON.stringify(a) == JSON.stringify(b)
                            # Will be null, if there are no extra windows that aren't showing due to insufficient space
                            # Will be an array of windows ids otherwise.

    @onDestroy =>
      @extra_windows_ids_rv.set null

      return

    #
    # Init data structures
    #

    # Structure of @_current_windows_arrangement
    # 
    # Terminology:
    #
    #   * We refer to the items of this array as: 'window_arrangement_def'
    #   * We refer to the items of the array provded to @setWindows() as 'window_def'
    #
    # [
    #   {
    #     id: # The id provided to the setWindows for the window.
    #
    #     window_def: # The window def as provided to @setWindows()
    #
    #     rendered_state: "pre-render"/"insufficient-space"/"min"/"min-with-no-template"/"open"/"pre-removal" # Holds the current rendered state, might be in-consistent
    #                                                       # with window_def.window_state, if there's not enough space to
    #                                                       # render, or if renderWindow haven't been called yet since
    #                                                       # the last setWindows() call.
    # 
    #     re_render_required: false/true # Changes determined by @setWindow(). We turn the re_render_required flag when an existing *rendered* window ("min"/"open" state in the
    #                                    # @_current_windows_arrangement) in a window_arrangement needs re-rendering as a result of a call
    #                                    # to @setWindows() that changes its window_def.
    #                                    #
    #                                    #   The following changes to the window_def will set re_render_required to be true:
    #                                    #
    #                                    #    * window_state is not the currently *rendered* window state
    #                                    #    * open_template changed when remained opened
    #                                    #    * min_template changed when remained minimized
    #                                    #    * data changes (JustdoHelpers.jsonComp compared).
    #                                    #
    #                                    # The fact that a re_render is required, doesn't mean that we will actually rerender the window.
    #                                    # If in the newly provided arrangement, there's no space for the window, we will just remove it
    #                                    # from the dom and will leave it to the extra window button list.
    #
    #     remove: false/true # Changes determined by @setWindow(). If set to true, will be removed in the next call to @_renderWindows()
    #
    #     template_obj: the object returned by JustdoHelpers.renderTemplateInNewNode(), if rendered, null otherwise
    #
    #   }
    # ]
    @_current_windows_arrangement = []
    @_current_windows_arrangement_dep = new Tracker.Dependency()

    return

  _deferredInit: ->
    if @destroyed
      return

    $(window).on "resize", resizeHandler = =>
      @_renderWindows()

      return

    @onDestroy =>
      $(window).off "resize", resizeHandler

      return

    @_setupCustomWindowDimTracker()

    return

  getExtraWindows: -> @extra_windows_ids_rv.get()

  #
  # @_current_windows_arrangement data-structure management
  #
  _setCurrentWindowArrangement: (new_windows_arrangement) ->
    @_current_windows_arrangement = new_windows_arrangement

    @_current_windows_arrangement_dep.changed()

    return

  getWindowsArrangement: ->
    @_current_windows_arrangement_dep.depend()

    return @_current_windows_arrangement

  _getWindowArrangementObjectForWindowDef: (window_def) ->
    window_def = _.extend {}, window_def # shallow copy to avoid surprises later.

    window_arrangement_def =
      id: window_def.id

      window_def: window_def

      rendered_state: "pre-render"
      re_render_required: false
      remove: false
      template_obj: null

    return window_arrangement_def

  _updateWindowArrangementObjectWithNewWindowDef: (window_arrangement_def, new_window_def) ->
    # Updates an existing window_arrangement_def with a new window_def, if needed

    existing_window_def = window_arrangement_def.window_def

    window_arrangement_def.window_def = new_window_def # Update the window_def

    # Find out whether dom re-rendering is required. If not min/open, nothing to re-render.
    if (rendered_state = window_arrangement_def.rendered_state) in ["min", "open"] and
         (
            rendered_state != new_window_def.window_state or # a change to the rendered state requested
              not JustdoHelpers.jsonComp(existing_window_def.data, new_window_def.data, {exclude_fields: @options.data_fields_to_ignore_when_cmp_changes}) or # data changes triggers re-rendering
              (new_window_def.window_state == "open" and (existing_window_def.open_template != new_window_def.open_template)) or
              (new_window_def.window_state == "min" and (existing_window_def.min_template != new_window_def.min_template))
         )
      window_arrangement_def.re_render_required = true

    return window_arrangement_def

  _updateExtraWindows: ->
    extra_windows = _.filter @_current_windows_arrangement, (window_arrangement_def) =>
      if window_arrangement_def.rendered_state == "insufficient-space"
        return true

      return @_isMinimizedWindowWithoutMinimizedTemplate(window_arrangement_def.window_def)

    # If we there are no window to the Extra Windows section
    if _.isEmpty(extra_windows)
      if @extra_windows_btn_tpl_obj?
        @extra_windows_btn_tpl_obj.destroy()
        @extra_windows_btn_tpl_obj = null

      @extra_windows_ids_rv.set null

      return

    # Space exhausted, set up extra windows button if we haven't yet, update extra_windows_ids
    if not @extra_windows_btn_tpl_obj?
      @extra_windows_btn_tpl_obj =
        JustdoHelpers.renderTemplateInNewNode(@options.extra_windows_button_template)

      $node = $(@extra_windows_btn_tpl_obj.node)

      $node.addClass("extra-windows-button-container")
           .attr("style", """width: #{@options.extra_windows_button_width}px;""")

      @$container.append $node

    extra_windows_ids = []
    for window_arrangement_def in extra_windows
      extra_windows_ids.push window_arrangement_def.id

    @extra_windows_ids_rv.set extra_windows_ids

    return

  setWindows: (windows_array) ->
    # Windows array structure.
    #
    # Updates @_current_windows_arrangement with the new window_array, immediately calls
    # _renderWindows() to bring changes into effect (will be called even if no changes happened).
    #
    # Replaces @_current_windows_arrangement with a new array without the removed windows.
    #
    # [
    #    {
    #      id: String # A unique id for the window, will be used to identify
    #                 # re-arrangement/changes/removal of the window.
    #                 #
    #                 # The behavior for case same id will be provided more than
    #                 # once in the windows_array input is undefined.
    #
    #      window_state: "min/open" # The desired state for the window, if space permits.
    #
    #      open_template: String # the template to use when the window is open
    #      min_template: String or undefined # The template to use when the window is minimized
    #                                        # if undefined the window will be part of the Extra windows 
    #
    #      data: # The data object to provide to the open_template/min_template .
    #            # Important! changes to data fields that aren't listed under
    #            # @options.data_fields_to_ignore_when_cmp_changes will cause re-rendering of the
    #            # window. JustdoHelpers.jsonComp() is used to compare objects.
    #    }
    # ]

    if not _.isArray windows_array
      @logger.warn "setWindows called without windows_array"

      return

    new_windows_arrangement = []

    for window_def, i in windows_array
      # Check whether @_current_windows_arrangement got a window with such an id set already.
      # If it does, add the existing window_arrangement_def object to the new_windows_arrangement
      # otherwise, create a new window_arrangement_def for the window.

      existing_window_arrangement_def = null
      for window_arrangement_def, j in @_current_windows_arrangement
        if not window_arrangement_def? # Might be null, if we moved it already to the new_windows_arrangement
          continue
        
        if window_arrangement_def.id == window_def.id
          existing_window_arrangement_def = window_arrangement_def

          break

      # A window for this doesn't exist, see if space is sufficiant for presenting it.
      if not existing_window_arrangement_def?
        new_windows_arrangement.push @_getWindowArrangementObjectForWindowDef(window_def)
      else
        # Move the existing window object to the new_windows_arrangement, update with the provided window_def
        new_windows_arrangement.push @_updateWindowArrangementObjectWithNewWindowDef(existing_window_arrangement_def, window_def)

        @_current_windows_arrangement[j] = null

    for window_arrangement_def in @_current_windows_arrangement
      # Mark for removal existing windows that aren't part of the new arrangement and append to the
      # new_windows_arrangement, actual removal will be handled by @_renderWindows()

      if not window_arrangement_def?
        continue

      window_arrangement_def.remove = true

      new_windows_arrangement.push window_arrangement_def

    @_setCurrentWindowArrangement(new_windows_arrangement)

    @_renderWindows()

    return

  #
  # Rendering related
  #

  _getAvailableWidth: -> $("body").width()

  _destroyWindowTemplate: (window_arrangement_def, new_rendered_state) ->
    # Receives a window_arrangement_def, destroys its template object, if exists.
    if (template_obj = window_arrangement_def.template_obj)?
      template_obj.destroy()

    window_arrangement_def.template_obj = null
    window_arrangement_def.re_render_required = false
    window_arrangement_def.rendered_state = new_rendered_state

    return

  _rerenderWindowTemplate: (window_arrangement_def, window_position) ->
    # Receives a window_arrangement_def, destroys its existing rendered template (if any exists) and renders it

    @_destroyWindowTemplate(window_arrangement_def, "pre-render")

    {id, window_def} = window_arrangement_def

    {window_state} = window_def

    template_obj =
      JustdoHelpers.renderTemplateInNewNode(window_def["#{window_state}_template"], window_def.data)

    $node = $(template_obj.node)

    $node.addClass("window-container")
         .attr("style", """width: #{@options["#{window_state}_window_width"]}px;#{if (window_position < @_current_windows_arrangement.length - 1) then " margin-left: #{@options.width_between_windows}px;" else "" }""")

    @$container.append($node)

    window_arrangement_def.template_obj = template_obj
    window_arrangement_def.re_render_required = false
    window_arrangement_def.rendered_state = window_state

    return

  _updateExistingWindowTemplateFollowingRerendering: (window_arrangement_def, window_position) ->
    # Receives a window, ensure its css compared to other windows, following re-rendering is correct

    $node = $(window_arrangement_def.template_obj.node)

    if (window_position == @_current_windows_arrangement.length - 1)
      $node.css("margin-left", "")
    else
      $node.css("margin-left", @options.width_between_windows + "px")

    return

  _removeRemovedWindowsFromCurrentWindowsArrangement: ->
    # Sub-procedure of @_renderWindows() should only be called by it.
    #
    # Removes from @_current_windows_arrangement windows flagged for removal.
    # Replaces @_current_windows_arrangement with a new array without the removed windows.

    changed = false
    for window_arrangement_def, i in @_current_windows_arrangement
      if window_arrangement_def.remove
        @_destroyWindowTemplate(window_arrangement_def, "pre-removal")

        delete @_current_windows_arrangement[i]

        changed = true

    @_setCurrentWindowArrangement(_.compact(@_current_windows_arrangement))

    return

  _ensureCorrectWindowsArrangement: ->
    got_extra_windows_btn = @extra_windows_btn_tpl_obj?

    # Make sure windows are arranged correctly
    for window_arrangement_def, i in @_current_windows_arrangement
      {rendered_state, template_obj} = window_arrangement_def

      first = i == 0
      # last = i == (@_current_windows_arrangement.length - 1)

      if rendered_state in ["min", "open"]
        $node = $(template_obj.node) # by the time _ensureCorrectWindowsArrangement() is called, template_obj is rendered if rendered_state is min/open, no need to check existence

        if i == $node.index()
          continue

        if first
          @$container.prepend($node)
        # The following doesn't really happen
        # else if last
        #   if got_extra_windows_btn
        #     @extra_windows_btn_tpl_obj.before($node)
        #   else
        #     @$container.append($node)
        else
          @$container.find("> div:eq(#{i - 1})").after($node)

    @$container.append($(".extra-windows-button-container", @$container))

    return

  _isMinimizedWindowWithoutMinimizedTemplate: (window_def) -> window_def.window_state == "min" and not window_def.min_template?

  _renderWindows: ->
    @_removeRemovedWindowsFromCurrentWindowsArrangement()

    available_width = @_getAvailableWidth()

    space_exhausted = false

    space_required_for_extra_windows_button_and_left_margin = 
      @options.width_between_windows_to_extra_windows_button + @options.extra_windows_button_width + @options.left_margin

    chat_windows_hide_btn_show = false

    for window_arrangement_def, i in @_current_windows_arrangement
      {id, window_def} = window_arrangement_def

      if @_isMinimizedWindowWithoutMinimizedTemplate(window_def)
        @_destroyWindowTemplate(window_arrangement_def, "min-with-no-template")

        continue

      # If space exhausted already, no point calculating space sufficiancy again
      if not space_exhausted
        # Check whether space can be allocated for that window.
        window_state = window_def.window_state

        # Come up with the required space
        space_required = @options["#{window_state}_window_width"]

        if i == 0
          # This isn't the first item, add space for the right margin from the previous window
          space_required += @options.right_margin
        else
          # This isn't the first item, add space for the right margin from the previous window
          space_required += @options.width_between_windows

        space_required_plus_required_allocations = space_required

        if i != (@_current_windows_arrangement.length - 1)
          # This isn't the last item, we need to make sure that we'll have space for the extra
          # windows button

          space_required_plus_required_allocations += space_required_for_extra_windows_button_and_left_margin
        else
          # This is the last item, make sure left_margin requirement fulfilled.
          space_required_plus_required_allocations += @options.left_margin

        if space_required_plus_required_allocations > available_width
          space_exhausted = true

      if space_exhausted
        @_destroyWindowTemplate(window_arrangement_def, "insufficient-space")
      else
        available_width -= space_required

        if window_arrangement_def.rendered_state in ["pre-render", "insufficient-space", "min-with-no-template"] or window_arrangement_def.re_render_required
          # If the window weren't rendered before, or, if re-rendering required
          @_rerenderWindowTemplate(window_arrangement_def, i)
        else
          @_updateExistingWindowTemplateFollowingRerendering(window_arrangement_def, i)

    @_updateExtraWindows()

    @_ensureCorrectWindowsArrangement()

    # Show chat_windows_hide_btn if there is an opened chat window
    for window_arrangement_def in @_current_windows_arrangement
      if window_arrangement_def.rendered_state == "open"
        chat_windows_hide_btn_show = true
        break

    if chat_windows_hide_btn_show
      @_renderChatWindowsHideBtn()
    else
      @_removeChatWindowsHideBtn()

    return

  _renderChatWindowsHideBtn: ->
    $(".bottom-windows").removeClass "chats-hidden"

    if not @chat_windows_hide_btn?
      @chat_windows_hide_btn = $("""
        <svg class="bottom-windows-hide bg-primary jd-c-pointer">
          <use class="bottom-windows-hide-down" xlink:href="/layout/icons-feather-sprite.svg#chevron-down"></use>
          <use class="bottom-windows-hide-up" xlink:href="/layout/icons-feather-sprite.svg#chevron-up"></use>
        </svg>
      """)
      @$container.append @chat_windows_hide_btn

      @chat_windows_hide_btn.on "click", ->
        $(".bottom-windows").toggleClass "chats-hidden"

        return

    return

  _removeChatWindowsHideBtn: ->
    $(".bottom-windows-hide").remove()
    @chat_windows_hide_btn = null
    $(".bottom-windows").removeClass "chats-hidden"

    return

  _setupCustomWindowDimTracker: ->
    if @_custom_window_dim_tracker?
      # Already setupped
      return

    @_custom_window_dim_tracker = Tracker.autorun =>

      # Stick chat to the Project-pane TOP

      # if "n" in APP.modules.main.custom_window_dim_gravity.get() and
      #     (custom_win_height = APP.modules.main.custom_window_dim_offset.get().height) != 0
      #   @$container.css({bottom: custom_win_height})
      #
      #   return

      # Stick chat to the window BOTTOM
      if APP.justdo_project_pane.isExpanded()
        @$container.css({bottom: 0})
      else
        custom_win_height = APP.modules.main.custom_window_dim_offset.get().height
        @$container.css({bottom: custom_win_height = APP.modules.main.custom_window_dim_offset.get().height})

      return

    @onDestroy =>
      @_custom_window_dim_tracker.stop()

      return

    return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    _.each @_on_destroy_procedures, (proc) -> proc()

    @destroyed = true

    @logger.debug "Destroyed"

    return
