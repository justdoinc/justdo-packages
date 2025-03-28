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
  tasks_collection_schema:
    jira_issue_key:
      label: "Jira Issue key"
      type: String
      optional: true

    jira_issue_id:
      label: "Jira Issue ID"
      type: Number
      optional: true

    jira_project_id:
      label: "Jira Project ID"
      type: Number
      optional: true

    jira_last_updated:
      label: "Last Updated to Jira"
      type: Date
      optional: true

    jira_issue_type:
      label: "Issue Type"
      type: String
      optional: true

    jira_issue_reporter:
      label: "Jira Issue Reporter"
      type: String
      optional: true

      grid_visible_column: false
      user_editable_column: false

    # jira_sprint and jira_fix_version stores the sprint and fix version information of an issue
    jira_sprint:
      label: "Jira Sprint"
      type: String
      optional: true

    jira_fix_version:
      label: "Fix Versions"
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
      label: "Story Point"
      type: Number
      optional: true

    # These two is required in the task document level to support sprints updates only
    jira_project_key:
      label: "Jira Project Key"
      type: String
      optional: true
    jira_mountpoint_type:
      label: "Jira Mountpoint Type"
      type: String
      allowedValues: ["root", "sprints", "fix_versions", "roadmap"]
      optional: true

    "jrs:style":
      label: "Row Style"
      type: Object
      blackbox: true
      optional: true

 _.extend JustdoJiraIntegration.prototype,
  _attachCollectionsSchemas: ->
    # attachSchema() will modifty tasks_collection_schema, hence the _.extend()
    # We keep the integrity of tasks_collection_schema since its keys will be used in the unmounting process,
    # to unset all the fields specified in the schema.
    @tasks_collection.attachSchema(_.extend {}, @tasks_collection_schema)

    # The reason we have another collection and not using system-records is to be
    # future ready for multiple Jira connections per installation.
    jira_collection_schema =
      server_info:
        label: "Jira instance metadata"
        type: jira_collection_server_info_schema
        optional: true
      access_token:
        label: "Jira OAuth access token"
        type: String
        optional: true
      access_token_updated:
        label: "Time of last access token update"
        type: Date
        optional: true
      refresh_token:
        label: "Jira OAuth refresh token"
        type: String
        optional: true
      refresh_token_updated:
        label: "Time of last refresh token update"
        type: Date
        optional: true
      token_secret:
        label: "Token secret for OAuth 1"
        type: String
        optional: true
      jira_projects:
        label: "Mounted Jira projects and their metadata"
        type: Object
        blackbox: true
        optional: true
      last_webhook_connection_check:
        label: "Time of last API client and webhook connection check"
        type: Date
        optional: true
      last_data_integrity_check:
        label: "Time of last issue data consistency check"
        type: Date
        optional: true
      jira_users:
        label: "Jira users"
        type: Array
        optional: true
      "jira_users.$":
        label: "Jira user"
        type: Object
        optional: true
        blackbox: true
    @jira_collection.attachSchema jira_collection_schema
    return
