spinning_icon = """<span class="fa fa-spinner fa-spin"></span>"""

_.extend JustDoProjectsTemplates.prototype,
  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return

  showTemplatesFromCategoriesPicker: (options) ->
    if not (project_id = JD.activeJustdoId())?
      return

    default_options =
      popup_title_i18n: "Choose template"
      popup_subtitle_i18n: ""
      categories: ["blank"]
      target_task: "/"
      allow_closing: true
    options = _.extend default_options, options

    message_template = JustdoHelpers.renderTemplateInNewNode Template.project_template_from_category_selector, {categories: options.categories, subtitle_i18n: options.popup_subtitle_i18n}
    message_template.node.classList.add "project-template-selector-wrapper"

    create_button_disabled = false

    dialog = bootbox.dialog
      message: message_template.node
      title: TAPi18n.__ options.popup_title_i18n
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

            $create_btn = $(".modal-footer>.create-btn")
            $create_btn.addClass "disabled"
            $create_btn.html spinning_icon

            template_instance = message_template.template_instance
            selected_template_id = template_instance.active_template_id_rv.get()

            @createSubtreeFromTemplate options.target_task, selected_template_id, project_id, (err, res) ->
              if err?
                create_button_disabled = false
                $create_btn.removeClass "disabled"
                $create_btn.html "Create"
                JustdoSnackbar.show
                  text: err.reason or err
                return

              dialog.modal "hide"

              Meteor.setTimeout ->
                if (grid_data = APP.modules.project_page.gridData())? and _.isArray(paths_to_expand = res?.paths_to_expand)
                  for path in paths_to_expand
                    grid_data.expandPath path
              , 2000

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
