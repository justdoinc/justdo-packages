potential_date_columns = ["Start Date", "End Date", "Due Date"]

column_name_to_colum_id =
  "Start Date": "start_date"
  "End Date": "end_date"
  "Due Date": "due_date"
  "Priority": "priority"

testDataAndImport = (modal_data, dates_format) ->
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
    # Check fields content such as dates format, priority range etc.
    # Row 0 is always the subject. let's make sure it's a simple string
    try
      check row[0], String
    catch
      JustdoSnackbar.show
        text: "Invalid Subject format in #{line_number}. Import aborted."
      return

    task.title = row[0]
    task.project_id = project_id

    if number_of_columns > 1
      for column_num in [1..number_of_columns]
        cell_val = row[column_num]
        field_type = modal_data.columns_selection["justdo_clipboard_import_input_#{column_num + 1}"]
        column_id = column_name_to_colum_id[field_type]

        # If Priority - check that the value is between 0 and 100
        if field_type == "Priority"
          if not /^[0-9][0-9]?$|^100$/g.exec cell_val
            JustdoSnackbar.show
              text: "Invalid priority value in line #{line_number} (must be between 0 and 100). Import aborted."
            return
          task[column_id] = parseInt cell_val, 10


        # If we have a date field, check that the date is formatted properly, and transform to internal format
        if field_type in potential_date_columns
          moment_date = moment.utc cell_val, dates_format
          if not moment_date.isValid()
            JustdoSnackbar.show
              text: "Invalid date format in line #{line_number}. Import aborted."
            return
          task[column_id] = moment_date.format("YYYY-MM-DD")

    tasks.push task

  gc = APP.modules.project_page.mainGridControl()
  gc._grid_data.bulkAddChild modal_data.parent_task_id, tasks, (err, results) ->
    if err
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
          paths.push "/" + result[1]
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
  "click .justdo-clipboard-import-activation": (e,tpl)->

    # Check to see if there is a task selected
    if not JD.activePath()
      JustdoSnackbar.show
        text: "A task must be selected to import from the clipboard."
      return

    modal_data =
      dialog_state: new ReactiveVar ""
      clipboard_data: new ReactiveVar []
      columns_selection: {}
      parent_task_id: JD.activeItem()._id

    message_template =
      JustdoHelpers.renderTemplateInNewNode(Template.justdo_clipboard_import_input, modal_data)

    dialog = bootbox.dialog
      title: "Import Clipboard Data"
      message: message_template.node
      animate: true
      className: "bootbox-new-design"

      onEscape: ->
        return true

      scrollable: true

      buttons:
        Reset:
          label: "Reset"
          className: "btn-primary justdo-import-clipboard-data-reset-button"
          callback: =>
            modal_data.dialog_state.set "wait_for_paste"
            modal_data.clipboard_data.set []
            modal_data.columns_selection = {}
            $(".justdo-clipboard-import-main-button").html("Cancel")
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

            # Check that all columns are selected and return false if not the case
            if Object.keys(modal_data.columns_selection).length < (number_of_columns - 1)
              JustdoSnackbar.show
                text: "Please select all columns fields."
              return false

            # Manage dates - ask for input format
            date_column_found = false
            for column_id, column_name of modal_data.columns_selection
              if column_name in potential_date_columns
                date_column_found = true
                break
            if date_column_found
              bootbox.prompt
                title: "Please select dates format"
                animate: true
                className: "bootbox-new-design"
                inputType: 'select'
                inputOptions: [
                    text: 'YYYY-MM-DD'
                    value: 'YYYY-MM-DD'
                  ,
                    text: 'YYYY/MM/DD'
                    value: 'YYYY/MM/DD'
                  ,
                    text: 'DD/MM/YYYY'
                    value: 'DD/MM/YYYY'
                  ,
                  text: 'MM/DD/YYYY'
                  value: 'MM/DD/YYYY'
                ]
                callback: (date_format)->
                  testDataAndImport modal_data, date_format
                  return

            else
              testDataAndImport modal_data

            return true

    dialog.on 'shown.bs.modal', (e) ->
      $(".justdo_clipboard_import_paste_target").focus()
      return
    return