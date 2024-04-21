grid_bound_element_default_options = 
  close_on_grid_header_rebuild: true
  close_on_mouse_up_on_task_owner: true
  update_pos_on_grid_scroll: true
  destroy_on_grid_destroy: true
  avoid_cell_edit_mode_when_pressed_on_grid: true

_.extend GridControl.prototype,
  initGridBoundElement: (element_html, options) ->
    # Creates a BoundElement with custom grid related features
    # Inits a new html element that is added to the dom under a container defined
    # in options.
    # 
    # Element will be either "closed" or "opened". The element is considered closed
    # unless it has the "open" class.
    #
    # In addition to all the BoundElement features this method will also take care of:
    #   * Removing the element from the DOM on grid_control destroy
    #   * Closing the element in response to certain grid events
    #   * Only if open - updating the element position in response to grid events - like BoundElement
    #     options.positionUpdateHandler will be called
    #
    # If special logic required on destroy bind event to grid control's "destroyed" event
    #
    # Returns the created element jQuery object

    options = _.extend {}, grid_bound_element_default_options, options

    $element = null
    if options.avoid_cell_edit_mode_when_pressed_on_grid
      is_mouse_down = 0
      mouseDownDetector = ->
        is_mouse_down = 1

      mouseUpDetector = (e) ->
        if options.close_on_mouse_up_on_task_owner
          if $(e.target).closest(".grid-tree-control-user").length > 0
            close()

        is_mouse_down -= 1

      lockGridWhenGridBoundElementOpened = =>
        is_mouse_down = 0

        $(@container).on 'mousedown', mouseDownDetector
        # mousedown is not propogated up from $element, unlike mouseup
        # so we need to account for it.
        $element.on 'mousedown', mouseDownDetector

        $(@container).on 'mouseup', mouseUpDetector

        @lockEditing()

      unlockGridWhenGridBoundElementClosed = =>
        $(@container).off 'mousedown', mouseDownDetector
        # See comment for lockGridWhenGridBoundElementOpened
        $element.off 'mousedown', mouseDownDetector

        $(@container).off 'mouseup', mouseUpDetector

        if is_mouse_down
          releaseOnMouseUp = =>
            Meteor.defer =>
              @unlockEditing()

            $(@container).off 'mouseup', releaseOnMouseUp

            return

          $(@container).on 'mouseup', releaseOnMouseUp
        else
          @unlockEditing()

        return

      # openedHandler binding
      if (original_openedHandler = options.openedHandler)?
        options.openedHandler = =>
          lockGridWhenGridBoundElementOpened()
          original_openedHandler()
      else
        options.openedHandler = lockGridWhenGridBoundElementOpened

      # closedHandler binding
      if (original_closedHandler = options.closedHandler)?
        options.closedHandler = =>
          unlockGridWhenGridBoundElementClosed()
          original_closedHandler()
      else
        options.closedHandler = unlockGridWhenGridBoundElementClosed

    $element = PACK.helpers.initBoundElement(element_html, options)

    $element.addClass "grid-bound-element"

    #
    # $element events shortcuts
    #

    original_destroy = $element.data "destroy"
    close = $element.data "close"
    updatePosition = $element.data "updatePosition"

    #
    # Augment original destroy
    #
    $element.data "destroy", destroy = _.once =>
      if options.update_pos_on_grid_scroll
        @_grid.onScroll.unsubscribe updatePosition

      original_destroy()

    #
    # Events handling
    #
    if options.update_pos_on_grid_scroll
      @_grid.onScroll.subscribe updatePosition

    if options.close_on_grid_header_rebuild
      @on "columns-headers-dom-rebuilt", close

    #
    # Destroy on grid destroy
    #
    if options.destroy_on_grid_destroy
      @_grid.onBeforeDestroy.subscribe =>
        destroy()

    return $element