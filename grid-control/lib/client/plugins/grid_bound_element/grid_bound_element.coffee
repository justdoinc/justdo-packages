grid_bound_element_default_options = 
  close_on_grid_header_rebuild: true
  update_pos_on_grid_scroll: true
  destroy_on_grid_destroy: true

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

    $element = PACK.helpers.initBoundElement(element_html, options)

    options = _.extend {}, grid_bound_element_default_options, options

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