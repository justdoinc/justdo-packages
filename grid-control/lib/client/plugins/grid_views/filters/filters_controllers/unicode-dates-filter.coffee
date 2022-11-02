default_filter_options =
  filter_options: [
    # # Format:
    #
    # {
    #   type: ""
    #
    #   type specific options
    # }
    #
    # ## Supported Types and their options
    #
    # ### "relative-range"
    #
    # Range relative to today. If you select this type for an option, you must also
    # specify the label and relative_range properties:
    #
    # {
    #   type: "relative-range",
    #   id: "overdue",
    #   label: "Overdue",
    #   relative_range: [1, null]
    # }
    #
    # id should be dash separated all-lower case name. Label can change without loosing
    # user settings in the process, as long as id remains the same.
    #
    # Relative range is an array with 2 items the first number is the begin day (inclusive)
    # for the range relative to today (in the example above - tomorrow).
    # The second date is the end date (inclusive).
    #
    # null means unlimited (in the example above: all date that come after tomorrow).
    #
    # ### "custom-range"
    #
    # We will let the user select begin date and end date from calendar UI.
    #
    # Only one "custom-range" filer option is supported per column, hence there's
    # no need to set id property.

    # The following defaults are provided mostly to serve us example
    {
      type: "relative-range",
      id: "today",
      label: "Today",
      relative_range: [0, 0]
    }
    {
      type: "relative-range",
      id: "overdue",
      label: "Overdue",
      relative_range: [1, null]
    }
    {
      type: "relative-range",
      id: "future",
      label: "Future",
      relative_range: [null, -1]
    }
    {
      type: "custom-range"
      label: "Between"
    }
  ]

#
# Filter controller constructor
#
UnicodeDatesFilterControllerConstructor = (context) ->
  GridControl.FilterController.call this

  @grid_control = context.grid_control
  @column_settings = context.column_settings
  @column_filter_state_ops = context.column_filter_state_ops

  filter_settings_options = @column_settings?.filter_settings?.options

  @filter_settings_options = _.extend {}, default_filter_options, filter_settings_options

  @filter_change_listener = => @refresh_state()

  @grid_control.on "filter-change", @filter_change_listener

  @controller = $("""<div class="dates-filter-controller" />""")

  filter_options_html = ""
  for filter_option in @filter_settings_options.filter_options
    if filter_option.type == "relative-range"
      if not filter_option.id?
        console.warn "relative-range filter option has no id, skipping"

        continue

      option_item = """
        <li value="relative-range-#{filter_option.id}">
          <i class="fa-li fa fa-square-o"></i><i class="fa-li fa fa-check-square-o"></i>
          #{filter_option.label}
        </li>
      """

      filter_options_html += option_item
    if filter_option.type == "custom-range"
      option_item = """
        <li value="custom-range">
          <i class="fa-li fa fa-square-o"></i><i class="fa-li fa fa-check-square-o"></i>
          <div class="custom-range-wrapper">
            <div class="custom-range-input-wrapper empty">
              <div class="custom-range-label-wrapper">
                <div class="custom-range-label custom-range-label-start">From</div>
                <input id="custom-range-start" class="custom-range-input" type="text" readonly="readonly">
              </div>
              <svg class="jd-icon clear-date"><use xlink:href="/layout/icons-feather-sprite.svg#x"></use></svg>
            </div>
            <span>-</span>
            <div class="custom-range-input-wrapper empty">
              <div class="custom-range-label-wrapper">
                <div class="custom-range-label custom-range-label-end">To</div>
                <input id="custom-range-end" class="custom-range-input" type="text" readonly="readonly">
              </div>
              <svg class="jd-icon clear-date"><use xlink:href="/layout/icons-feather-sprite.svg#x"></use></svg>
            </div>
          </div>
        </li>
      """
      filter_options_html += option_item

  # note, the reason why we seperate the ul for the dropdown-header is that
  # the vertical scroll of the members ul, when there are many members, go
  # over the x button that close the filter controller.
  # (we might avoid this title at all, if we didn't have this issue)
  @controller.append("""
    <ul class="fa-ul whitelist-alike-filter-dropdown-ul">
      #{filter_options_html}
    </ul>
  """)

  $(@controller).on "click", "li", (e) =>
    $el = $(e.target).closest("li")
    value = $el.attr("value")

    # Shallow copy filter_state if is object
    filter_state = @column_filter_state_ops.getColumnFilter()
    if filter_state?
      filter_state = _.extend {}, filter_state
    else
      filter_state = {}

    if (result = /^relative-range-(.*)/.exec(value))?
      relative_range_id = result[1]

      # Shallow copy the relative_ranges_state array, if it exists
      relative_ranges_state = filter_state.relative_ranges
      if _.isArray(relative_ranges_state)
        relative_ranges_state = relative_ranges_state.slice()
      else
        relative_ranges_state = []

      if $el.hasClass("selected")
        relative_ranges_state = _.without relative_ranges_state, relative_range_id
      else
        relative_ranges_state = _.union relative_ranges_state, [relative_range_id]

      if _.isEmpty(relative_ranges_state)
        delete filter_state.relative_ranges
      else
        filter_state.relative_ranges = relative_ranges_state

    if _.isEmpty(filter_state)
      @column_filter_state_ops.clearColumnFilter()
    else
      @column_filter_state_ops.setColumnFilter(filter_state)

    return

  $(@controller).on "click", "li[value=custom-range] .fa-li", (e) =>
    @setCustomRange("click")

    return

  $(@controller).on "change", ".custom-range-input", (e) =>
    @setCustomRange("change")

    return

  # Custom range Datepicker
  @controller.find(".custom-range-input").datepicker
    changeYear: true
    changeMonth: true
    beforeShow: (el, obj) ->
      obj.dpDiv.on "mousedown contextmenu", (e) ->
        e.stopImmediatePropagation()

        return

  $(".column-filter-dropdown-container").on "mousedown", (e) ->
    $input = $(".custom-range-input")
    if $input.datepicker("widget").is(":visible")
      $input.datepicker("hide")
      $input.blur()

    return

  @controller.on "click", ".clear-date", (e) ->
    $input = $(e.currentTarget).parent(".custom-range-input-wrapper").find(".custom-range-input")
    $input.val("").trigger "change"
    return

  @refresh_state()

  return @

