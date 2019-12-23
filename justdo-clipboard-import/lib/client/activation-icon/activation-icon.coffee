
Template.justdo_clipboard_import_activation_icon.events

  "click .justdo-clipboard-import-activation": (e,tpl)->

    #check to see if there is a task selected
    if not JD.activePath()
      JustdoSnackbar.show
        text: "A task must be selected to import from the clipboard."
        actionText: "Close"
        duration: 10000
        onActionClick: =>
          JustdoSnackbar.close()
          return
      return

    modal_data =
      dialog_state: new ReactiveVar ""
      clipboard_data: new ReactiveVar []

    message_template =
      JustdoHelpers.renderTemplateInNewNode(Template.justdo_clipboard_import_dialog, modal_data)

    bootbox.dialog
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
            return false

        Import:
          label: "Import"
          className: "btn-primary"
          callback: =>

            return true

    return