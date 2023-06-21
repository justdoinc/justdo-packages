_.extend JustdoJiraIntegration.prototype,
  _setupPublications: ->
    self = @

    Meteor.publish "jiraCollection", (jira_doc_id) ->
      if not @userId
        return @ready()

      check jira_doc_id, String

      jira_collection_query_options =
        fields:
          "server_info.url": 1
          "server_info.name": 1
          "server_info.avatarUrl": 1
          "jira_projects": 1
      return self.jira_collection.find jira_doc_id, jira_collection_query_options

    Meteor.publish "jiraCoreFieldIds", ->
      if not @userId
        return @ready()

      query =
        "members.user_id": @userId
        "conf.#{JustdoJiraIntegration.projects_collection_jira_doc_id}":
          $ne: null

      # User has to be member of one linked jira project to see the field id
      if not self.projects_collection.findOne(query, {fields: {_id: 1}})?
        return @ready()

      query = "jira-core-field-ids"
      query_options =
        fields:
          "fields.sprint": 1

      return APP.collections.SystemRecords.find query, query_options

    return
