_.extend JustDoProjectsTemplates.prototype,
  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return

  showTemplatesPicker: (options) ->
    if not (project_id = JD.activeJustdoId())?
      return

    default_options =
      popup_title: "Choose template"
      popup_subtitle: ""
      categories: ["blank", "getting-started"]
      target_task: "/"
      allow_closing: true
    options = _.extend default_options, options

    message_template = JustdoHelpers.renderTemplateInNewNode Template.project_template_selector, {categories: options.categories, subtitle: options.popup_subtitle}
    create_button_disabled = false

    dialog = bootbox.dialog
      message: message_template.node
      title: options.popup_title
      animate: true
      scrollable: true
      closeButton: options.allow_closing
      className: "bootbox-new-design project-templates-modal"
      buttons:
        Create:
          label: "Create"
          className: "btn-primary create-btn"
          callback: =>
            # Ensure rapid clicking will not trigger multiple calls
            if create_button_disabled
              return

            create_button_disabled = true
            $(".modal-footer>.create-btn").addClass "disabled"

            template_instance = message_template.template_instance
            selected_template_category_id = template_instance.active_category_id_rv.get()
            selected_template_id = template_instance.active_template_id_rv.get()

            @createSubtreeFromTemplate options.target_task, selected_template_category_id, selected_template_id, project_id, (err) ->
              if err?
                create_button_disabled = false
                JustdoSnackbar.show
                  text: err.reason or err
                return

              dialog.modal "hide"

              if (grid_control = APP.modules.project_page.gridControl())?
                grid_control.expandDepth()

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
