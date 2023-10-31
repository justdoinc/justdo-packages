_.extend JustdoJiraIntegration.prototype,
  registerConfigTemplate: ->
    APP.executeAfterAppClientCode ->
      project_page_module = APP.modules.project_page
      project_page_module.project_config_ui.registerConfigTemplate "justdo_jira_integration_project_config",
        section: "extensions"
        template: "justdo_jira_integration_project_config"
        priority: 100

    return

module_id = JustdoJiraIntegration.project_custom_feature_id

curProj = -> APP.modules.project_page.curProj()

Template.justdo_jira_integration_project_config.helpers
  isModuleEnabled: ->
    return curProj().isCustomFeatureEnabled(module_id)

  pluginName: ->
    return JustdoJiraIntegration.plugin_human_readable_name

Template.justdo_jira_integration_project_config.events
  "click .jd-icon-extension": ->
    proj = curProj()

    if proj.isCustomFeatureEnabled(module_id)
      APP.justdo_jira_integration.isJustdoMountedWithJiraProject JD.activeJustdoId(), (err, is_mounted) ->
        if err?
          console.error err
        if is_mounted
          JustdoSnackbar.show
            text: "This JustDo has an active Jira mountpoint. Please unmount before disabling this plugin."
            duration: 10000
        else
          curProj().disableCustomFeatures(module_id)
        return
    else
      curProj().enableCustomFeatures(module_id)

  "click .settings-btn": ->
    message_template = JustdoHelpers.renderTemplateInNewNode(Template.justdo_jira_integration_project_setting)

    dialog = bootbox.dialog
      title: "Configure Jira Integration"
      message: message_template.node
      animate: true
      className: "bootbox-new-design bootbox-jira-config"
      scrollable: true

      onEscape: ->
        return true

      buttons:
        # Test:
        #   label: "Test"
        #   className: "btn-primary"
        #   callback: =>
        #     return false

        Save:
          label: "Close"
          className: "btn-primary jira-connectivity-configuration-save-and-close"
          callback: =>
            return true
    return
