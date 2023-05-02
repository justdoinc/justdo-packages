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
            APP.projects.createNewProject {init_first_task: false, org_id: APP.justdo_orgs.getActiveOrgId()}, (err, project_id) ->
              if err?
                JustdoSnackbar.show
                  text: err.reason
                return
              Router.go "project", {_id: project_id}
              dialog.modal "hide"
              return
            return false
