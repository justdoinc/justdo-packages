APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page
  main_module = APP.modules.main
  curProj = project_page_module.helpers.curProj

  project_template_helpers = APP.modules.project_page.template_helpers

  #
  # project_header template
  #
  Template.project_header.helpers project_template_helpers

  #
  # project_header_global_layout_header_right, project_header_global_layout_header_middle, project_header_global_layout_header_left templates
  #
  Template.project_header_global_layout_header_right.helpers project_template_helpers
  Template.project_header_global_layout_header_right.helpers
    rightNavbarItems: ->
      return JD.getPlaceholderItems("project-right-navbar").reverse()

  Template.project_header_global_layout_header_left.helpers project_template_helpers
  Template.project_header_global_layout_header_left.helpers
    leftNavbarItems: ->
      return JD.getPlaceholderItems("project-left-navbar").reverse()

  JD.registerPlaceholderItem "members-dropdown-button",
    data:
      template: "members_dropdown_button"
      template_data: {}

    domain: "project-right-navbar"
    position: 100

  # JD.registerPlaceholderItem "plugins-store-button",
  #   data:
  #     template: "plugins_store_button"
  #     template_data: {}
  #
  #   domain: "project-right-navbar"
  #   position: 200

  JD.registerPlaceholderItem "project-settings",
    data:
      template: "project_settings"
      template_data: {}

    domain: "project-right-navbar"
    position: 0

  JD.registerPlaceholderItem "project-required-actions-dropdown-comp",
    data:
      template: "project_required_actions_dropdown_comp"
      template_data: {}

    domain: "global-right-navbar"
    position: 50


  Template.project_header_global_layout_header_middle.helpers project_template_helpers

  #
  # project_name template
  #
  Template.project_name.helpers project_template_helpers

  Template.project_name.helpers
    projectName: ->
      # IMPORTANT!!!
      # This helper returns and renders pure html which make xss attack possible
      # Currently the only user input is project_name and it's been pass through xssGuard to prevent such attacks
      # In case additional user-specified data is returned in this method, MAKE SURE IT PASSES THROUGH XSS GUARD BEFORE RETURNING
      if project = curProj()
        project_name = JustdoHelpers.xssGuard project.getProjectDoc({fields: {title: 1}})?.title
        is_admin = project.isAdmin()
        is_untitled = project.isUntitled()
        contenteditable = false
        active_class = ""

        if is_untitled
          project_name = "Untitled JustDo"

        project_name_el = """<div id="project-name" spellcheck="false" """

        if is_admin
          contenteditable = true
          active_class = "active"

        project_name_el += """class="#{active_class}" contenteditable=#{contenteditable}>#{project_name}</div>"""

        return project_name_el

    isUserProjectAdmin: ->
      if curProj()?.isAdmin?()
        return true
      return false

  # Code to insert sanitized text without affecting caret position.
  # Taken from https://stackoverflow.com/questions/21205785/how-to-make-html5-contenteditable-div-allowing-only-text-in-firefox
  insertTextAtSelection = (div, txt) ->
    # get selection area so we can position insert
    sel = window.getSelection()
    text = div.textContent
    before = Math.min(sel.focusOffset, sel.anchorOffset)
    after = Math.max(sel.focusOffset, sel.anchorOffset)
    # ensure string ends with \n so it displays properly
    afterStr = text.substring(after)
    if afterStr == ""
      afterStr = "\n"
    # insert content
    div.textContent = text.substring(0, before) + txt + afterStr
    # restore cursor at correct position
    sel.removeAllRanges()
    range = document.createRange()
    # childNodes[0] should be all the text
    range.setStart div.childNodes[0], before + txt.length
    range.setEnd div.childNodes[0], before + txt.length
    sel.addRange range
    return

  Template.project_name.events
    "paste .project-name-wrapper #project-name": (e,tpl) ->
      e.preventDefault()
      e = e.originalEvent or e
      new_title = e.clipboardData.getData "text/plain"
      insertTextAtSelection $("#project-name").get(0), new_title
      return

    "keypress .project-name-wrapper #project-name": (e,tpl) ->
      if e.keyCode == 13
        e.preventDefault()
        new_title = $("#project-name").text()
        curProj().updateProjectName new_title

        $("#project-name").blur()

      return

    "blur .project-name-wrapper #project-name": (e, tpl) ->
      new_title = $("#project-name").text()
      curProj().updateProjectName new_title

      return

  #
  # project_settings template
  #
  Template.project_settings.helpers project_template_helpers

  Template.project_settings.helpers
    showRolesAndGroupsManager: ->
      return APP.justdo_roles?.showRolesAndGroupsManagerDialogOpenerInProjectSettingsDropdown()

    customJustdoSaveDefaultViewEnabled: ->
      return APP.custom_justdo_save_default_view?.isPluginInstalledOnProjectDoc(JD.activeJustdo({conf: 1}))

    settingsDropdownTopItems: ->
      return JD.getPlaceholderItems("settings-dropdown-top")

    settingsDropdownMiddleItems: ->
      return JD.getPlaceholderItems("settings-dropdown-middle")

    settingsDropdownBottomItems: ->
      return JD.getPlaceholderItems("settings-dropdown-bottom")

  Template.project_settings.events
    "click #project-config": (e) ->
      project_page_module.project_config_ui.show()

      return

    "click #register-project-for-daily-email": (e) ->
      e.stopPropagation()

      project_obj = curProj()

      project_obj.subscribeToDailyEmail(
        not project_obj.isSubscribedToDailyEmail())

    "click .email-notifications": (e) ->
      e.stopPropagation()

      project_obj = curProj()

      project_obj.subscribeToEmailNotifications(
        not project_obj.isSubscribedToEmailNotifications())

    "click .roles-and-groups-manager": ->
      APP.justdo_roles.openRolesAndGroupsManagerDialog()

      return

    "click .reset-default-views-columns": ->
      APP.custom_justdo_save_default_view?.resetUserViews()

      return

    "click .set-current-columns-structure-as-default": ->
      APP.custom_justdo_save_default_view?.saveCurrentViewAsDefaultViewForActiveProject()

      return

  Template.panes_controls.helpers
    isBottomPaneAvailable: -> not _.isEmpty APP.justdo_project_pane.getTabs()

    isBottomPaneOpen: -> APP.justdo_project_pane.isExpanded()

    isTaskPaneOpen: -> project_page_module.preferences.get()?.toolbar_open

    getTaskPanePosition: -> project_page_module.preferences.get()?.toolbar_position

  Template.panes_controls.events
    "click .task-pane-control": ->
      toolbar_open = project_page_module.preferences.get()?.toolbar_open

      project_page_module.updatePreferences({toolbar_open: not toolbar_open})

      return

    "click .bottom-pane-control": ->
      if APP.justdo_project_pane.isExpanded()
        APP.justdo_project_pane.collapse()
      else
        APP.justdo_project_pane.expand()

  Template.right_project_header.helpers
    rightHeaderTemplate: -> main_module.getCustomHeaderTemplate("right")

  Template.left_project_header.helpers
    leftHeaderTemplate: -> main_module.getCustomHeaderTemplate("left")
