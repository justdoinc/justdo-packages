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

  mountTaskWithJiraProject: (task_id, jira_project_id, cb) ->
    if _.isString jira_project_id
      jira_project_id = parseInt jira_project_id, 10
    Meteor.call "mountTaskWithJiraProject", task_id, jira_project_id, cb
    return

  unmountTaskWithJiraProject: (justdo_id, jira_project_id, cb) ->
    if _.isString jira_project_id
      jira_project_id = parseInt jira_project_id, 10
    Meteor.call "unmountTaskWithJiraProject", justdo_id, jira_project_id, cb
    return

  isJustdoMountedWithJiraProject: (justdo_id, cb) ->
    Meteor.call "isJustdoMountedWithJiraProject", justdo_id, cb
    return
