# PACK.filters_controllers initiated in ../columns_filters.coffee
PACK.filters_controllers.whitelist = (grid_control, column_settings) ->
  @grid_control = grid_control
  @column_settings = column_settings

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
    filter_state = @grid_control.getColumnFilter(@column_settings.field)
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
      grid_control.clearColumnFilter(@column_settings.field)
    else
      grid_control.setColumnFilter(@column_settings.field, filter_state)

  @refresh_state()

  return @

_.extend PACK.filters_controllers.whitelist.prototype,
  refresh_state: ->
    filter_state = @grid_control.getColumnFilter(@column_settings.field)

    $("li", @controller).removeClass("selected")
    if not filter_state?
      return

    for value in filter_state
      $("[value=#{value}]", @controller).addClass("selected")

  destroy: ->
    @grid_control.removeListener "filter-change", @filter_change_listener