# Check README.md to learn more about editors definitions

GridControl.installEditor "SelectorEditor",
  init: ->
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
        label = value_def.txt

      options.push {
        label: label
        value: value
        order: value_def.order
      }

    options = _.sortBy options, "order"

    selector_options_html = ""
    for option in options
      label = option.label.trim()

      if _.isEmpty label
        label = "&nbsp;"

      selector_options_html +=
        """<option value="#{option.value}" data-content="#{label}">#{label}</option>"""

    @$select = $("""<select class="selector-editor">#{selector_options_html}</select>""")
    @$select.appendTo @context.container

    @$select.selectpicker
      dropupAuto: true
      size: false
      width: "100%"

    @$select_picker = @$select.next()
    @$select_picker_obj = @$select_picker.data("this")

    @showSelect()

    @$grid_view_port =
      $(@context.grid.getCanvasNode()).parent()

    @grid_view_port_scroll_handler = =>
      @$select.selectpicker "resizeHandler"

      return

    @$grid_view_port.on "scroll", @grid_view_port_scroll_handler

    @applyStaticFix()

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

  applyStaticFix: ->
    if $(@context.container).hasClass("slick-cell")
      $(@context.container).addClass("selector-editor-container-cell")

    return

  destroyStaticFix: ->
    $(@context.container).removeClass("selector-editor-container-cell")

    return

  destroy: ->
    @$select.selectpicker("destroy")
    @$grid_view_port.off("scroll", @grid_view_port_scroll_handler)

    @destroyStaticFix()

    return

  #
  # Editor specific helpers
  #
  showSelect: ->
    @$select_picker_obj.$menu.show()

    return
