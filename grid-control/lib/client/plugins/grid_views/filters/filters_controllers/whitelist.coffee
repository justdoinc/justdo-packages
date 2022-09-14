empty_state_representing_value_for_html = "|NIL|"

# In ie11, when we tried add inputs with argument value of "" ie changed it to "1" (!)
getHtmlValue = (value) -> if value != "" then value else empty_state_representing_value_for_html
getValueFromHtmlValue = (html_value) -> if html_value != empty_state_representing_value_for_html then html_value else ""

getAvailableValuesFromContext = (context) ->
  column_settings = context.column_schema_definition

  if not (filter_values = settings_filter_values = column_settings?.grid_column_filter_settings?.options?.filter_values)?
    # First try to see if the filter values are set in the grid_column_filter_settings options in
    # such case these values will take precedence over the values over the column settings values
    if not (filter_values = column_settings.grid_values)?
      # If we can't even find values under the column_settings values just return an empty object
      return {}

  if _.isFunction(filter_values)
    filter_values = filter_values()

  return filter_values

getAvailableValuesFromContextArray = (context) ->
  filter_values = getAvailableValuesFromContext(context)

  result = _.map filter_values, (filter_value, filter_key) -> {filter_key, filter_value}

  result = _.sortBy result, (item) -> item.filter_value.order or 0

  return result

#
# Filter controller constructor
#
WhiteListFilterControllerConstructor = (context) ->
  GridControl.FilterController.call this

  @once "insterted-to-dom", =>
    @controller_search.focus()

    return

  @grid_control = context.grid_control
  @column_filter_state_ops = context.column_filter_state_ops

  column_settings_values = getAvailableValuesFromContextArray(context)

  @filter_change_listener = => @refresh_state()

  @grid_control.on "filter-change", @filter_change_listener

  @controller = $("""<div></div>""")

  @controller_search = $("""<input type="text" class="form-control form-control-sm" style="margin-bottom: 8px;" placeholder="Filter Options">""")

  @controller_ul_wrapper = $("""<div class="filter-dropdown-list-wrapper">""")

  @controller_ul = $("""<ul class="fa-ul whitelist-alike-filter-dropdown-ul" />""")

  @controller.append(@controller_search)
  @controller.append(@controller_ul_wrapper)
  @controller_ul_wrapper.append(@controller_ul)

  populateOptionsList = =>
    search_text = @controller_search.val().toLowerCase()
    @controller_ul.empty()
    for item in column_settings_values
      {filter_key, filter_value} = item

      if (html = filter_value.html)?
        if filter_value.skip_xss_guard
          # Future ready for the day we'll allow users
          # to define custom values.
          # By adding this I'm forcing development to take
          # xss into account
          label = html
        else
          # Prefer the html label
          label = JustdoHelpers.xssGuard(html, {allow_html_parsing: true, enclosing_char: ''})
      else
        label = filter_value.txt

      if label.toLowerCase().indexOf(search_text) >= 0
        @controller_ul.append("<li value='#{JustdoHelpers.xssGuard(getHtmlValue(filter_key), {allow_html_parsing: true, enclosing_char: "'"})}'><i class='fa-li fa fa-square-o'></i><i class='fa-li fa fa-check-square-o'></i> #{JustdoHelpers.xssGuard(label, {allow_html_parsing: true, enclosing_char: ''})}</li>")

    return

  populateOptionsList()

  $(@controller_search).on "keyup", (e) =>
    populateOptionsList()
    @refresh_state()
    return

  $(@controller_ul).on "click", "li", (e) =>
    filter_state = @column_filter_state_ops.getColumnFilter()
    $el = $(e.target).closest("li")

    html_value = $el.attr("value")
    value = getValueFromHtmlValue(html_value)

    stored_values_to_filter = [value]
    if value is ""
      # We regard null/undefined value as equivalent to empty string.
      stored_values_to_filter.push null

    if $el.hasClass("selected")
      args = [filter_state].concat(stored_values_to_filter)
      filter_state = _.without.apply _, args
    else
      if filter_state?
        filter_state = _.union filter_state, stored_values_to_filter
      else
        filter_state = stored_values_to_filter

    if _.isEmpty(filter_state)
      @column_filter_state_ops.clearColumnFilter()
    else
      @column_filter_state_ops.setColumnFilter(filter_state)

  @refresh_state()

  return @

Util.inherits WhiteListFilterControllerConstructor, GridControl.FilterController

_.extend WhiteListFilterControllerConstructor.prototype,
  allow_select_all: true

  getSelectAllFilterState: ->
    return

  refresh_state: ->
    filter_state = @column_filter_state_ops.getColumnFilter()

    # Remove the selected class from all items
    $("li", @controller).removeClass("selected")

    # If no filter set, return
    if not filter_state?
      return

    # Add the selected task, only to the selected items
    for value in filter_state
      $("[value='#{getHtmlValue(value)}']", @controller).addClass("selected")

    return

  destroy: ->
    @grid_control.removeListener "filter-change", @filter_change_listener

#
# stateToQuery
#
columnFilterStateToQuery = (column_filter_state, context) ->
  column_state_definitions = getAvailableValuesFromContext(context)

  simple_states = []
  custom_queries = []

  for state in column_filter_state
    if not (state_def = column_state_definitions[state])?
      simple_states.push state

      continue

    if not (customFilterQuery = state_def.customFilterQuery)?
      simple_states.push state

      continue

    custom_queries.push customFilterQuery(state, column_state_definitions, context)

  query = {}

  if not _.isEmpty(simple_states)
    query[context.column_id] = {$in: simple_states}

  if not _.isEmpty(custom_queries)
    if not _.isEmpty(query)
      # If we got a query already, add it to the custom_queries to make it one of the items
      # of the resulting $or statement
      custom_queries.push query

    query = {$or: custom_queries}

  return query

getSelectAllFilterState = (context) ->
  return _.map(getAvailableValuesFromContextArray(context), (option) -> option.filter_key)

GridControl.installFilterType "whitelist",
  controller_constructor: WhiteListFilterControllerConstructor
  column_filter_state_to_query: columnFilterStateToQuery
  getSelectAllFilterState: getSelectAllFilterState