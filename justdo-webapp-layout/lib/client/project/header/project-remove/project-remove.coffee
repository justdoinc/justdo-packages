APP.executeAfterAppLibCode ->
  module = APP.modules.project_page
  curProj = module.helpers.curProj

  Template.project_settings_dropdown_remove_project.events
    "click #remove-project": (e) ->
      currrent_project = curProj()

      currrent_project_title =
        currrent_project.getProjectDoc().title || ""

      currrent_project_title = currrent_project_title.trim()

      project_name_typed_correctly = ->
        return $(".project-remove-project-name-input").val().trim() == currrent_project_title

      setErrorMessage = (message) ->
        $(".remove-failed-error-message")
          .removeClass("empty")
          .html(JustdoHelpers.xssGuard(message))

        return

      clearErrorMessage = ->
        $(".remove-failed-error-message")
          .addClass("empty")
          .html("")

        return

      disableRemoveButton = ->
        $(".delete-project-confirm")
          .attr("disabled", "disabled")

        return

      enableRemoveButton = ->
        $(".delete-project-confirm")
          .removeAttr("disabled")

        return

      box = bootbox.dialog
        title: "Are you sure?"
        message: """
          <div class="message-paragraph">
            This will permanently remove the <b>#{currrent_project_title}</b> JustDo.<br />
          </div>

          <div class="message-paragraph">
            Please type in the name of the JustDo to confirm.
          </div>

          <input type="text" class="project-remove-project-name-input form-control">

          <div class="remove-failed-error-message empty"></div>
        """
        animate: false
        className: "project-remove-dialog"

        onEscape: ->
          return true

        buttons:
          delete_project:
            label: """Delete this JustDo"""

            className: "btn-danger delete-project-confirm"

            callback: =>
              if $(".delete-project-confirm").attr("disabled") == "disabled"
                # This shouldn't happen in reality.

                return

              if not project_name_typed_correctly()
                # We'll get here only if we got a bug somewhere
                setErrorMessage("Wrong JustDo name entered")

                return

              disableRemoveButton()
              clearErrorMessage()

              curProj().removeProject (err) ->
                if err?
                  enableRemoveButton()

                  setErrorMessage(err.reason)

                  return

                # If no error, close the modal
                box.modal("hide") # bad api name, but hide removes the modal

                return

              return false # so the bootbox won't close

          cancel:
            label: "Cancel"

            className: "btn-primary"

            callback: ->
              return true

      if currrent_project_title != ""
        # If the project title is empty, don't disable the remove
        # button, user can remove immediately
        disableRemoveButton()

      $(".project-remove-project-name-input").keyup ->
        if project_name_typed_correctly()
          enableRemoveButton()
        else
          disableRemoveButton()

      return
