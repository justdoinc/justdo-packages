bindTargetToPaste = (tpl)->
  $(".justdo_clipboard_import_paste_target").bind "paste", (e)->
    e.stopPropagation()
    e.preventDefault()
    cd = e.originalEvent.clipboardData
    #    console.log(cd.types)
    #    console.log(">>> plain "  + cd.getData("text/plain"))
    #    console.log(">>> html  "  + cd.getData("text/html"))

    if ("text/html" in cd.types)
      data = cd.getData("text/html")
      tr_reg_exp = /<\s*tr[^>]*>(.*?)<\s*\/\s*tr>/g
      td_reg_exp = /<\s*td[^>]*>(.*?)<\s*\/\s*td>/g
      rows = []
      while ((tr = tr_reg_exp.exec(data)) != null)
        cells = []
        while ((td = td_reg_exp.exec(tr[1])) != null)
          cell = td[1]
          cell = cell.replace /<br\/>/g, "\n"
          cell = cell.replace /&quot;/g , '"'
          cell = cell.replace /&#39;/g, "'"
          cells.push cell
        rows.push cells

      #limit max number of rows to import
      if rows.length > 50
        JustdoSnackbar.show
          text: "Too many rows, you may copy up to 50 rows."
          actionText: "Close"
          duration: 10000
          onActionClick: =>
            JustdoSnackbar.close()
            return
        return

      tpl.data.clipboard_data.set rows
      tpl.data.dialog_state.set "has_data"
    return
  return

Template.justdo_clipboard_import_dialog.onCreated ->

  self = @

  Meteor.defer ->
    self.data.dialog_state.set "wait_for_paste"

  @autorun =>
    state = Template.instance().data.dialog_state.get()
    if (state == "wait_for_paste")
      $(".justdo_clipboard_import_paste_target").css("display", "")
      $(".justdo_clipboard_import_table").css("display", "none")
      Meteor.defer ->
        bindTargetToPaste self
    else if state == "has_data"
      $(".justdo_clipboard_import_paste_target").css("display", "none")
      $(".justdo_clipboard_import_table").css("display", "")
    else
      $(".justdo_clipboard_import_paste_target").css("display", "none")
      $(".justdo_clipboard_import_table").css("display", "none")
    return
  return


Template.justdo_clipboard_import_dialog.onRendered ->

  self = @


Template.justdo_clipboard_import_dialog.helpers
#  showDropTarget: ->
#    debugger
#    if ("wait_for_paste" == Template.instance().data.dialog_state.get())
#      return
#    return "style=\"display: none\""

#  has_data: -> return ("has_data" == Template.instance().data.dialog_state.get())

  rows: ->
    if not ("has_data" == Template.instance().data.dialog_state.get())
      return []
    return Template.instance().data.clipboard_data.get()

  numberOfAdditionalColumns: ->
    if not ("has_data" == Template.instance().data.dialog_state.get())
      return []
    return [2..Template.instance().data.clipboard_data.get()[0].length]




Template.justdo_clipboard_import_dialog.events
  "keyup .justdo_clipboard_import_paste_target": (e, tpl)->
    $(".justdo_clipboard_import_paste_target").val("");
    return false

  "click .justdo_clipboard_import_dialog_header_selector a": (e) ->
    field_name = $(e.currentTarget).text()
    col_header_id = $(e.currentTarget)[0].getAttribute("column_id")
    $("##{col_header_id}").text(field_name)
    return



