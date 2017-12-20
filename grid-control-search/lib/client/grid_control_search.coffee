_ = lodash

GridControlSearch = (container) ->
  EventEmitter.call this

  @destroyed = false
  @container = $(container)

  @grid_control = null

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
      # enter/shift-enter arrow for next/prev search result
      if e.which == 13
        if not e.shiftKey
          @next()
        else
          @prev()
        
      # down arrow for next search result
      if e.which == 40 # down
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

  unsetGridControl: ->
    if not @isGridControlDefined()
      @logger.debug "@unsetGridControl(), no grid control to unset"

      return

    # Unset active row tracker
    @active_row_tracker?.stop()
    @active_row_tracker = null

    # Unset binded events
    @grid_control.unloadEventsArray(@active_events)
    @active_events = null

    @grid_control = null

    @logger.debug "Grid control unset completed"

  setGridControl: (grid_control) ->
    if @isGridControlDefined()
      # If grid control defined already, run uset procedures

      @unsetGridControl()

    @grid_control = grid_control

    @active_row_tracker = Tracker.nonreactive =>
      # Purpose of the nonreactive is for case the call to
      # setGridControl itself was enclosed with a nonreactive
      # call, in such a case the following autorun won't work
      # properly.
      # (with the nonreactive we introduce another clean
      # isolated reactivity context for the following
      # Tracker.autorun).
      return Tracker.autorun =>
        @grid_control.getCurrentPath() # Upon change to current path
        @_update_location()

    @active_events = [
      ["on", "destroyed", (=> @unsetGridControl())]
      ["on", "tree_change", (=> @_search())]
      ["on", "grid-tree-filter-updated", (=> @_search())]
      ["on", "grid-view-change", (=> @_search())]
    ]
    @grid_control.loadEventsArray(@active_events)

    @_search() # To refresh results for new grid control

    @logger.debug "Grid control set completed"

  isGridControlDefined: ->
    return @grid_control?

  _search: ->
    # actual search logic

    if not @isGridControlDefined()
      @logger.debug "Grid control is not defined, @_search() cancelled"

      return

    view_fields = _.map @grid_control.getView(), (x) -> x.field
    forced_fields = _.map @grid_control.schema, (def, field) ->
      if def.grid_search_when_out_of_view == true
        return field

      return false
    forced_fields = _.filter forced_fields, (x) -> x != false
    fields = _.union forced_fields, view_fields

    # In case we just want to look for specific task id
    if (res = /^id:([0-9]{1,10})\s*$/i.exec(@current_term))?
      fields = ["seqId"]
      @current_term = "^#{res[1]}$"

    if @current_term != ""
      @logger.debug "Refresh search results"

      search_regexp = new RegExp(@current_term, "i")
      search_options =
        fields: fields
        exclude_filtered_paths: true
        exclude_typed_items: true
      @paths = @grid_control._grid_data.search search_regexp, search_options

      if @paths.length > 0
        @_setHaveResults(@paths)
      else
        @_unsetHaveResults()

  highlightMatchedPaths: ->
    @clearMatchedPaths()

    for path in @paths
      if (item_index = @grid_control._grid_data.getPathGridTreeIndex(path))?
        $(".slick-row:nth-child(#{item_index + 1})", @grid_control.container).addClass("search-result")

    return

  clearMatchedPaths: ->
    $(".search-result", @grid_control.container).removeClass("search-result")

    return

  _setHaveResults: (paths) ->
    @paths = paths
    @container.addClass('results-found')
    @search_info.addClass('label-primary')
    @search_info.removeClass('label-warning')
    @loc_buttons.removeClass('disabled')
    @_setMessage "<span class='location'></span><span class='results-count'>#{paths.length}</span>"
    @_update_location()

    @highlightMatchedPaths()

    return

  _unsetHaveResults: () ->
    @paths = null
    @next_path = null
    @prev_path = null
    @container.removeClass('results-found')
    @search_info.removeClass('label-primary')
    @search_info.addClass('label-warning')
    @loc_buttons.addClass('disabled')
    @_setMessage "0"

    @clearMatchedPaths()

    return

  _update_location: ->
    if not @isGridControlDefined()
      @logger.debug "Grid control is not defined, @_update_location() cancelled"

      return

    if @paths?
      active_path = @grid_control.getCurrentPath()

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
    if not @isGridControlDefined()
      @logger.debug "Grid control is not defined, @prev() cancelled"

      return

    if @prev_path?
      @grid_control.activatePath(@prev_path)

  next: ->
    if not @isGridControlDefined()
      @logger.debug "Grid control is not defined, @next() cancelled"

      return

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
    if @destroyed
      # Nothing to do
      return

    @destroyed = true

    @unsetGridControl()

    @container.empty()

    @logger.debug "Destroyed"
