_ = lodash

GridControlSearch = (grid_control, container) ->
  EventEmitter.call this

  @grid_control = grid_control

  @container = $(container)
  @input = @search_info = @clear_button = @search_prev = @search_next = null # controls
  @current_term = ""
  @paths = null # stores an array with results paths or null if no results or clear
  @next_path = null # stores path for next result, if exists
  @prev_path = null # stores path for prev result, if exists

  @logger = Logger.get("grid-control-search")

  @_init()

  if Tracker.currentComputation?
    Tracker.onInvalidate =>
      @destroy()

  @grid_control.on "destroyed", =>
    @destroy()

  @grid_control._init_dfd.done =>
    @grid_control._grid_data.on "grid-item-changed", =>
      @_search()

    @grid_control._grid_data.on "rebuild", =>
      @_search()

    @grid_control.on "grid-view-change", =>
      @_search()

    @grid_control._grid.onActiveCellChanged.subscribe =>
      @_update_location()

  return @

Util.inherits GridControlSearch, EventEmitter

_.extend GridControlSearch.prototype,
  search_ui_component:
    '<div class="grid-control-search input-group input-group-sm">
      <div class="form-control"><input type="text" class="search-input" placeholder="Search" /></div>
      <span class="input-group-btn">
        <div class="btn clear-button"><i class="fa fa-times"></i></div>
        <div class="btn search-info-container"><span class="label search-info"></span></div>
        <button type="button" class="btn btn-default search-prev disabled"><i class="fa fa-chevron-up"></i></button>
        <button type="button" class="btn btn-default search-next disabled"><i class="fa fa-chevron-down"></i></button>
      </span>
    </div>'

  _init: ->
    @container.html(@search_ui_component)

    @input =
      $('.search-input', @container)

    @clear_button =
      $('.clear-button', @container)

    @search_prev =
      $('.search-prev', @container)

    @search_next =
      $('.search-next', @container)

    @loc_buttons =
      $('.search-next,.search-prev', @container)

    @search_info =
      $('.search-info', @container)

    @search_info_container =
      $('.search-info-container', @container)

    @input.keydown (e) =>
      # down arrow or enter key for next search result
      if e.which == 40 or e.which == 13 # down or enter
        e.preventDefault()
        @next()

      # up arrow for prev search result
      if e.which == 38 # up
        e.preventDefault()
        @prev()

      # esc key to clear
      if e.which == 27 # esc
        e.preventDefault()
        @clear()

    @input.keyup =>
      @search(@input.val())

    # clear button function
    @clear_button.on 'click', =>
      @clear()

    # click prev button for previous result
    @search_prev.on 'click', =>
      @prev()

    # click next button for next result
    @search_next.on 'click', =>
      @next()

  _search: () ->
    # actual search logic
    fields = _.map @grid_control.getView(), (x) -> x.field

    if @current_term != ""
      @paths = @grid_control._grid_data.search(new RegExp(@current_term), fields)

      if @paths.length > 0
        @_setHaveResults(@paths)
      else
        @_unsetHaveResults()

  _setHaveResults: (paths) ->
    @paths = paths
    @container.addClass('results-found')
    @search_info.addClass('label-primary')
    @search_info.removeClass('label-warning')
    @loc_buttons.removeClass('disabled')
    @_setMessage "<span class='location'></span>#{paths.length}"
    @_update_location()

  _unsetHaveResults: () ->
    @paths = null
    @next_path = null
    @prev_path = null
    @container.removeClass('results-found')
    @search_info.removeClass('label-primary')
    @search_info.addClass('label-warning')
    @loc_buttons.addClass('disabled')
    @_setMessage "0"

  _update_location: ->
    if @paths?
      active_path = @grid_control.getActiveCellPath()

      if not active_path?
        # If no active path: set first result as next
        @next_path = @paths[0]
        @prev_path = @paths[@paths.length - 1]
      else
        if (path_index = @paths.indexOf active_path) > -1 # if active_path is part of result set
          @next_path = @paths[(path_index + 1) % @paths.length]
          @prev_path = @paths[(path_index + @paths.length - 1) % @paths.length]
          @_setLocationMessage "#{path_index + 1}/"

          return
        else
          getPathArray = GridData.helpers.getPathArray
          active_path_array = getPathArray "/0#{active_path}" # prepend /0 to have it as common origin if no other common origin
          @next_path = @paths[0]
          @prev_path = @paths[@paths.length - 1]
          for path, i in @paths
            # This loop compares found paths with active path to set the correct
            # next and previous results, which should be the closer to current active path.
            #
            # Note: found paths are sorted by their order in the slick grid tree.
            #
            # We keep setting every path we find that comes before the active path
            # as the previous result (and next path as next result) until we find
            # a path that comes after current active or the end of the result set
            current_path_array = getPathArray "/0#{path}"
            for item_id, j in active_path_array
              if item_id == current_path_array[j]
                common_origin_id = item_id
              else
                active_path_diff_item = item_id
                current_path_diff_item = current_path_array[j]

                break

            if not active_path_diff_item? # active_path is ancestor of current_path, comes after
              # active ancestor, break
              break
            else if not current_path_diff_item? # current_path is ancestor of active_path, comes before
              # current ancestor, set path as previous
              @prev_path = path
              @next_path = @paths[(@paths.length + i + 1) % @paths.length] # XXX BUG
            else
              # share common origin, but one isn't ancestor of the other
              # check the first different item in the paths to find who comes
              # first.
              current_path_diff_item_order = _.findKey(@grid_control._grid_data.tree_structure[common_origin_id], (x) -> x == current_path_diff_item)
              active_path_diff_item_order = _.findKey(@grid_control._grid_data.tree_structure[common_origin_id], (x) -> x == active_path_diff_item)

              if active_path_diff_item_order > current_path_diff_item_order
                # active item comes after current path, set path as previous
                @prev_path = path
                @next_path = @paths[(@paths.length + i + 1) % @paths.length] # XXX BUG
              else
                # active item comes before current path, break
                break

    @_setLocationMessage ""

  _updateMessageContainerPosition: ->
    @search_info_container.position
      my: "right"
      at: "left"
      of: @clear_button

    $(".form-control", @container).css("padding-right", @clear_button.outerWidth() + @search_info_container.outerWidth())

  _setMessage: (message) ->
    @search_info.html(message)

    @_updateMessageContainerPosition()

  _setLocationMessage: (message) ->
    $(".location", @search_info).html(message)

    @_updateMessageContainerPosition()

  clear: ->
    if @current_term != ""
      @input.val('')
      @current_term = ""
      @container.removeClass('input-not-empty')

      @input.focus()

      @_unsetHaveResults()
      @_setMessage("")

  prev: ->
    if @prev_path?
      @grid_control.activatePath(@prev_path)

  next: ->
    if @next_path?
      @grid_control.activatePath(@next_path)

  search: (term) ->
    if term? and term != "" 
      if @current_term != term
        @container.addClass('input-not-empty')

        @current_term = term
        if @input.val() != term
          @input.val term

        @_search()
    else
      @clear()

  destroy: ->
    @container.empty()
    @logger.debug "Destroyed"