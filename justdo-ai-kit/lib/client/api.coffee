_.extend JustdoAiKit.prototype,
  _immediateInit: ->
    @chatbox_dropdown_messages_rv = new ReactiveVar [
      {
        role: "bot"
        msg: "Hi. Ask me anything about your project~"
      }
    ]
    @sub_handles_by_req_id = {}
    @show_ai_template_picker_condition = {}
    @_registerSiteAdminPage()

    return

  _deferredInit: ->
    if @destroyed
      return

    @_setupContextMenu()
    @_setupEventHooks()
    @_registerProjectHeaderButtonForPocDomains()
    @_setupDropdown()

    return

  registerShowAiTemplatePickerCondition: (condition_id, condition) ->
    check condition_id, String
    check condition, Function
    @show_ai_template_picker_condition[condition_id] = condition
    return

  checkShowAiTemplatePickerCondition: (project_id) ->
    for condition_id, condition of @show_ai_template_picker_condition
      if not condition project_id
        return false
    return true

  _registerProjectHeaderButtonForPocDomains: ->
    if not JustdoAiKit.enable_chat_assistant_for_project_level
      return

    JD?.registerPlaceholderItem "ai-kit-chatbox-btn",
      data:
        template: "ai_kit_chatbox_dropdown_btn"
        template_data: {}

      domain: "project-left-navbar"
      position: 200

    return

  setSubHandle: (req_id, sub_handle) ->
    @sub_handles_by_req_id[req_id] = sub_handle
    return

  stopAndDeleteSubHandle: (req_id) ->
    Tracker.nonreactive =>
      handle = @sub_handles_by_req_id[req_id]
      handle?.stop?()
      return

    delete @sub_handles_by_req_id[req_id]
    return

  _setupEventHooks: ->
    self = @

    if @app_type is "web-app"
      # Do not create first task for new project
      APP.projects.on "pre-create-new-project", (options) -> options.init_first_task = false

      # Unset the template picker hook from justdo_new_project_templates
      APP.justdo_new_project_templates?.unsetShowFirstJustDoTemplatePickerForNewUserHook()
      # Setup our version of the hook for the first project created for new users
      APP.projects.once "post-reg-init-completed", (init_report) ->
        # If the first project is not created, simply return
        if not _.isString(first_project_id = init_report.first_project_created)
          return

        # Check if other plugins prevent the picker from showing in this project
        if not self.checkShowAiTemplatePickerCondition first_project_id
          return

        # Check if user campaign allows picker to show
        if not self._isUserCampaignAllowFirstProjectTemplateGeneratorToShow()
          return

        Tracker.autorun (computation) ->
          active_justdo = JD.activeJustdo {lastTaskSeqId: 1}

          if not (project_id = active_justdo?._id)?
            return

          # Unlikely to happen, but in case someone created a project then immidiately go to another project, stop this computation.
          if project_id isnt first_project_id
            computation.stop()
            return

          # If project is already created with tasks, do not show the picker
          # (First task upon project creation is handled above)
          if active_justdo?.lastTaskSeqId isnt 0
            computation.stop()
            return

          if not (gc = APP.modules.project_page.gridControl(true))?
            return

          if not (grid_ready = gc.ready?.get?())
            return

          self.showNewProjectTemplateGenerator()
          computation.stop()
          return

        return

      # Show AI template picker after new project is created except the first one we create for new users
      APP.projects.on "post-create-new-project", (project_id) ->
        if not self.checkShowAiTemplatePickerCondition project_id
          return

        Tracker.autorun (computation) ->
          if (JD.activeJustdoId() is project_id) and (gc = APP.modules.project_page.gridControl())?
            self.showNewProjectTemplateGenerator()
            computation.stop()
            return
          return

    return

  showNewProjectTemplateGenerator: ->
    if not (project_id = JD.activeJustdoId())?
      return

    message_template = JustdoHelpers.renderTemplateInNewNode Template.project_template_welcome_ai

    dialog = bootbox.dialog
      message: message_template.node
      animate: false
      scrollable: true
      backdrop: false
      closeButton: false
      onEscape: true
      rtl_ready: true
      className: "bootbox-new-design project-templates-modal project-template-ai-modal"

    message_template.template_instance.bootbox_dialog = dialog

    current_url = Router.current().originalUrl

    @close_dialog_tracker?.stop?()
    @close_dialog_tracker = Tracker.autorun (computation) =>
      if Router.current().originalUrl isnt current_url
        dialog.modal "hide"
        computation.stop()
        return

      return

    return

  _setupContextMenu: ->
    if @app_type is "web-app"
      APP.justdo_tasks_context_menu.registerSectionItem "main", "tasks-summary",
        position: 10
        data:
          label: "Summary"
          label_i18n: "ai_tasks_summary_label"
          icon_type: "feather"
          icon_val: "jd-ai"
          icon_class: "ai-icon"
          op: ->
            template = APP.helpers.renderTemplateInNewNode(Template.tasks_summary)

            dialog = bootbox.dialog
              message: template.node
              className: "bootbox-new-design ai-summary-bootbox"
              closeButton: false
              onEscape: ->
                return true

            dialog.on "shown.bs.modal", -> $(".ai-wizard-input").focus()

            return

        listingCondition: (item_data, task_id, task_path, field_val, dependencies_fields_vals, field_info, gc) ->
          if not gc?
            return false

          if gc.isMultiSelectMode()
            selected_items_count = _.size gc.getFilterPassingMultiSelectedPathsArray()
            is_selected_items_count_lte_limit = selected_items_count <= JustdoAiKit.tasks_summary_tasks_limit
            return is_selected_items_count_lte_limit

          return true

    return

  _setupDropdown: ->
    AiWizardTooltipDropdownConstructor = JustdoHelpers.generateNewTemplateDropdown "ai-kit-tooltip", "ai_wizard_tooltip",
      custom_bound_element_options:
        close_button_html: null

      updateDropdownPosition: ($connected_element) ->
        @$dropdown
          .position
            of: $connected_element
            my: "left top"
            at: "right bottom"
            collision: "flipfit"
            using: (new_position, details) =>
              element = details.element
              element.element.css
                top: new_position.top
                left: new_position.left

        return

    @tooltip_dropdown = new AiWizardTooltipDropdownConstructor()
    return

  renderAiWizardTooltip: (e) ->
    e.stopPropagation()
    @tooltip_dropdown.$connected_element = $(e.currentTarget)
    @tooltip_dropdown.openDropdown()
    return

  closeAiWizardTooltip: ->
    @tooltip_dropdown.closeDropdown()
    return

  _registerSiteAdminPage: ->
    APP.executeAfterAppClientCode =>
      if APP.justdo_site_admins?
        APP.justdo_site_admins.registerSiteAdminsPage "ai-requests",
          title: "AI Requests"
          template: "justdo_site_admin_ai_requests"
          listingCondition: -> APP.justdo_site_admins?.isUserSuperSiteAdmin Meteor.userId()

      return
    return
