empty_state_representing_value_for_html = "|NIL|"

# In ie11, when we tried add inputs with argument value of "" ie changed it to "1" (!)
getHtmlValue = (value) -> if value != "" then value else empty_state_representing_value_for_html
getValueFromHtmlValue = (html_value) -> if html_value != empty_state_representing_value_for_html then html_value else ""

#
# Filter controller constructor
#
WhiteListFilterControllerConstructor = (context) ->
  GridControl.FilterController.call this

  @once "insterted-to-dom", =>
    Meteor.defer =>
      # No clue why, but focusing on the same tick as the init tick messes up
      # with the positioning of the dropdown. (As of 2021-07-21 in Chrome). Daniel C.

      @controller_search.focus()

      return

    return

  @grid_control = context.grid_control
  @column_settings = context.column_settings
  @column_filter_state_ops = context.column_filter_state_ops

  @filter_change_listener = => @refresh_state()

  @grid_control.on "filter-change", @filter_change_listener
  
  @controller = $("""<div style="max-height: 292px; overflow: scroll"></div>""")

  @controller_search = $("""<input type="text" style="width: 85%">""")

  @controller_ul = $("""<ul class="fa-ul whitelist-alike-filter-dropdown-ul" />""")

  @controller.append(@controller_search)
  @controller.append(@controller_ul)

  populateOptionsList = =>
    search_text = @controller_search.val().toLowerCase()
    @controller_ul.empty()
    for value, value_options of @column_settings.values
      if (html = value_options.html)?
        if value_options.skip_xss_guard
          # Future ready for the day we'll allow users
          # to define custom values.
          # By adding this I'm forcing development to take
          # xss into account
          label = html
        else
          # Prefer the html label
          label = JustdoHelpers.xssGuard(html, {allow_html_parsing: true, enclosing_char: ''})
      else
        label = value_options.txt

      if label.toLowerCase().indexOf(search_text) >= 0
        @controller_ul.append("<li value='#{JustdoHelpers.xssGuard(getHtmlValue(value), {allow_html_parsing: true, enclosing_char: "'"})}'><i class='fa-li fa fa-square-o'></i><i class='fa-li fa fa-check-square-o'></i> #{JustdoHelpers.xssGuard(label, {allow_html_parsing: true, enclosing_char: ''})}</li>")

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
  query = {}

  query[context.column_id] = {$in: column_filter_state}

  return query

GridControl.installFilterType "whitelist",
  controller_constructor: WhiteListFilterControllerConstructor
  column_filter_state_to_query: columnFilterStateToQuery