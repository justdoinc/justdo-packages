# data_integrity_check_rate_ms = 1000 * 60 * 5 # 5 mins
data_integrity_check_rate_ms = 1000 * 60


_.extend JustdoJiraIntegration,
  access_token_update_rate_ms: 1000 * 60 * 50  # 50 mins
  webhook_connection_check_rate_ms: 1000 * 60 # 1 min
  data_integrity_check_rate_ms: data_integrity_check_rate_ms
  data_integrity_margin_of_safety: data_integrity_check_rate_ms / 5
  data_integrity_check_timeout: data_integrity_check_rate_ms / 2
  jql_issue_search_results_limit: 1000000 # Unlimited for now
  jira_issue_hierarchy_levels: 3 # Default: Epic-Story/Task/Bug-Subtask
