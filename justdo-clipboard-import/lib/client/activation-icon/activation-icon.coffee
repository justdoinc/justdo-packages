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
  
  custom_fields_supported_formatters = ["defaultFormatter", "unicodeDateFormatter", "keyValueFormatter", "calculatedFieldFormatter"]
  
  for field_id, field of all_fields
    if field.custom_field and field.grid_editable_column and field.grid_column_formatter in custom_fields_supported_formatters
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

testDataAndImport = (modal_data, selected_columns_definitions) ->
  # Check that all columns have the same number of cells
  cp_data = modal_data.clipboard_data.get()
  number_of_columns = cp_data[0].length
  project_id = JD.activeJustdo()._id
  line_number = 0
  max_indent = -1
  last_indent = 0
  tasks = []
  lines_to_add = {}   # line_index:
                      #   task: task
                      #   indent_level: indent level
  
  row_index = 0
  for row in cp_data
    task = {}
    line_number += 1
    if row.length != number_of_columns
      JustdoSnackbar.show
        text: "Mismatch in number of columns on different rows. Import aborted."

      return false

    task.project_id = project_id
    if not modal_data.rows_to_skip_set.get().has("#{row_index}")
      indent_level = 1
      for column_num in [0..(number_of_columns - 1)]
        cell_val = row[column_num].trim()
        field_def = selected_columns_definitions[column_num]
        field_id = field_def._id
  
        if cell_val.length > 0 and field_id == "task-indent-level"
          indent_level = parseInt cell_val, 10
          
          
        else if cell_val.length > 0 and field_id != "clipboard-import-no-import" and field_id != "task-indent-level"
          if field_def.type is String
            #dealing with options fields
            if field_def.grid_column_formatter == "keyValueFormatter"
              val = null
              for key, defs of field_def.grid_values
                if defs?.txt?.trim()?.toLowerCase() == cell_val.trim().toLowerCase()
                  val = key
                  break
              if val == null
                $(".justdo-clipboard-import-table tr:nth-child(#{line_number + 1})").effect("highlight", {}, 3000)

                JustdoSnackbar.show
                  text: "Invalid #{field_def.label} value #{cell_val} in line #{line_number} - not a valid option. Import aborted."
                  duration: 15000
                return false
              task[field_id] = val
            else
              task[field_id] = cell_val

          if field_def.type is Number
            # TODO: Look for: '_available_field_types' under justdo-internal-packages/grid-control-custom-fields/lib/both/grid-control-custom-fields/grid-control-custom-fields.coffee
            # in the future, the information on whether we need to use parseFloat or parseInt() should be taken from the relevant definition.
            cell_val = parseFloat(cell_val.trim())

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

              return false

            task[field_id] = cell_val

          # If we have a date field, check that the date is formatted properly, and transform to internal format
          if isDateFieldDef(field_def)
            moment_date = moment.utc cell_val, modal_data.date_fields_date_format.get()
            if not moment_date.isValid()
              JustdoSnackbar.show
                text: "Invalid date format in line #{line_number}. Import aborted."
              return false
            task[field_id] = moment_date.format("YYYY-MM-DD")
      tasks.push task
      
      if max_indent < indent_level
        max_indent = indent_level
      if indent_level > last_indent + 1 or indent_level <= 0 or (last_indent == -1 and indent_level != 1) # Indent can't jump more than 1 indent level at once
                                                                                    # and can't start with anything but 1
        JustdoSnackbar.show
          text: "Invalid indentation at line #{line_number} - inconsistent indentation."
          duration: 15000
        return false
      last_indent = indent_level
      lines_to_add[row_index] =
        task: task
        indent_level: indent_level
        
    row_index += 1

  gc = APP.modules.project_page.mainGridControl()
  
  importLevel = (indent_level_to_import, mapSeriesCb) ->
    parent_id = modal_data.parent_task_id
    batches = {}  # parent_id: [tasks]
    for line_index, line of lines_to_add
      if line.indent_level == indent_level_to_import - 1
        parent_id = line.task_id
        
      if line.indent_level == indent_level_to_import
        if not batches[parent_id]?
          batches[parent_id] = []
        batches[parent_id].push line.task

    async_calls = []
    for parent_id, batch of batches
      do (parent_id, batch) ->
        async_calls.push (callback) ->
          gc._grid_data.bulkAddChild "/" + parent_id + "/", batch, callback
          return
        return
        
    
    async.parallelLimit async_calls, 5, (err, results) ->
      result_num = 0
      all_results = []
      for batch_result in results
        for item in batch_result
          all_results.push item[0]
          
      for index,line of lines_to_add
        if line.indent_level == indent_level_to_import
          line.task_id = all_results[result_num]
          result_num += 1
      
      mapSeriesCb(err, results)
      return
    
    return
  
  async.mapSeries [1..max_indent], (n, callback) ->
    importLevel(n, callback)
  , (err, results) ->
  
    if err?
      JustdoSnackbar.show
        text: "#{err}. Import aborted."
        duration: 15000
      return false
  
    # No error
    paths = []
    for level in results
      for batch in level
        for item in batch
          paths.unshift item[1]   # unshift is necessary. Regular push weill fail the operation as we need to start removing
                                  # from the deepest level.
    JustdoSnackbar.show
      text: "#{paths.length} task(s) imported."
      duration: 10000
      actionText: "Undo"
      onActionClick: =>
        gc._grid_data.bulkRemoveParents paths, (err)->
          if err
            JustdoSnackbar.show
              text: "#{err}."
              duration: 15000
          return
      
        JustdoSnackbar.close()
        return # end of onActionClick
    return # end of mapSeries call back
 
  return true
  
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
      rows_to_skip_set: new ReactiveVar(new Set())
      getAvailableFieldTypes: getAvailableFieldTypes
      date_fields_date_format: new ReactiveVar(null)

    message_template =
      JustdoHelpers.renderTemplateInNewNode(Template.justdo_clipboard_import_input, modal_data)

    dialog = bootbox.dialog
      title: "Import spreadsheet data as child tasks to <i>#{JustdoHelpers.taskCommonName(JD.activeItem(), 80)}</i>"
      message: message_template.node
      animate: true
      className: "bootbox-new-design justdo-clipboard-import-dialog"

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
            modal_data.rows_to_skip_set.set(new Set())
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
            if selected_columns_definitions.length < (number_of_columns)
              JustdoSnackbar.show
                text: "Please select all columns fields."
              return false

            # Manage dates - ask for input format
            date_column_found = false
            for column_def in selected_columns_definitions
              if isDateFieldDef(column_def)
                date_column_found = true
                break

            if date_column_found and not modal_data.date_fields_date_format.get()?
              options = _.map(getAllowedDateFormats(), (format) -> {text: format, value: format})
              options.push
                text: "DD MMMM YYYY"
                value: "DD MMMM YYYY"
                
              bootbox.prompt
                title: "Please select dates format"
                animate: true
                className: "bootbox-new-design"
                inputType: "select"
                inputOptions: options
                value: getDefaultDateFormat()
                callback: (date_format) ->
                  modal_data.date_fields_date_format.set(date_format)

                  if testDataAndImport modal_data, selected_columns_definitions
                    bootbox.hideAll()

                  return true

              return false

            if testDataAndImport modal_data, selected_columns_definitions
              return true

            return false

    dialog.on "shown.bs.modal", (e) ->
      $(".justdo-clipboard-import-paste-target").focus()
      return
    return