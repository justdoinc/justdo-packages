# Check README.md to learn more about editors definitions

GridControl.installEditor "SelectorEditor",
  init: ->
    if not (selector_options = @context.column.values)?
      selector_options = {}

    options = []
    for value, value_def of selector_options
      if (html_format = value_def.html)?
        label = html_format
      else
        label = value_def.txt

      options.push {
        label: label
        value: value
        order: value_def.order
      }

    options = _.sortBy options, "order"

    selector_options_html = ""
    for option in options
      selector_options_html +=
        """<option value="#{option.value}" data-content="#{option.label}">#{label}</option>"""

    @$select = $("""<select class="selector-editor">#{selector_options_html}</select>""")
    @$select.appendTo @context.container

    @$select.selectpicker
      dropupAuto: true
      size: false
      width: "100%"

    @$select_picker = @$select.next()
    @$select_picker_obj = @$select_picker.data("this")

    @showSelect()

    @focus()

    @$grid_view_port =
      $(@context.grid.getCanvasNode()).parent()

    @grid_view_port_scroll_handler = =>
      @$select.selectpicker "resizeHandler"

      return

    @$grid_view_port.on "scroll", @grid_view_port_scroll_handler

    return

  setInputValue: (val) ->
    if not val?
      # Regard undefined value as empty string to allow the user set a label
      # for empty/undefined values

      val = ""
    
    @$select.selectpicker("val", val);

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
    @$grid_view_port.off("scroll", @grid_view_port_scroll_handler)

    return

  #
  # Editor specific helpers
  #
  showSelect: ->
    @$select_picker_obj.$menu.show()

    return
