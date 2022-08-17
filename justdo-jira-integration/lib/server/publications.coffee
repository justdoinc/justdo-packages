_.extend JustdoJiraIntegration.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "jiraCollection", (justdo_id) ->
      if not @userId
        @ready()

      check justdo_id, String

      jira_doc_id = self.projects_collection.findOne(justdo_id, {fields: {[JustdoJiraIntegration.projects_collection_jira_doc_id]: 1}})?[JustdoJiraIntegration.projects_collection_jira_doc_id]

      jira_collection_query_options =
        fields:
          "server_info.url": 1
          "server_info.name": 1
          "server_info.avatarUrl": 1
          "jira_projects": 1
      return self.jira_collection.find jira_doc_id, jira_collection_query_options

    Meteor.publish "projectsCollectionJiraDocId", (justdo_id) ->
      if not @userId
        @ready()

      check justdo_id, String

      query_options =
        fields:
          [JustdoJiraIntegration.projects_collection_jira_doc_id]: 1

      return self.projects_collection.find justdo_id, query_options

    return
