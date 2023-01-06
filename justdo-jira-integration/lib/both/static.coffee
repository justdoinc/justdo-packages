# XXX Hardcoded for now
sprint_custom_field_id = "customfield_10020"
jira_cloud_client_id_regex_token = "(\\d|[a-z]|[A-Z])"

_.extend JustdoJiraIntegration,
  project_custom_feature_id: "justdo_jira_integration" # Use underscores

  plugin_human_readable_name: "Jira Integration"

  task_pane_tab_label: "Jira"

  custom_page_label: "Jira Integration"

  projects_collection_jira_doc_id: "justdo_jira:id"

  # Client id of a Jira cloud instance looks like this: 11223344-a1b2-3b33-c444-def123456789
  jira_cloud_client_id_regex: new RegExp "#{jira_cloud_client_id_regex_token}{8}-(#{jira_cloud_client_id_regex_token}{4}-){3}#{jira_cloud_client_id_regex_token}{12}"

  default_issue_type_colors:
    epic: "904ee2"
    story: "63ba3b"
    task: "4bade8"
    bug: "e54939"
    subtask: "B7E5FF"

  hardcoded_field_map: [
    justdo_field_id: "title"
    justdo_field_name: "Title"
    jira_field_id: "summary"
    jira_field_name: "Summary"
  ,
    justdo_field_id: "description"
    justdo_field_name: "Description"
    jira_field_id: "description"
    jira_field_name: "Description"
  ,
    justdo_field_id: "state"
    justdo_field_name: "State"
    jira_field_id: "status"
    jira_field_name: "Status"
  ,
    justdo_field_id: "jira_issue_type"
    justdo_field_name: "Issue Type"
    jira_field_id: "issuetype"
    jira_field_name: "Issue Type"
  ,
    justdo_field_id: "owner_id"
    justdo_field_name: "Owner"
    jira_field_id: "assignee"
    jira_field_name: "Assignee"
  ,
    justdo_field_id: "jira_sprint"
    justdo_field_name: "Jira Sprint"
    jira_field_id: sprint_custom_field_id
    jira_field_name: "Sprint"
  ,
    justdo_field_id: "jira_fix_version"
    justdo_field_name: "Fix Versions"
    jira_field_id: "fixVersions"
    jira_field_name: "Fix Versions"
  ]
