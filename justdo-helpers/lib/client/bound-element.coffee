bound_element_default_options =
  container: "body"
  # If close_button_html isn't null it will be inserted inside a wrapper with
  # the .close class, the GridBoundElement will take care of close logic.
  # The wrapper will be appended to the element_html
  close_button_html: '<i class="fa fa-close fa-fw"></i>'
  close_on_context_menu_outside: true
  close_on_esc: true
  close_on_click_outside: true
  close_on_mousedown_outside: true
  close_on_bootstrap_dropdown_show: true
  close_on_bound_elements_show: true
  close_bootstrap_dropdowns_on_open: true
  keep_open_while_bootbox_active: true
  update_pos_on_dom_scroll: true
  update_pos_on_dom_resize: true

  positionUpdateHandler: ($connected_element) ->
    # Only if element is open - this handler will be called once position
    # update required in response to certain events
    return

  closedHandler: ->
    # Will be called upon close
    return

  openedHandler: (template_data) ->
    # Will be called upon open, if already open, will be closed first
    # logic
    return

_.extend JustdoHelpers,
  initBoundElement: (element_html, options) ->
    # Inits a new html element that is added to the dom under a container defined
    # in options.
    # 
    # Element will be either "closed" or "opened". The element is considered closed
    # unless it has the "open" class.
    #
    # the method takes care of:
    #   * Closing the element in response to certain events - options.closedHandler will
    #      be called following such close to allow more actions to be taken
    #   * Only if open - updating the element position in response to events - by calling
    #      options.positionUpdateHandler
    #
    # Returns the created element jQuery object 

    options = _.extend {}, bound_element_default_options, options

    $element = $(element_html)

    $element.addClass "bound-element"

    $element.appendTo(options.container)

    #
    # Element methods
    #
    open_class = "open"
    $element.data "isOpen", isOpen = =>
      $element.hasClass(open_class)

    last_type = null
    $connected_element = null
    $element.data "open", open = (type, $type_connected_element, template_data) =>
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

      $element.trigger($.Event('show.boundelement'))

      if options.close_bootstrap_dropdowns_on_open
        $('.dropdown.open:not(.bound-element,.grid-bound-element)').removeClass('open')

      $element.addClass(open_class)

      options.openedHandler(template_data)

      updatePosition()

    _allow_dropdown_close = true
    $element.data "allowDropdownClose", allowDropdownClose = =>
      _allow_dropdown_close = true

      return

    $element.data "preventDropdownClose", preventDropdownClose = =>
      _allow_dropdown_close = false

      return

    # We track last_mousedown_in_container to avoid situations where a click that begins
    # inside the container, and ends outside of it, cause the element to close.
    last_mousedown_in_container = false
    $element.data "close", close = (e) =>
      # important, it isn't guarentee that e will be defined!

      if e? and e.type == "click"
        # If we are responding to a click. Close, only if the click didn't begin inside
        # the bound element.
        if last_mousedown_in_container
          return

      if not _allow_dropdown_close
        return

      if options.keep_open_while_bootbox_active and isBootboxActive()
        # Don't close if bootbox active
        return

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

      if not $connected_element.is(":visible")
        # If the connected element isn't visible, attempts to reposition the bound element
        # will cause it to be removed from the screen
        return

      options.positionUpdateHandler($connected_element)

    documentMousedownHandler = (e) ->
      last_mousedown_in_container = false

      return close(e)

    $element.data "destroy", destroy = _.once =>
      # Release all events bindings to document
      if options.close_on_esc
        $(document).off 'keydown', closeOnEsc

      if options.close_on_click_outside
        $(document).off 'click', close

      if options.close_on_bootstrap_dropdown_show
        $(document).off 'show.bs.dropdown', close

      if options.close_on_bound_elements_show
        $(document).off 'show.boundelement', close

      if options.close_on_mousedown_outside
        $(document).off 'mousedown', documentMousedownHandler

      if options.close_on_context_menu_outside
        $(document).off 'contextmenu', close 

      if options.update_pos_on_dom_scroll
        $(window).off 'scroll', updatePosition

      if options.update_pos_on_dom_resize
        $(window).off 'resize', updatePosition

      $element.remove()

    #
    # Close button
    #
    if options.close_button_html?
      default_close = if options.close_button_html == bound_element_default_options.close_button_html then "default-close" else ""
      $close_button = $("<div class=\"close-btn #{default_close}\">#{options.close_button_html}</div>")
      $close_button.appendTo $element

      $close_button.click (e) ->
        e.stopPropagation()

        close() # We don't pass the e here intentionally, it is a click event, and we have a special treatment for click events that will cause the close() to not closing (see close() implementation)

        return

    #
    # Helpers
    #
    isBootboxActive = -> $(".bootbox").length > 0

    #
    # Events handling
    #
    if options.close_on_bootstrap_dropdown_show
      $(document).on 'show.bs.dropdown', close  

    if options.close_on_bound_elements_show
      $(document).on 'show.boundelement', close

    closeOnEsc = (e) ->
      e = e || window.event
      if e.keyCode == 27
        close(e)

    if options.close_on_esc
      $(document).on 'keydown', closeOnEsc

    if options.close_on_click_outside
      $(document).on 'click', close

      $element.click (e) ->
        # Don't bubble clicks up, to avoid closing the element
        e.stopPropagation()

    if options.close_on_mousedown_outside
      $(document).on 'mousedown', documentMousedownHandler

      $element.mousedown (e) ->
        last_mousedown_in_container = true

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

    return $element
