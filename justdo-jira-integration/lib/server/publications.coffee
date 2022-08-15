_.extend JustdoJiraIntegration.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "jiraCollection", (justdo_id) ->
      if not @userId
        @ready()

      check justdo_id, String

      jira_collection_query =
        justdo_ids: justdo_id
      jira_collection_query_options =
        fields:
          "justdo_ids.$": 1
          "server_info.url": 1
          "server_info.name": 1
          "server_info.avatarUrl": 1
          "jira_projects": 1
      return self.jira_collection.find jira_collection_query, jira_collection_query_options

    Meteor.publish "jiraMountpoints", (justdo_id) ->
      if not @userId
        @ready()

      check justdo_id, String

      query_options =
        fields:
          "justdo_jira_integration.mounted_tasks": 1

      return self.projects_collection.find justdo_id, query_options

    return
