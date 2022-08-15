_.extend JustdoJiraIntegration.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    refresh_subscription_computation = Tracker.autorun =>
      if not (justdo_id = JD.activeJustdoId())?
        return

      # Refresh subscription upon switching Justdo
      @jira_collection_subscription?.stop?()
      @jira_collection_subscription = Meteor.subscribe "jiraCollection", justdo_id

      @justdo_mountpoints_subscription?.stop?()
      @justdo_mountpoints_subscription = Meteor.subscribe "jiraMountpoints", justdo_id

    @registered_pseudo_custom_fields = []
    @registerConfigTemplate()
    @registerTaskPaneSection()
    @setupCustomFeatureMaintainer()

    return

  setupCustomFeatureMaintainer: ->
    self = @

    custom_feature_maintainer =
      APP.modules.project_page.setupProjectCustomFeatureOnProjectPage JustdoJiraIntegration.project_custom_feature_id,
        installer: =>

          APP.modules.project_page.setupPseudoCustomField "jira_issue_key",
            label: "Issue Key"
            field_type: "string"
            grid_visible_column: true
            grid_editable_column: false
            default_width: 100
          self.registered_pseudo_custom_fields.push "jira_issue_key"

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

          return

    @onDestroy =>
      custom_feature_maintainer.stop()
      self.refresh_subscription_computation?.stop?()

      return

    return
