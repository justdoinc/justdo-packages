_.extend JustdoNewProjectTemplates.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    return

  showTemplatesPicker: ->
    message_template = JustdoHelpers.renderTemplateInNewNode Template.new_project_template_selector

    dialog = bootbox.dialog
      message: message_template.node
      title: "Welcome"
      animate: true
      scrollable: true
      closeButton: false
      className: "bootbox-new-design new-project-templates-modal"
      buttons:
        Create:
          label: "Create"
          className: "btn-primary"
          callback: ->
            selected_template_id = message_template.template_instance.active_template_rv.get()

            APP.projects.createNewProject {init_first_task: false, org_id: APP.justdo_orgs.getActiveOrgId()}, (err, project_id) ->
              if err?
                JustdoSnackbar.show
                  text: err.reason or err
                return

              Router.go "project", {_id: project_id}

              APP.justdo_new_project_templates.createSubtreeFromTemplate selected_template_id, project_id, (err) ->
                if err?
                  JustdoSnackbar.show
                    text: err.reason or err
                  return

                if (grid_control = APP.modules.project_page.gridControl())?
                  grid_control.expandDepth()

                return
              return

            return false

    current_url = Router.current().originalUrl

    @close_dialog_tracker?.stop?()
    @close_dialog_tracker = Tracker.autorun (computation) =>
      if Router.current().originalUrl isnt current_url
        dialog.modal "hide"
        computation.stop()
        return

      return

    return
