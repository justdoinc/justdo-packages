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
       label: "Original Index (will not be imported)"
       _id: "clipboard-import-index"

     "task-indent-level":
       label: "Indent Level"
       _id: "task-indent-level"

   # available_field_types[1] is an array
   # unshift = prepend
   available_field_types[1].unshift available_field_types[0]["clipboard-import-no-import"], available_field_types[0]["clipboard-import-index"]
   available_field_types[1].push available_field_types[0]["task-indent-level"]

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
      filter_regexp = new RegExp(JustdoHelpers.escapeRegExp(search_input), "i")
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

    $corresponding_selector_button = $(e.currentTarget).closest(".justdo-clipboard-import-input-selector").find("button")

    # If this column was previously set to owner_id, we revert the cell data back to original here (see why below)
    if $corresponding_selector_button.val() == "owner_id"
      clipboard_data_rv = tpl.parent_data.clipboard_data
      clipboard_data = clipboard_data_rv.get()
      col_index = $(e.currentTarget).closest(".bg-light").data("col-index")

      $(".data-cell[data-col-index=#{col_index}]").each (row_index, data_cell) ->
        if (old_value = clipboard_data[row_index][col_index].old_value)?
          clipboard_data[row_index][col_index] = old_value
        $(data_cell).children(".owner-id-alert").remove()

      clipboard_data_rv.set(clipboard_data)

    $corresponding_selector_button
      .text(field_label)
      .val(field_id)

    # The following block is dedicated to handle task owner import by email
    if field_id == "owner_id"
      col_index = $(e.currentTarget).closest(".bg-light").data("col-index")

      # Load all docs of users from current JustDo
      APP.projects.ensureAllMembersPublicBasicUsersInfoLoaded ->
        clipboard_data_rv = tpl.parent_data.clipboard_data
        clipboard_data = clipboard_data_rv.get()

        # Check if the email belongs to a user and change the cell text to that user's display name
        $(".data-cell[data-col-index=#{col_index}]").each (row_index, data_cell) ->
          $data_cell = $(data_cell)

          if (email_address = $data_cell.text().toLowerCase()) and (JustdoHelpers.common_regexps.email.test email_address)
            if (user_doc = Meteor.users.findOne {"emails.address": email_address}, {fields: JustdoHelpers.avatar_required_fields})
              clipboard_data[row_index][col_index] =
                old_value: $data_cell.text()
                import_value: user_doc._id
                user_obj: user_doc
              return
            # If no user doc found, we put a warning icon next to the cell data indicating that the email does not belong to a member
            user_not_found_icon = """<span title="User not found in the current JustDo, invite the user first." class="raw-tooltip owner-id-alert"><svg class="jd-icon"><use xlink:href="/layout/icons-feather-sprite.svg#alert-triangle"/></svg></span>"""
            $data_cell.prepend(user_not_found_icon) # No user input is used here, hence no xssGuard
            return

          not_email_icon = """<span title="Invalid email" class="raw-tooltip owner-id-alert"><svg class="jd-icon"><use xlink:href="/layout/icons-feather-sprite.svg#alert-circle"/></svg></span>"""
          $data_cell.prepend(not_email_icon) # No user input is used here, hence no xssGuard
          return

        clipboard_data_rv.set(clipboard_data)

        return
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
