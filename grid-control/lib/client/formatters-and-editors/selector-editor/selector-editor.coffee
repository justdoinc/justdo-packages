# Check README.md to learn more about editors definitions

minimum_items_to_show_search = 3

getKeyBgColor = (grid_values, value) ->
  if not grid_values?
    grid_values = {}

  if not value?
    # Regard undefined value as empty string (we don't return immediately to
    # allow the user set a html/txt labels for empty/undefined values)
    return undefined

  if not (value_def = grid_values[value])?
    return undefined

  return value_def.bg_color

GridControl.installEditor "SelectorEditor",
  init: ->
    style_right = APP.justdo_i18n.getRtlAwareDirection "right"

    if not (selector_options = @context.column.values)?
      selector_options = {}
    else
      selector_options = _.extend {}, selector_options # shallow copy to avoid affecting the original object

    if not (removed_selector_options = @context.column.removed_values)?
      removed_selector_options = {}

    if (field_value = this.context.item[this.context.field_name])?
      # If we can determine the field_value, and it isn't part of the selector_options,
      # check whether it is part of the removed_selector_options, and if so, add it as
      # the first select options.
      # Note, we do that by adding the option definition to the selector_options object that we
      # *shallow copied* we don't affect the original object.
      if field_value not of selector_options and field_value of removed_selector_options
        selector_options[field_value] = _.extend({}, removed_selector_options[field_value])
        selector_options[field_value].order = -9999 # to ensure it'll appear first.

    options = []
    for value, value_def of selector_options
      if (html_format = value_def.html)?
        label = html_format
      else
        label = APP.justdo_i18n.getDefaultI18nTextOrCustomInput {text: value_def.txt, i18n_key: value_def.txt_i18n}

      options.push {
        label: label
        value: value
        order: value_def.order
        bg_color: JustdoHelpers.normalizeBgColor(value_def.bg_color)
      }

    options = _.sortBy options, "order"

    selector_options_html = ""
    for option in options
      label = option.label.trim()

      if _.isEmpty label
        label = "&nbsp;"

      if option.bg_color != "transparent"
        custom_style = """ style="background-color: #{JustdoHelpers.xssGuard(option.bg_color)}; color: #{JustdoHelpers.xssGuard(JustdoHelpers.getFgColor(option.bg_color))};" """
      else
        custom_style = ''

      selector_options_html +=
        """<option value='#{JustdoHelpers.xssGuard(option.value, {allow_html_parsing: true, enclosing_char: "'"})}' data-content="#{JustdoHelpers.xssGuard(label, {allow_html_parsing: true, enclosing_char: '"'})}" #{custom_style}>#{JustdoHelpers.xssGuard(label, {allow_html_parsing: true, enclosing_char: ""})}</option>"""

    @$select = $("""<select class="selector-editor dropdown-menu-lite">#{selector_options_html}</select>""")
    @$select.appendTo @context.container

    @$select = $(".selector-editor", @context.container)

    show_live_search = false

    if options?
      show_live_search = options.length > minimum_items_to_show_search

    @$select.selectpicker
      width: "100%"
      sanitize: false
      size: 8
      liveSearch: show_live_search

    @$select.selectpicker("refresh")
    @$select.selectpicker("render")

    @$select_picker = @$select.next()

    @showSelect()

    @$grid_view_port =
      $(@context.grid.getCanvasNode()).parent()

    @$select.on "change-request-processed", =>

      saveAndExitActiveEditor = @context.grid_control.saveAndExitActiveEditor()

      if saveAndExitActiveEditor
        if @context.field_name == "state" and @doc.state == "done" and field_value != "done" # field_value is the original value pre-selection.
          $active_cell = $(@context.container)

          removeUpdateDetector = =>
            @context.grid_control._grid_data.off "grid-item-changed", updateDetector

            return

          max_before_give_up = 10
          updateDetector = (item_row, update_fields) =>
            if (max_before_give_up -= 1) < 0
              removeUpdateDetector()

              return

            current_item = @context.grid_control._grid_data.getItem(item_row)

            if current_item?._id == @context.item?._id and current_item.state == "done" and "state" in update_fields
              Meteor.defer =>

                # Salute animation

                # $active_cell.append """
                #   <div class="state-done-animation salute">
                #     <lottie-player
                #       background="transparent"
                #       style="width: initial; height: 123px; position: absolute; top: -50px; #{style_right}: 0"
                #       src="/layout/lottie/task-done-salute.json"
                #       speed="0.5"
                #       autoplay="true">
                #     </lottie-player>
                #   </div>
                # """

                # Check animation

                $active_cell.append """
                  <div class="state-done-animation check">
                    <lottie-player
                      background="transparent"
                      style="width: 45px; height: 45px; position: absolute; top: -20px; #{style_right}: -20px;"
                      src="/layout/lottie/task-done-check.json"
                      speed="3"
                      autoplay="true">
                    </lottie-player>
                  </div>
                """

                setTimeout ->
                  $active_cell.find(".state-done-animation").fadeOut()
                , 1000

                removeUpdateDetector()

                return

            return

          @context.grid_control._grid_data.on "grid-item-changed", updateDetector

      return

    @$select.on "hidden.bs.select", =>
      @context.grid_control.saveAndExitActiveEditor()

      return

    return

  setInputValue: (val) ->
    if not val?
      # Regard undefined value as empty string to allow the user set a label
      # for empty/undefined values

      val = ""

    @$select.selectpicker("val", val)
    @$select.selectpicker("refresh")
    @$select.selectpicker("render")

    bg_color = JustdoHelpers.normalizeBgColor(getKeyBgColor(@context.column.values, val))
    fg_color = JustdoHelpers.getFgColor(bg_color)

    if bg_color?    
      $(".dropdown-toggle", @$select_picker)
        .css("background-color", bg_color)
        .css("color", fg_color)

    return

  serializeValue: ->
    return @$select.selectpicker("val")

  validator: (value) ->
    return undefined

  focus: ->
    $("button", @$select_picker).focus()

    return

  destroy: ->
    @$select.selectpicker("destroy")

    return

  showSelect: ->
    @$select.selectpicker("toggle")

    return

  moreInfoSectionCustomizationsExtensions: ($firstNode, field_editor) ->
    @$select.on "change-request-processed", =>
      Meteor.defer ->
        field_editor.save()

        return

      return

    @$select.on "hidden.bs.select", =>
      Meteor.defer ->
        field_editor.save()

        return

      return

    return