Util.inherits UnicodeDatesFilterControllerConstructor, GridControl.FilterController

_.extend UnicodeDatesFilterControllerConstructor.prototype,
  refresh_state: ->
    filter_state = @column_filter_state_ops.getColumnFilter()

    # Remove the selected class from all items
    $("li", @controller).removeClass("selected")

    # If no filter set, return
    if not filter_state?
      return

    # Add the selected task, only to the selected items
    if (relative_ranges = filter_state.relative_ranges)?
      for relative_range in relative_ranges
        $("[value=relative-range-#{relative_range}]", @controller).addClass("selected")



    if filter_state.custom_range?
      $("[value=custom-range]", @controller).addClass("selected")
      $("#custom-range-start", @controller).val(filter_state.custom_range.start)
      $("#custom-range-end", @controller).val(filter_state.custom_range.end)

      label_start = "From"
      label_end = "To"

      date_format = JustdoHelpers.getUserPreferredDateFormat()

      if filter_state.custom_range.start != ""
        label_start = moment(filter_state.custom_range.start).format(date_format)

      if filter_state.custom_range.end != ""
        label_end = moment(filter_state.custom_range.end).format(date_format)

      @controller.find(".custom-range-label-start").text label_start
      @controller.find(".custom-range-label-end").text label_end

      $start_input_wrapper = @controller.find("#custom-range-start").parents(".custom-range-input-wrapper")
      $end_input_wrapper = @controller.find("#custom-range-end").parents(".custom-range-input-wrapper")

      if moment(label_start, date_format, true).isValid()
        $start_input_wrapper.removeClass "empty"
      else
        $start_input_wrapper.addClass "empty"

      if moment(label_end, date_format, true).isValid()
        $end_input_wrapper.removeClass "empty"
      else
        $end_input_wrapper.addClass "empty"

    return

  destroy: ->
    @grid_control.removeListener "filter-change", @filter_change_listener

  setCustomRange: (event_type) ->
    # Shallow copy filter_state if is object
    filter_state = @column_filter_state_ops.getColumnFilter()
    if filter_state?
      filter_state = _.extend {}, filter_state
    else
      filter_state = {}

    custom_range_start = @controller.find("#custom-range-start").val()
    custom_range_end = @controller.find("#custom-range-end").val()
    filter_state.custom_range = {
      start: custom_range_start
      end: custom_range_end
    }

    if event_type == "click"
      $select_el = $("li[value=custom-range]")

      if $select_el.hasClass("selected")
        delete filter_state.custom_range

    @column_filter_state_ops.setColumnFilter(filter_state)

    return

