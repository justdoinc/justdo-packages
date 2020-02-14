# The order below will also serve as the ordering in the dropdown
base_supported_fields_ids = [
  "title"
  "status"
  "start_date"
  "end_date"
  "due_date"
  "priority"
]

fallback_date_format = "YYYY-MM-DD"

getAllowedDateFormats = ->
  return Meteor.users.simpleSchema()?.schema()?["profile.date_format"]?.allowedValues or [fallback_date_format]

getDefaultDateFormat = ->
  return Meteor.user()?.profile?.date_format or Meteor.users.simpleSchema()?.schema()?["profile.date_format"]?.defaultValue or fallback_date_format

isDateFieldDef = (field_def) ->
  return field_def.grid_column_formatter == "unicodeDateFormatter"

getAvailableFieldTypes = ->
  # Reactive resource
  #
  # Returns an array whose
  #
  #  * First item is an object with the schema definition for the
  #  supported_fields_ids available in the current grid.
  #  * Second item is an array of schema definitions + _id field with the
  #  field id. Ordered according to supported_fields_ids order.
  gc = APP.modules.project_page.mainGridControl()

  supported_fields_ids = base_supported_fields_ids.slice()
  all_fields = gc.getSchemaExtendedWithCustomFields()
  for field_id, field of all_fields
    # allow also to add to custom fields that are not of 'option' type
    if field.custom_field and (field.grid_column_formatter == "defaultFormatter" or field.grid_column_formatter == "unicodeDateFormatter")
      supported_fields_ids.push field_id

  supported_fields_definitions_object =
    _.pick all_fields, supported_fields_ids

  supported_fields_definitions_array =
    _.map supported_fields_ids, (field_id) ->
      if (field_def = supported_fields_definitions_object[field_id])?
        return _.extend {}, field_def, {_id: field_id}
      return undefined

  supported_fields_definitions_array = _.filter(supported_fields_definitions_array)
  return [supported_fields_definitions_object, supported_fields_definitions_array]

getSelectedColumnsDefinitions = ->
  available_field_types = getAvailableFieldTypes()

  selected_columns_definitions = []

  $(".justdo-clipboard-import-input-selector button[value]").each ->
    field_id = $(@).val()

    selected_columns_definitions.push(_.extend {}, available_field_types?[0]?[field_id], {_id: field_id})

    return

  return selected_columns_definitions

testDataAndImport = (modal_data, selected_columns_definitions, dates_format) ->
  # Check that all columns have the same number of cells
  cp_data = modal_data.clipboard_data.get()
  number_of_columns = cp_data[0].length
  project_id = JD.activeJustdo()._id
  line_number = 0
  tasks = []
  for row in cp_data
    task = {}
    line_number += 1
    if row.length != number_of_columns
      JustdoSnackbar.show
        text: "Mismatch in number of columns on different rows. Import aborted."

      return

    task.project_id = project_id

    for column_num in [0..(number_of_columns - 1)]
      cell_val = row[column_num].trim()
      field_def = selected_columns_definitions[column_num]
      field_id = field_def._id

      if cell_val.length > 0
        if field_def.type is String
          task[field_id] = cell_val

        if field_def.type is Number
          # TODO: Look for: '_available_field_types' under justdo-internal-packages/grid-control-custom-fields/lib/both/grid-control-custom-fields/grid-control-custom-fields.coffee
          # in the future, the information on whether we need to use parseFloat or parseInt() should be taken from the relevant definition.
          cell_val = parseFloat(cell_val.trim(), 10)

          # Check valid range
          out_of_range = false
          if field_def.min?
            if cell_val < field_def.min
              out_of_range = true

          if field_def.max?
            if cell_val > field_def.max
              out_of_range = true

          if out_of_range
            JustdoSnackbar.show
              text: "Invalid #{field_def.label} value #{cell_val} in line #{line_number} (must be between #{field_def.min} and #{field_def.max}). Import aborted."

            return

          task[field_id] = cell_val

        # If we have a date field, check that the date is formatted properly, and transform to internal format
        if isDateFieldDef(field_def)
          moment_date = moment.utc cell_val, dates_format
          if not moment_date.isValid()
            JustdoSnackbar.show
              text: "Invalid date format in line #{line_number}. Import aborted."
            return
          task[field_id] = moment_date.format("YYYY-MM-DD")

    tasks.push task

  gc = APP.modules.project_page.mainGridControl()
  gc._grid_data.bulkAddChild "/" + modal_data.parent_task_id + "/", tasks, (err, results) ->
    if err?
      JustdoSnackbar.show
        text: "#{err}. Import aborted."
        duration: 15000

      return

    # No error
    JustdoSnackbar.show
      text: "#{results.length} task(s) imported."
      duration: 10000
      actionText: "Undo"
      onActionClick: =>
        paths = []
        for result in results
          paths.push result[1]
        gc._grid_data.bulkRemoveParents paths, (err)->
          if err
            JustdoSnackbar.show
              text: "#{err}."
              duration: 15000
          return

        JustdoSnackbar.close()
        return

  return


