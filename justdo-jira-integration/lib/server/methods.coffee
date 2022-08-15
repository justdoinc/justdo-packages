_.extend JustdoJiraIntegration.prototype,
  _setupMethods: ->
    self = @

    Meteor.methods
      jiraGetOAuth1LoginLink: (justdo_id) ->
        check justdo_id, String
        check @userId, String
        return self.getOAuth1LoginLink justdo_id, @userId

      jiraGetOAuth2LoginLink: (justdo_id) ->
        check justdo_id, String
        check @userId, String
        return self.getOAuth2LoginLink justdo_id, @userId

      getAvailableJiraProjects: (justdo_id) ->
        check justdo_id, String
        check @userId, String
        return self.getAvailableJiraProjects justdo_id, @userId

      mountTaskWithJiraProject: (task_id, jira_project_key, jira_project_id) ->
        check task_id, String
        check jira_project_key, String
        check @userId, String
        return self.mountTaskWithJiraProject task_id, jira_project_key, jira_project_id, @userId

      unmountTaskWithJiraProject: (justdo_id, jira_project_key) ->
        check justdo_id, String
        check jira_project_key, String
        check @userId, String
        return self.unmountTaskWithJiraProject justdo_id, jira_project_key, @userId
