Template.justdo_clipboard_import_input_selector.onCreated ->
  self = @
  self.search_input_rv = new ReactiveVar null
  self.parent_data = Template.parentData(1)
  self.available_field_types_crv = JustdoHelpers.newComputedReactiveVar null, ->
   available_field_types = self.parent_data.getAvailableFieldTypes()
   # To maintain certain options at top/bottom, we manipulate the array and object of available field types explicitly.
   # available_field_types[0] is an object
   _.extend available_field_types[0],
    "clipboard-import-no-import":
      label: "-- skip column --"
      _id: "clipboard-import-no-import"

    "clipboard-import-index":
       label: "Index"
       _id: "clipboard-import-index"

     "task-indent-level":
       label: "Indent Level"
       _id: "task-indent-level"

   # available_field_types[0] is an array
   available_field_types[1].unshift # unshift = prepend
     label: "-- skip column --"
     _id: "clipboard-import-no-import"
   ,
     label: "Index"
     _id: "clipboard-import-index"
   available_field_types[1].push
     label: "Indent Level"
     _id: "task-indent-level"

   return available_field_types

  return

Template.justdo_clipboard_import_input_selector.onRendered ->
  self = @

  $(".justdo-clipboard-import-input-selector").on "shown.bs.dropdown", ->
    $(".clipboard-import-selector-search").focus()
    return

  $(".justdo-clipboard-import-input-selector").on "hidden.bs.dropdown", ->
    self.search_input_rv.set null
    $(".clipboard-import-selector-search").val null
    return

  return

Template.justdo_clipboard_import_input_selector.helpers
  getAvailableFieldTypesArray: ->
    tpl = Template.instance()
    fields = tpl.available_field_types_crv.get()[1]

    if not (search_input = tpl.search_input_rv.get())?
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
    available_field_types_crv = tpl.available_field_types_crv.get()[0]
    field_label = available_field_types_crv[field_id].label

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
