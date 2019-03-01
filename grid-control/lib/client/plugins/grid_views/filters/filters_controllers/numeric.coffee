default_grid_ranges = [
    # # Format:
    #
    # {
    #   id: "high",
    #   label: "Overdue",
    #   range: [90, null]
    # }
    #
    # id should be dash separated all-lower case name. Label can change without losing
    # user settings in the process, as long as id remains the same.
    #
    # range is an array with 2 items the first number is the begin number (inclusive)
    # The second is the end number (inclusive).
    #
    # null means unlimited (in the example above: all numbers equal or larger to 90).

    # The following defaults are provided mostly to serve us example
    {
      id: "less-than-50",
      label: "Less than 50",
      range: [null, 49]
    },
    {
      id: "equal-50",
      label: "50",
      range: [50, 50]
    },
    {
      id: "more-than-50",
      label: "More than 50",
      range: [50, null]
    }
  ]

#
# Filter controller constructor
#
NumericFilterControllerConstructor = (context) ->
  @grid_control = context.grid_control
  @column_settings = context.column_settings
  @column_filter_state_ops = context.column_filter_state_ops

  @grid_ranges = @column_settings?.grid_ranges or default_grid_ranges.slice()

  @filter_change_listener = => @refresh_state()

  @grid_control.on "filter-change", @filter_change_listener

  @controller = $("""<div class="numeric-filter-controller" />""")

  filter_options_html = ""
  for range in @grid_ranges
    if not range.id?
      console.warn "range filter option has no id, skipping"
      
      continue
    
    option_item = """
      <li value='range-#{range.id}'>
        <i class='fa-li fa fa-square-o'></i><i class='fa-li fa fa-check-square-o'></i>
        #{JustdoHelpers.xssGuard(range.label, {allow_html_parsing: true, enclosing_char: ''})}
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

    if (result = /^range-(.*)/.exec(value))?
      range_id = result[1]

      # Shallow copy the ranges_state array, if it exists
      ranges_state = filter_state.ranges
      if _.isArray(ranges_state)
        ranges_state = ranges_state.slice()
      else
        ranges_state = []

      if $el.hasClass("selected")
        ranges_state = _.without ranges_state, range_id
      else
        ranges_state = _.union ranges_state, [range_id]

      if _.isEmpty(ranges_state)
        delete filter_state.ranges
      else
        filter_state.ranges = ranges_state

    if _.isEmpty(filter_state)
      @column_filter_state_ops.clearColumnFilter()
    else
      @column_filter_state_ops.setColumnFilter(filter_state)

    return

  @refresh_state()

  return @

_.extend NumericFilterControllerConstructor.prototype,
  refresh_state: ->
    filter_state = @column_filter_state_ops.getColumnFilter()

    # Remove the selected class from all items
    $("li", @controller).removeClass("selected")

    # If no filter set, return
    if not filter_state?
      return

    # Add the selected task, only to the selected items
    if (ranges = filter_state.ranges)?
      for range in ranges
        $("[value=range-#{range}]", @controller).addClass("selected")

    return

  destroy: ->
    @grid_control.removeListener "filter-change", @filter_change_listener

#
# stateToQuery
#
columnFilterStateToQuery = (column_filter_state, context) ->
  ranges_queries = []

  if not (grid_ranges = context.column_schema_definition?.grid_ranges)?
    console.error "Couldn't find grid_ranges"

    return {}

  # Shallow copy
  column_filter_state = _.extend {}, column_filter_state

  if (original_ranges = column_filter_state.ranges)?
    found_ranges = original_ranges.slice() # copy

    all_range_ids_found = true
    for range_id in original_ranges
      range_id_found = false
      for range_def in grid_ranges
        if range_def.id == range_id
          range_id_found = true

          if not (range = range_def.range)?
            console.warn "range #{range_def.id} has no range prop - skipping"

          [gte, lte] = range

          range_query = {}

          if gte?
            range_query.$gte = gte

          if lte?
            range_query.$lte = lte

          if not _.isEmpty(range_query)
            ranges_queries.push range_query

          break

      if not range_id_found
        all_range_ids_found = false
        found_ranges = _.without found_ranges, range_id

    if not all_range_ids_found
      if found_ranges.length > 0
        column_filter_state.ranges = found_ranges
      else
        delete column_filter_state.ranges

      # Update the column filter state, remove obsolete states
      if _.isEmpty(column_filter_state)
        context.column_filter_state_ops.clearColumnFilter()
      else
        context.column_filter_state_ops.setColumnFilter(column_filter_state)

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

GridControl.installFilterType "numeric-filter",
  controller_constructor: NumericFilterControllerConstructor
  column_filter_state_to_query: columnFilterStateToQuery
