_.extend JustdoJiraIntegration.prototype,
  getOAuth1LoginLink: (justdo_id, cb) ->
    Meteor.call "jiraGetOAuth1LoginLink", justdo_id, cb
    return

  getOAuth2LoginLink: (justdo_id, cb) ->
    Meteor.call "jiraGetOAuth2LoginLink", justdo_id, cb
    return

  getAvailableJiraProjects: (justdo_id, cb) ->
    Meteor.call "getAvailableJiraProjects", justdo_id, cb
    return

  mountTaskWithJiraProject: (task_id, jira_project_key, jira_project_id, cb) ->
    Meteor.call "mountTaskWithJiraProject", task_id, jira_project_key, jira_project_id, cb
    return

  unmountTaskWithJiraProject: (justdo_id, jira_project_key, cb) ->
    Meteor.call "unmountTaskWithJiraProject", justdo_id, jira_project_key, cb
    return
