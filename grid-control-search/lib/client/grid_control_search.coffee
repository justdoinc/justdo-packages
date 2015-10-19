_ = lodash

GridControlSearch = (grid_control) ->
  EventEmitter.call this

  @grid_control = grid_control
  @grid_container = @grid_control.container

  @container = null # will point to the grid_control_search_container
  @input = @search_info = @clear_button = @search_close = @search_prev = @search_next = null # controls
  @current_term = ""
  @paths = null # stores an array with results paths or null if no results or clear
  @next_path = null # stores path for next result, if exists
  @prev_path = null # stores path for prev result, if exists

  Meteor.defer =>
    @_init()

  if Tracker.currentComputation?
    Tracker.onInvalidate =>
      @destroy()

  @grid_control._grid_data.on "grid-item-changed", =>
    @_search()

  @grid_control._grid_data.on "rebuild", =>
    @_search()

  @grid_control.on "grid-view-change", =>
    @_search()

  @grid_control._grid.onActiveCellChanged.subscribe () =>
    @_update_location()

  return @

Util.inherits GridControlSearch, EventEmitter

_.extend GridControlSearch.prototype,
  search_ui_component:
    '<div class="search-box">
      <div class="search-form">
        <input class="search-input" type="text" placeholder="Search" />
        <div class="clear-button"></div>
      </div>
      <div class="search-next"></div>
      <div class="search-prev"></div>
      <div class="search-close"></div>
      <div class="search-info"></div>
    </div>'

  _init: ->
    $('.slick-header', @grid_container).after(@search_ui_component)

    @container = $(".search-box", @grid_container)

    @input =
      $('.search-input', @container)

    @clear_button =
      $('.clear-button', @container)

    @search_close =
      $('.search-close', @container)

    @search_prev =
      $('.search-prev', @container)

    @search_next =
      $('.search-next', @container)

    @search_info =
      $('.search-info', @container)

    @_init_events()

    @on "change", (term) ->
      @search(term)

  _init_events: ->
    self = @

    #set ctrl to be false (ctrl key not pressed)
    ctrl = false
    self.grid_container.keydown (e) ->
      # if ctrl key is pressed, make ctrl true
      if e.which == 17 or e.metaKey # ctrl or cmd key
        ctrl = true

      # show search box if ctrl + f is pressed
      if e.which == 70 and ctrl == true # ctrl + f key
        e.preventDefault()
        self.show()
        ctrl = false

    # reset ctrl to false when ctrl key up
    self.grid_container.keyup (e) ->
      if e.which == 17 or e.metaKey # ctrl or cmd key
        ctrl = false

    # close search box when esc key is pressed
    self.grid_container.keydown (e) ->
      if e.which == 27 # esc
        self.clear()
        self.hide()

    # up arrow for prev search result
    self.input.keydown (e) ->
      if e.which == 38 # up
        e.preventDefault()
        self.prev()

    # down arrow or enter key for next search result
    self.input.keydown (e) ->
      if e.which == 40 or e.which == 13 # down or enter
        self.next()

    # add reset input button when input is not blank
    self.input.keyup ->
      self.search(self.input.val())

    self.input.focus ->
      # Take care of edge case resulted when opening the search while editing item
      Meteor.defer =>
        if self.input.get(0) != document.activeElement
          self.input.focus()

    # clear button function
    self.clear_button.on 'click', ->
      self.clear()

    # click x to close search box
    self.search_close.on 'click', ->
      self.clear()
      self.hide()

    # click prev button for previous result
    self.search_prev.on 'click', ->
      self.prev()

    # click next button for next result
    self.search_next.on 'click', ->
      self.next()

  destroy: ->
    @container.remove()

  _search: () ->
    # actual search logic
    fields = _.map @grid_control.getView(), (x) -> x.field

    if @current_term != ""
      @paths = @grid_control._grid_data.search(new RegExp(@current_term), fields)

      if @paths.length > 0
        @_setHaveResults(@paths)
      else
        @_unsetHaveResults()


  search: (term) ->
    @show()

    if term? and term != "" 
      if @current_term != term
        @container.addClass('input-not-empty')

        @current_term = term
        if @input.val() != term
          @input.val term

        @_search()
    else
      @clear()

  _setHaveResults: (paths) ->
    @paths = paths
    @container.addClass('results-found')
    @_setMessage "#{paths.length} found<span class='location'></span>"
    @_update_location()

  _unsetHaveResults: () ->
    @paths = null
    @next_path = null
    @prev_path = null
    @container.removeClass('results-found')
    @_setMessage "No results found"

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
          @_setLocationMessage ", showing #{path_index + 1}/#{@paths.length}"

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

  _setMessage: (message) ->
    @search_info.html(message)

  _setLocationMessage: (message) ->
    $(".location", @search_info).html(message)

  clear: ->
    if @current_term != ""
      @input.val('')
      @current_term = ""
      @container.removeClass('input-not-empty')

      @input.focus()

      @_unsetHaveResults()
      @_setMessage("")

  show: ->
    @container.addClass('show')
    @input.focus()
    Meteor.defer =>
      @input.focus()

  hide: ->
    @container.removeClass('show')

    active_cell = @grid_control._grid.getActiveCell()
    if (cell = $(".slick-cell.active")).length > 0
      cell.attr('tabindex',-1).focus()
    else
      @grid_container.attr('tabindex',-1).focus() # if no active cell focus on grid

  prev: ->
    if @prev_path?
      @grid_control.activatePath(@prev_path)

  next: ->
    if @next_path?
      @grid_control.activatePath(@next_path)

