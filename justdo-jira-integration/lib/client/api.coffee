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

  setupCustomFeatureMaintainer: ->
    self = @
    refresh_subscription_computation = null

    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoJiraIntegration.project_custom_feature_id,
        installer: =>
          refresh_subscription_computation = Tracker.autorun ->
            if not (active_justdo = APP.modules.project_page.curProj())?
              return

            # Refresh subscription upon switching Justdo
            self.jira_collection_subscription?.stop?()
            if (jira_doc_id = active_justdo.getProjectConfigurationSetting(JustdoJiraIntegration.projects_collection_jira_doc_id))?
              self.jira_collection_subscription = Meteor.subscribe "jiraCollection", jira_doc_id
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
            label: "Story Point"
            field_type: "number"
            grid_visible_column: true
            grid_editable_column: true
            default_width: 100
          self.registered_pseudo_custom_fields.push "jira_story_point"

          return

        destroyer: =>
          APP.modules.project_page.removePseudoCustomFields self.registered_pseudo_custom_fields
          refresh_subscription_computation?.stop?()

          return

    @onDestroy =>
      custom_feature_maintainer.stop()
      return

    return
