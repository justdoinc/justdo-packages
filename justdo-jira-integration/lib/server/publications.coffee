_.extend JustdoJiraIntegration.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "jiraCollection", (jira_doc_id) ->
      if not @userId
        @ready()

      check jira_doc_id, String

      jira_collection_query_options =
        fields:
          "server_info.url": 1
          "server_info.name": 1
          "server_info.avatarUrl": 1
          "jira_projects": 1
      return self.jira_collection.find jira_doc_id, jira_collection_query_options

    return