Template.justdo_clipboard_import_activation_icon.events
  "click .justdo-clipboard-import-activation": (e, tpl)->
    # Check to see if there is a task selected
    if not (JD.activePath() and JD.activeItem()._id?)
      JustdoSnackbar.show
        text: "A task must be selected to import from the clipboard."
      return

    modal_data =
      dialog_state: new ReactiveVar ""
      clipboard_data: new ReactiveVar []
      parent_task_id: JD.activeItem()._id
      getAvailableFieldTypes: getAvailableFieldTypes

    message_template =
      JustdoHelpers.renderTemplateInNewNode(Template.justdo_clipboard_import_input, modal_data)

    dialog = bootbox.dialog
      title: "Import Spreadsheet Data"
      message: message_template.node
      animate: true
      className: "bootbox-new-design"

      onEscape: ->
        return true

      scrollable: true

      buttons:
        Reset:
          label: "Reset"
          className: "btn-default justdo-import-clipboard-data-reset-button"
          callback: =>
            modal_data.dialog_state.set "wait_for_paste"
            modal_data.clipboard_data.set []
            $(".justdo-clipboard-import-main-button").html("Cancel")

            Meteor.defer ->
              $(".justdo-clipboard-import-paste-target").focus()

            return false

        Import:
          label: "Cancel"
          className: "btn-primary justdo-clipboard-import-main-button"
          callback: =>
            cp_data = modal_data.clipboard_data.get()
            if cp_data.length == 0
              return true
            number_of_columns = cp_data[0].length
            # This should not happen, but just in case
            if number_of_columns == 0
              return true

            selected_columns_definitions = getSelectedColumnsDefinitions()

            # Check that all columns are selected and return false if not the case
            if selected_columns_definitions.length < (number_of_columns - 1)
              JustdoSnackbar.show
                text: "Please select all columns fields."
              return false

            # Manage dates - ask for input format
            date_column_found = false
            for column_def in selected_columns_definitions
              if isDateFieldDef(column_def)
                date_column_found = true
                break
            if date_column_found
              bootbox.prompt
                title: "Please select dates format"
                animate: true
                className: "bootbox-new-design"
                inputType: "select"
                inputOptions: _.map(getAllowedDateFormats(), (format) -> {text: format, value: format})
                value: getDefaultDateFormat()
                callback: (date_format) ->
                  if not date_format?
                    # The user clicked the X button to Cancel the operation.
                    return

                  testDataAndImport modal_data, selected_columns_definitions, date_format

                  return

            else
              testDataAndImport modal_data, selected_columns_definitions

            return true

    dialog.on "shown.bs.modal", (e) ->
      $(".justdo-clipboard-import-paste-target").focus()
      return
    return