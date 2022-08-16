jira_collection_server_info_schema = new SimpleSchema
  id:
    label: "Jira instance ID"
    type: String
    optional: true
  url:
    label: "URL to Jira instance"
    type: String
    optional: true
  name:
    label: "Name of Jira instance"
    type: String
    optional: true
  scopes:
    label: "Jira OAuth scopes"
    type: [String]
    optional: true
  avatarUrl:
    label: "Jira instance avatar URL"
    type: String
    optional: true

_.extend JustdoJiraIntegration.prototype,
  _attachCollectionsSchemas: ->
    tasks_collection_schema =
      jira_issue_key:
        label: "Jira issue key"
        type: String
        optional: true

      jira_issue_id:
        label: "Jira issue ID"
        type: String
        optional: true

      jira_project_id:
        label: "Jira project ID"
        type: String
        optional: true

      jira_last_updated:
        label: "Last updated to Jira"
        type: Date
        optional: true

      jira_issue_type:
        label: "Issue Type"
        type: String
        optional: true
        grid_editable_column: true
        grid_visible_column: true
        grid_column_filter_settings:
          type: "whitelist"
        grid_column_formatter: "keyValueFormatter"
        grid_column_editor: "SelectorEditor"
        grid_values:
          "Epic":
            txt: "Epic"
            order: 0
            due_list_state: true
            bg_color: "904ee2"

          "Story":
            txt: "Story"
            order: 1
            due_list_state: false
            bg_color: "63ba3b"

          "Task":
            txt: "Task"
            order: 2
            due_list_state: false
            bg_color: "4bade8"

          "Bug":
            txt: "Bug"
            order: 3
            due_list_state: false
            bg_color: "e54939"

          "Sub-task":
            txt: "Sub-Task"
            order: 4
            due_list_state: false
            bg_color: "B7E5FF"

      jira_issue_reporter:
        label: "Jira issue reporter"
        type: String
        optional: true

      # jira_sprint and jira_fix_version stores the sprint and fix version information of an issue
      jira_sprint:
        label: "Jira sprint"
        type: String
        optional: true
      jira_fix_version:
        label: "Jira fixed version"
        type: [String]
        optional: true

      # NOTE: Not to be confused with jira_sprint and jira_fix_version,
      # the following four fields are not required by any tasks that are created from Jira issues.
      # They are for the sprint/fix version mountpoints
      jira_sprint_mountpoint_id:
        label: "ID of Jira Sprint"
        type: Number
        optional: true
      jira_fix_version_mountpoint_id:
        label: "ID of Jira Fix Version"
        type: Number
        optional: true

      jira_story_point:
        label: "Story point"
        type: Number
        optional: true

      # These two is required in the task document level to support sprints updates only
      jira_project_key:
        label: "Jira project key"
        type: String
        optional: true
      jira_mountpoint_type:
        label: "Jira mountpoint type"
        type: String
        allowedValues: ["root", "sprints", "fix_versions", "roadmap"]
        optional: true

      "jrs:style":
        label: "Row style"
        type: Object
        blackbox: true
        optional: true
    @tasks_collection.attachSchema tasks_collection_schema

    projects_collection_schema =
      [JustdoJiraIntegration.projects_collection_jira_doc_id]:
        label: "ID of associated Jira document"
        type: String
        optional: true
    @projects_collection.attachSchema projects_collection_schema

    # The reason we have another collection and not using system-records is to be
    # future ready for multiple Jira connections per installation.
    jira_collection_schema =
      server_info:
        label: "Jira instance metadata"
        type: jira_collection_server_info_schema
        optional: true
      justdo_ids:
        label: "Justdo IDs that are associated to this Jira instance"
        type: [String]
        optional: true
      access_token:
        label: "Jira OAuth access token"
        type: String
        optional: true
      refresh_token:
        label: "Jira OAuth refresh token"
        type: String
        optional: true
      jira_projects:
        label: "Mounted Jira projects and their metadata"
        type: Object
        blackbox: true
        optional: true
    @jira_collection.attachSchema jira_collection_schema
    return
