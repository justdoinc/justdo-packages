_.extend JustdoJiraIntegration.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @registered_pseudo_custom_fields = []
    @registerConfigTemplate()
    @registerTaskPaneSection()
    @setupCustomFeatureMaintainer()

    return

  setupIssueTypeCustomField: (jira_doc_id) ->
    default_issue_types =
      epics: [
        option_id: "Epic"
        label: "Epic"
        bg_color: "904ee2"
      ]
      standard_issue_types: [
        option_id: "Story"
        label: "Story"
        bg_color: "63ba3b"
      ,
        option_id: "Task"
        label: "Task"
        bg_color: "4bade8"
      ,
        option_id: "Bug"
        label: "Bug"
        bg_color: "e54939"
      ]
      subtasks: []

    if (jira_projects = @jira_collection.findOne(jira_doc_id, {fields: {jira_projects: 1}})?.jira_projects)?
      for jira_project_id, jira_project of jira_projects
        for issue_type in jira_project.issue_types
          issue_type_group = "standard_issue_types"
          issue_bg_color_tag = "task"
          if issue_type.subtask
            issue_type_group = "subtasks"
            issue_bg_color_tag = "subtask"

          issue_type_name = issue_type.name
          
          if issue_type_name is "Epic"
            continue
          if _.find default_issue_types[issue_type_group], (option_def) -> option_def.label is issue_type_name
            continue

          default_issue_types[issue_type_group].push
            option_id: issue_type_name
            label: issue_type_name
            bg_color: JustdoJiraIntegration.default_issue_type_colors[issue_bg_color_tag]

    issue_types = [].concat(default_issue_types.epics).concat(default_issue_types.standard_issue_types).concat(default_issue_types.subtasks)

    APP.modules.project_page.setupPseudoCustomField "jira_issue_type",
      label: "Issue Type"
      field_type: "select"
      grid_visible_column: true
      grid_editable_column: true
      field_options:
        select_options: issue_types

    return

  setupCustomFeatureMaintainer: ->
    self = @
    refresh_subscription_computation = null
    gcm = null

    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoJiraIntegration.project_custom_feature_id,
        installer: =>
          refresh_subscription_computation = Tracker.autorun ->
            # Refresh subscription upon switching Justdo
            self.jira_collection_subscription?.stop?()
            gcm?.off? "edit-failed"
            APP.modules.project_page.removePseudoCustomFields "jira_issue_type"

            if not (active_justdo = APP.modules.project_page.curProj())?
              return

            if (jira_doc_id = active_justdo.getProjectConfigurationSetting(JustdoJiraIntegration.projects_collection_jira_doc_id))?
              self.jira_collection_subscription = Meteor.subscribe "jiraCollection", jira_doc_id

              # Register gcm error handler (show snackbar on error)
              gcm = APP.modules.project_page.grid_control_mux.get()
              gcm?.on? "edit-failed", (tab, err) ->
                if err.error isnt "jira-update-failed"
                  return

                err_msg = err.reason

                if (err_details = err.details)?
                  if not _.isEmpty err_details.errorMessages
                    extra_err_msg = err_details.errorMessages.join "<br>"
                  else
                    extra_err_msg = _.values(err_details.errors)?.join "<br>"

                if extra_err_msg?
                  err_msg = "#{err_msg}<br>#{extra_err_msg}"

                console.log err
                JustdoSnackbar.show
                  text: err_msg
                return

              Tracker.nonreactive -> self.setupIssueTypeCustomField jira_doc_id
            return

          APP.modules.project_page.setupPseudoCustomField "jira_issue_key",
            label: "Issue Key"
            field_type: "string"
            grid_visible_column: true
            grid_editable_column: false
            default_width: 100
          self.registered_pseudo_custom_fields.push "jira_issue_key"

          APP.modules.project_page.setupPseudoCustomField "jira_issue_type",
            label: "Issue Type"
            field_type: "select"
            grid_visible_column: true
            grid_editable_column: true
            field_options:
              select_options: [
                option_id: "Epic"
                label: "Epic"
                bg_color: "904ee2"
              ,
                option_id: "Story"
                label: "Story"
                bg_color: "63ba3b"
              ,
                option_id: "Task"
                label: "Task"
                bg_color: "4bade8"
              ,
                option_id: "Bug"
                label: "Bug"
                bg_color: "e54939"
              ,
                option_id: "Sub-task"
                label: "Sub-Task"
                bg_color: "B7E5FF"
              ]
          self.registered_pseudo_custom_fields.push "jira_issue_type"

          APP.modules.project_page.setupPseudoCustomField "jira_fix_version",
            label: "Fix Versions"
            field_type: "strings_array"
            grid_visible_column: true
            grid_editable_column: false
            grid_dependencies_fields: ["jira_fix_version"]
            client_only: true
            filter_type: "whitelist"
            filter_options:
              filter_values: ->
                if not (mounted_jira_project_metadata = self.jira_collection.findOne({}, {fields: {jira_projects: 1}})?.jira_projects)?
                  return {}

                index = 0
                all_fix_versions_under_current_justdo = {}
                for jira_project_key, jira_project_metadata of mounted_jira_project_metadata
                  for fix_version in jira_project_metadata.fix_versions
                    fix_version_name = fix_version.name
                    if all_fix_versions_under_current_justdo[fix_version_name]?
                      continue

                    all_fix_versions_under_current_justdo[fix_version_name] =
                      txt: fix_version_name
                      order: index
                      customFilterQuery: (filter_state_id, column_state_definitions, context) -> {jira_fix_version: filter_state_id}

                    index += 1

                return all_fix_versions_under_current_justdo
            default_width: 100
          self.registered_pseudo_custom_fields.push "jira_fix_version"

          APP.modules.project_page.setupPseudoCustomField "jira_sprint",
            label: "Jira Sprint"
            field_type: "string"
            grid_visible_column: true
            grid_editable_column: false
            grid_dependencies_fields: ["jira_sprint"]
            client_only: true
            filter_type: "whitelist"
            filter_options:
              filter_values: ->
                if not (mounted_jira_project_metadata = self.jira_collection.findOne({}, {fields: {jira_projects: 1}})?.jira_projects)?
                  return {}

                index = 0
                all_sprints_under_current_justdo = {}
                for jira_project_key, jira_project_metadata of mounted_jira_project_metadata
                  for sprint in jira_project_metadata.sprints
                    sprint_name = sprint.name
                    if all_sprints_under_current_justdo[sprint_name]?
                      continue

                    all_sprints_under_current_justdo[sprint_name] =
                      txt: sprint_name
                      order: index
                      customFilterQuery: (filter_state_id, column_state_definitions, context) -> {jira_sprint: filter_state_id}

                    index += 1

                return all_sprints_under_current_justdo
            default_width: 100
          self.registered_pseudo_custom_fields.push "jira_sprint"

          APP.modules.project_page.setupPseudoCustomField "jira_story_point",
            label: "Story Points"
            field_type: "number"
            grid_visible_column: true
            grid_editable_column: true
            default_width: 100
          self.registered_pseudo_custom_fields.push "jira_story_point"

          return

        destroyer: =>
          self.registered_pseudo_custom_fields.push "jira_issue_type"
          APP.modules.project_page.removePseudoCustomFields self.registered_pseudo_custom_fields
          refresh_subscription_computation?.stop?()
          self.jira_collection_subscription?.stop?()
          gcm?.off? "edit-failed"

          return

    @onDestroy =>
      custom_feature_maintainer.stop()
      return

    return
