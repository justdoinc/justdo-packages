# Check README.md to learn more about editors definitions

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

    @$select.on "change-request-processed", =>
      @context.grid_control.saveAndExitActiveEditor()

      return

    @applyStaticFix()

    return

  setInputValue: (val) ->
    if not val?
      # Regard undefined value as empty string to allow the user set a label
      # for empty/undefined values

      val = ""
    
    @$select.selectpicker("val", val);

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

  moreInfoSectionCustomizations: ($firstNode, field_editor) ->
    field_editor.$dom_node.find("div.dropdown-menu").removeAttr("style")

    $firstNode.find(".dropdown-menu a")
      .click (e) ->
        Meteor.defer ->
          field_editor.save()

          $(":focus").blur()

          return

    return