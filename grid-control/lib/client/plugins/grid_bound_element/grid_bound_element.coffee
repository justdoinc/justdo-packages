default_options =
  container: "body"
  close_on_context_menu_outside: true
  close_on_click_outside: true
  close_on_grid_header_rebuild: true
  update_pos_on_grid_scroll: true
  update_pos_on_dom_scroll: true
  update_pos_on_dom_resize: true

  # Only if element is open - this handler will be called once position update required in response to certain events
  positionUpdateHandler: -> return
  # Will be called upon close that was triggered by initGridBoundElement logic
  closeHandler: -> return

_.extend GridControl.prototype,
  initGridBoundElement: (element_html, options) ->
    # Inits a new html element that is added to the dom under a container defined
    # in options.
    # 
    # Element will be either "closed" or "opened". The element is considered closed
    # unless it has the "open" class.
    #
    # It is safe to close/open the created element by adding/removing the "open" class
    # from logic outside this method.
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

    if options.update_pos_on_grid_scroll
      @_grid.onScroll.subscribe =>
        options.positionUpdateHandler()

    if options.close_on_grid_header_rebuild
      @on "columns-headers-dom-rebuilt", =>
        options.closeHandler()

    if options.close_on_click_outside
      $(document).on 'click', options.closeHandler

      $element.click (e) ->
        # Don't bubble clicks up, to avoid closing the element
        e.stopPropagation()

    if options.close_on_context_menu_outside
      $(document).on 'contextmenu', options.closeHandler

      $element.on 'contextmenu', (e) ->
        # Don't bubble contextmenu, to avoid closing the element
        e.stopPropagation()

    if options.update_pos_on_dom_scroll
      $(window).on 'scroll', options.positionUpdateHandler

    if options.update_pos_on_dom_resize
      $(window).on 'resize', options.positionUpdateHandler

    @_grid.onBeforeDestroy.subscribe =>
      # Release all events bindings to document
      if options.close_on_click_outside
        $(document).off 'click', options.closeHandler

      if options.close_on_context_menu_outside
        $(document).off 'contextmenu', options.closeHandler 

      if options.update_pos_on_dom_scroll
        $(window).off 'scroll', options.positionUpdateHandler

      if options.update_pos_on_dom_resize
        $(window).off 'resize', options.positionUpdateHandler

      $element.remove()

    return $element