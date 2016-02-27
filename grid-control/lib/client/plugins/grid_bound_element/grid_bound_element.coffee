default_options =
  container: "body"
  close_on_context_menu_outside: true
  close_on_click_outside: true
  close_on_grid_header_rebuild: true
  update_pos_on_grid_scroll: true
  update_pos_on_dom_scroll: true
  update_pos_on_dom_resize: true

  positionUpdateHandler: ($connected_element) ->
    # Only if element is open - this handler will be called once position
    # update required in response to certain events
    return

  closedHandler: ->
    # Will be called upon close
    return

  openedHandler: ->
    # Will be called upon open, if already open, will be closed first
    # logic
    return

_.extend GridControl.prototype,
  initGridBoundElement: (element_html, options) ->
    # Inits a new html element that is added to the dom under a container defined
    # in options.
    # 
    # Element will be either "closed" or "opened". The element is considered closed
    # unless it has the "open" class.
    #
    # the method takes care of:
    #   * Removing the element from the DOM on grid_control destroy - and unbinding
    #      all events attached to the DOM
    #   * Closing the element in response to certain events - options.positionUpdateHandler will
    #      be called following such close to allow more actions to be taken
    #   * Only if open - updating the element position in response to events - by calling
    #      options.positionUpdateHandler
    #
    # If special logic required on destroy bind event to grid control's "destroyed" event
    #
    # Returns the created element jQuery object 

    options = _.extend {}, default_options, options

    $element = $(element_html)

    $element.appendTo(options.container)

    #
    # Element methods
    #
    open_class = "open"
    $element.data "isOpen", isOpen = =>
      $element.hasClass(open_class)

    last_type = null
    $connected_element = null
    $element.data "open", open = (type, $type_connected_element) =>
      # type can be any arbitrary string if open will be called for the second
      # time with the same type it will be closed instead of open (toggle behavior)
      #
      # $type_connected_element will be passed as the first arg of positionUpdateHandler()
      # to be used for positioning - should be jquery object.
      # can be null if no such concept for this bound element

      if isOpen() and type == last_type
        close()
        return

      last_type = type
      $connected_element = $type_connected_element

      if isOpen()
        # If open already, close first.
        close()

      $element.addClass(open_class)

      options.openedHandler()

      updatePosition()

    $element.data "close", close = =>
      if not isOpen()
        # If closed, do nothing
        return

      $element.removeClass(open_class)

      options.closedHandler()

    $element.data "toggle", toggle = =>
      if isOpen()
        close()
      else
        open()

    $element.data "updatePosition", updatePosition = =>
      if not isOpen()
        # Do nothing if closed
        return

      options.positionUpdateHandler($connected_element)

    #
    # Events handling
    #
    if options.update_pos_on_grid_scroll
      @_grid.onScroll.subscribe updatePosition

    if options.close_on_grid_header_rebuild
      @on "columns-headers-dom-rebuilt", close

    if options.close_on_click_outside
      $(document).on 'click', close
      # Bootstrap's dropdown button stops click propagation, so it needs special treatment
      $(document).on 'show.bs.dropdown', close  

      $element.click (e) ->
        # Don't bubble clicks up, to avoid closing the element
        e.stopPropagation()

    if options.close_on_context_menu_outside
      $(document).on 'contextmenu', close

      $element.on 'contextmenu', (e) ->
        # Don't bubble contextmenu, to avoid closing the element
        e.stopPropagation()

    if options.update_pos_on_dom_scroll
      $(window).on 'scroll', updatePosition

    if options.update_pos_on_dom_resize
      $(window).on 'resize', updatePosition

    @_grid.onBeforeDestroy.subscribe =>
      # Release all events bindings to document
      if options.close_on_click_outside
        $(document).off 'click', close
        $(document).off 'show.bs.dropdown', close

      if options.close_on_context_menu_outside
        $(document).off 'contextmenu', close 

      if options.update_pos_on_dom_scroll
        $(window).off 'scroll', updatePosition

      if options.update_pos_on_dom_resize
        $(window).off 'resize', updatePosition

      $element.remove()

    return $element