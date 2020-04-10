bindTargetToPaste = (tpl)->
  $(".justdo-clipboard-import-paste-target").bind "paste", (e) ->
    e.stopPropagation()
    e.preventDefault()
    clipboard_data = e.originalEvent.clipboardData
    if ("text/html" in clipboard_data.types)
      data = clipboard_data.getData("text/html")

      # Info about why we use [^\x05] can be found on: https://bugzilla.mozilla.org/show_bug.cgi?id=1579867
      tr_reg_exp = /<\s*tr[^>]*>([^\x05]*?)<\s*\/\s*tr>/g
      td_reg_exp = /<\s*td[^>]*>([^\x05]*?)<\s*\/\s*td>/g
      longest_row_length = 0
      rows = []
      while ((tr = tr_reg_exp.exec(data)) != null)
        cells = []
        row_length = 0
        all_cells_are_empty = true
        processing_column_number = 0
        while ((td = td_reg_exp.exec(tr[1])) != null)
          processing_column_number += 1
          cell = td[1]
          cell = cell.replace /<br\/?>/g, "\n"
          cell = cell.replace /&quot;/g , '"'
          cell = cell.replace /&#39;/g, "'"
          cell = cell.replace /&lt;/g, "<"
          cell = cell.replace /&gt;/g, ">"
          cells.push cell
          if cell.trim().length > 0
            all_cells_are_empty = false
            row_length = processing_column_number

        if not all_cells_are_empty
          rows.push cells
          if longest_row_length < row_length
            longest_row_length = row_length

      #limit max number of rows to import
      if rows.length > 100
        JustdoSnackbar.show
          text: "Too many rows, you may copy up to 100 rows."
        return

      #trim all rows according to the longest row. This handles cases where the entire row is copied to
      #the clipboard
      for row_number of rows
        rows[row_number] = rows[row_number].slice 0, longest_row_length

      if rows.length > 0
        tpl.data.clipboard_data.set rows
        tpl.data.dialog_state.set "has_data"
        $(".justdo-clipboard-import-main-button").html("Import")
      else
        JustdoSnackbar.show
          text: "Couldn't find tabular information in the clipboard."

    return
  return

Template.justdo_clipboard_import_input.onCreated ->
  self = @

  @showIntro = new ReactiveVar false

  @getAvailableFieldTypes = @data.getAvailableFieldTypes

  Meteor.defer ->
    self.data.dialog_state.set "wait_for_paste"

    return

  @autorun =>
    state = Template.instance().data.dialog_state.get()

    if state == "wait_for_paste"
      $(".justdo-clipboard-import-paste-target").css("display", "")
      $(".justdo-clipboard-import-table").css("display", "none")

      Meteor.defer ->
        bindTargetToPaste self

        return

    else if state == "has_data"
      $(".justdo-clipboard-import-paste-target").css("display", "none")
      $(".justdo-clipboard-import-table").css("display", "")
    else
      $(".justdo-clipboard-import-paste-target").css("display", "none")
      $(".justdo-clipboard-import-table").css("display", "none")
    return
  return

Template.justdo_clipboard_import_input.helpers
  rows: ->
    if not ("has_data" == Template.instance().data.dialog_state.get())
      return []

    return Template.instance().data.clipboard_data.get()

  numberOfColumns: ->
    if not ("has_data" == Template.instance().data.dialog_state.get())
      return []

    return [1..Template.instance().data.clipboard_data.get()[0].length]

  getAvailableFieldTypesArray: ->
    return Template.instance().getAvailableFieldTypes()[1]

  showIntro: ->
    return Template.instance().showIntro.get()

  skipRow: (index)->

    rows_to_skip = Template.instance().data.rows_to_skip_Set.get()
    console.log index, rows_to_skip
    if rows_to_skip.has "#{index}"
      return "skip-row"
    return ""

Template.justdo_clipboard_import_input.events
  "keyup .justdo-clipboard-import-paste-target": (e, tpl)->
    $(".justdo-clipboard-import-paste-target").val("")

    return false

  "click .justdo-clipboard-import-input-selector a": (e, tpl) ->
    e.preventDefault()

    field_id = $(e.currentTarget)[0].getAttribute("field-id")
    field_label = "-- skip column --"
    if field_id != "clipboard-import-no-import"
      field_label = Template.instance().getAvailableFieldTypes()?[0]?[field_id]?.label


    $(e.currentTarget).closest(".justdo-clipboard-import-input-selector").find("button")
      .text(field_label)
      .val(field_id)

    return

  "click .show-intro": (e) ->
    e.preventDefault()
    Template.instance().showIntro.set true

    return

  "click .hide-intro": (e) ->
    e.preventDefault()
    Template.instance().showIntro.set false

    return

  "change .skip-row-checkbox": (e, tpl) ->
    rows_to_skip = Template.instance().data.rows_to_skip_Set.get()
    if e.target.checked
      rows_to_skip.add e.target.getAttribute("row-index")
    else
      rows_to_skip.delete e.target.getAttribute("row-index")
    Template.instance().data.rows_to_skip_Set.set rows_to_skip
    return