#
# stateToQuery
#
columnFilterStateToQuery = (column_filter_state, context) ->
  if not context.grid_control.unicode_date_filters_query_updater?
    installUnicodeDateFiltersQueryUpdater(context.grid_control)

  ranges_queries = []

  if not (filter_settings_options = context.column_schema_definition?.grid_column_filter_settings?.options)?
    console.error "Couldn't find filter_settings_options"

    return {}

  # Shallow copy
  column_filter_state = _.extend {}, column_filter_state

  if (original_relative_ranges = column_filter_state.relative_ranges)?
    found_relative_ranges = original_relative_ranges.slice() # copy

    all_filter_option_id_found = true
    for relative_range_id in original_relative_ranges
      filter_option_id_found = false
      for filter_option in filter_settings_options.filter_options
        if filter_option.type == "relative-range" and filter_option.id == relative_range_id
          filter_option_id_found = true

          if not (relative_range = filter_option.relative_range)?
            console.warn "relative-range #{filter_option.id} has no relative_range prop - skipping"

          [gte, lte] = relative_range

          range_query = {}

          if gte?
            range_query.$gte = JustdoHelpers.getRelativeUnicodeDate(gte)

          if lte?
            range_query.$lte = JustdoHelpers.getRelativeUnicodeDate(lte)

          if not _.isEmpty(range_query)
            ranges_queries.push range_query

          break

      if not filter_option_id_found
        all_filter_option_id_found = false
        found_relative_ranges = _.without found_relative_ranges, relative_range_id

    if not all_filter_option_id_found
      if found_relative_ranges.length > 0
        column_filter_state.relative_ranges = found_relative_ranges
      else
        delete column_filter_state.relative_ranges

      # Update the column filter state, remove obsolete states
      if _.isEmpty(column_filter_state)
        context.column_filter_state_ops.clearColumnFilter()
      else
        context.column_filter_state_ops.setColumnFilter(column_filter_state)

  if (custom_range = column_filter_state.custom_range)?
    {start, end} = custom_range
    start = moment(start)
    end = moment(end)
    range_query = {}
    if start.isValid()
      range_query.$gte = start.format("YYYY-MM-DD")
    if end.isValid()
      range_query.$lte = end.format("YYYY-MM-DD")
    if not _.isEmpty(range_query)
      ranges_queries.push(range_query)

  if _.isEmpty ranges_queries
    return {}

  query = {
    $or: []
  }

  for range_query in ranges_queries
    sub_query = {}
    sub_query["#{context.column_id}"] = range_query

    query.$or.push sub_query

  return query

getSelectAllFilterState = (context) ->
  result = {relative_ranges: []} # At the moment, only relative-range filter options are supported.

  filter_options = context.column_schema_definition.grid_column_filter_settings.options.filter_options
  for filter_option in filter_options

    if filter_option.type == "relative-range"
      result.relative_ranges.push filter_option.id

    if filter_option.type == "custom-range"
      $el = context.grid_control.$filter_dropdown
      custom_range_start = ""
      custom_range_end = ""
      result.custom_range = {
        start: custom_range_start
        end: custom_range_end
      }

  return result

GridControl.installFilterType "unicode-dates-filter",
  controller_constructor: UnicodeDatesFilterControllerConstructor
  column_filter_state_to_query: columnFilterStateToQuery
  getSelectAllFilterState: getSelectAllFilterState

installUnicodeDateFiltersQueryUpdater = (grid_control) ->
  # Note! we install only one updater per grid control no matter
  # how many columns are using the unicode-dates-filter.
  #
  # We install the updater the first time a unicode-dates-filter is
  # set on any column. We stop the updater upon the destruction of
  # the grid control.

  if grid_control.unicode_date_filters_query_updater?
    logger.warn("unicodeDateFiltersQueryUpdater already installed")

  previous_value = null
  grid_control.unicode_date_filters_query_updater = Tracker.autorun ->
    current_value = JustdoHelpers.getCurrentUnicodeDateReactive()

    # We check if != null since in the first time we don't want to
    # trigger redundant update
    if previous_value != null and current_value != previous_value
      # Updated, recalculate filters state
      grid_control._updateFilterState(true) # true means forced update
                                            # Read more on: grid-control/lib/client/plugins/grid_views/filters/filters.coffee
                                            # under _updateFilterState implementation

    previous_value = current_value

  grid_control.once "destroyed", ->
    grid_control.unicode_date_filters_query_updater.stop()

  return

GridControl.UnicodeDatesFilterControllerConstructor = UnicodeDatesFilterControllerConstructor
GridControl.UnicodeDatesFilterGetSelectAllFilterState = getSelectAllFilterState
GridControl.UnicodeDatesFilterColumnFilterStateToQuery = columnFilterStateToQuery
