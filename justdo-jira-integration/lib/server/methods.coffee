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

      mountTaskWithJiraProject: (task_id, jira_project_id) ->
        check task_id, String
        check jira_project_id, Number
        check @userId, String
        return self.mountTaskWithJiraProject task_id, jira_project_id, @userId

      unmountTaskWithJiraProject: (justdo_id, jira_project_id) ->
        check justdo_id, String
        check jira_project_id, Number
        check @userId, String
        return self.unmountTaskWithJiraProject justdo_id, jira_project_id, @userId

      isJustdoMountedWithJiraProject: (justdo_id) ->
        check justdo_id, String
        return self.isJustdoMountedWithJiraProject justdo_id

      getJiraFieldDef: (jira_doc_id) ->
        check jira_doc_id, String
        return self.getJiraFieldDef jira_doc_id

      getJiraFieldDefByJiraProjectId: (jira_doc_id, jira_project_id) ->
        check jira_doc_id, String
        check jira_project_id, Number
        return self.getJiraFieldDefByJiraProjectId jira_doc_id, jira_project_id

      addCustomFieldPairs: (jira_doc_id, jira_project_id, field_map) ->
        check jira_doc_id, String
        check jira_project_id, Number
        # field_map is checked inside addCustomFieldPairs()
        check @userId, String
        return self.addCustomFieldPairs jira_doc_id, jira_project_id, field_map, @userId

      deleteCustomFieldPair: (justdo_id, jira_project_id, custom_field_pair_id) ->
        check justdo_id, String
        check jira_project_id, Number
        check custom_field_pair_id, String
        check @userId, String

        return self.deleteCustomFieldPair justdo_id, jira_project_id, custom_field_pair_id, @userId
