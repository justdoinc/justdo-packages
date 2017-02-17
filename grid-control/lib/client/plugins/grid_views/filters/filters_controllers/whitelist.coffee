#
# Filter controller constructor
#
WhiteListFilterControllerConstructor = (context) ->
  @grid_control = context.grid_control
  @column_settings = context.column_settings
  @column_filter_state_ops = context.column_filter_state_ops

  @filter_change_listener = => @refresh_state()

  @grid_control.on "filter-change", @filter_change_listener

  @controller = $("<ul class='fa-ul' />")

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
        label = JustdoHelpers.xssGuard(html)
    else
      label = value_options.txt

    @controller.append("<li value='#{value}'><i class='fa-li fa fa-square-o'></i><i class='fa-li fa fa-check-square-o'></i> #{label}</li>")

  $(@controller).on "click", "li", (e) =>
    filter_state = @column_filter_state_ops.getColumnFilter()
    $el = $(e.target).closest("li")
    value = $el.attr("value")

    if $el.hasClass("selected")
      filter_state = _.without filter_state, value
    else
      if filter_state?
        filter_state = _.union filter_state, [value]
      else
        filter_state = [value]

    if _.isEmpty(filter_state)
      @column_filter_state_ops.clearColumnFilter()
    else
      @column_filter_state_ops.setColumnFilter(filter_state)

  @refresh_state()

  return @

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
      $("[value=#{value}]", @controller).addClass("selected")

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