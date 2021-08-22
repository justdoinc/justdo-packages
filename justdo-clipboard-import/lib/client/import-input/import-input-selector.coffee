Template.justdo_clipboard_import_input_selector.onCreated ->
  self = @
  self.search_input_rv = new ReactiveVar null
  # Special type of fields that isn't supported in grid and doesn't require import
  self.special_fields_map =
    "clipboard-import-no-import": "-- skip column --"
    "task-indent-level": "Indent Level"
    "clipboard-import-index": "Index"

  return

Template.justdo_clipboard_import_input_selector.onRendered ->
  self = @

  $(".justdo-clipboard-import-input-selector").on "shown.bs.dropdown", ->
    $(".clipboard-import-selector-search").focus()
    return

  $(".justdo-clipboard-import-input-selector").on "hidden.bs.dropdown", ->
    $(".clipboard-import-selector-search").val null
    return

  return

Template.justdo_clipboard_import_input_selector.helpers
  notInSearchMode: -> _.isEmpty Template.instance().search_input_rv.get()

  getAvailableFieldTypesArray: ->
    fields = Template.parentData(1).getAvailableFieldTypes()[1]

    if not (search_input = Template.instance().search_input_rv.get())?
      filtered_fields = fields
    else
      filter_regexp = new RegExp("\\b#{JustdoHelpers.escapeRegExp(search_input)}", "i")
      filtered_fields = _.filter fields, (doc) ->  filter_regexp.test(doc.label)

    return filtered_fields

  isAdmin: ->
    if not (cur_proj = APP.modules?.project_page?.curProj())?
      return false

    return cur_proj.isAdmin()

Template.justdo_clipboard_import_input_selector.events
  "click .justdo-clipboard-import-input-selector a[field-id]": (e, tpl) ->
    e.preventDefault()

    field_id = $(e.currentTarget)[0].getAttribute("field-id")

    # Look for field_label in special_fields_map first
    if not (field_label = tpl.special_fields_map[field_id])?
      field_label = Template.parentData(1).getAvailableFieldTypes()?[0]?[field_id]?.label

    $(e.currentTarget).closest(".justdo-clipboard-import-input-selector").find("button")
      .text(field_label)
      .val(field_id)

    return

  "click .manage-columns": ->
    APP.modules.project_page.project_config_ui.showCustomFieldsConfigurationOnly()

    return

  "keyup .clipboard-import-selector-search": (e, tpl) ->
    value = $(e.target).val().trim()

    if _.isEmpty value
      tpl.search_input_rv.set null

    tpl.search_input_rv.set value

    return

  "keydown .justdo-clipboard-import-input-selector .dropdown-menu": (e, tpl) ->
    $dropdown_item = $(e.target).closest(".clipboard-import-selector-search, .dropdown-item")

    if e.which == 38 # Up
      e.preventDefault()

      if ($prev_item = $dropdown_item.prevAll(".dropdown-item").first()).length > 0
        $prev_item.focus()
      else
        $(".clipboard-import-selector-search", $dropdown_item.closest(".justdo-clipboard-import-input-selector")).focus()

    if e.which == 40 # Down
      e.preventDefault()
      $dropdown_item.nextAll(".dropdown-item").first().focus()

    if e.which == 27 # Escape
      $(".justdo-clipboard-import-input-selector .btn").dropdown "hide"

    return
