_.extend JustdoJiraIntegration.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  isPluginInstalledOnProjectDoc: (project_doc) ->
    return APP.projects.isPluginInstalledOnProjectDoc(JustdoJiraIntegration.project_custom_feature_id, project_doc)

  getProjectDocIfPluginInstalled: (project_id) ->
    return @projects_collection.findOne({_id: project_id, "conf.custom_features": JustdoJiraIntegration.project_custom_feature_id})

  getJiraDocIdFromJustdoId: (justdo_id) ->
    check justdo_id, String
    if not (jira_doc_id = @projects_collection.findOne(justdo_id, {fields: {"conf.#{JustdoJiraIntegration.projects_collection_jira_doc_id}": 1}})?.conf?[JustdoJiraIntegration.projects_collection_jira_doc_id])?
      throw @_error "not-supported", "Justdo #{justdo_id} does not have a linked Jira doc"
    return jira_doc_id

  getJiraServerInfoFromJustdoId: (justdo_id) ->
    jira_doc_id = @getJiraDocIdFromJustdoId justdo_id
    return @jira_collection.findOne(jira_doc_id, {fields: {server_info: 1}})?.server_info

  getAuthTypeIfJiraInstanceIsOnPerm: ->
    if @server_type.includes "server"
      return @server_type.replace "server-", ""
    return

  isJiraInstanceCloud: ->
    return @server_type.includes "cloud"

  getIssueTypeRank: (issue_type, jira_project_id) ->
    # Default issue type rank:
    #   1: Epic
    #   0: Other non-subtask types
    #   -1: Subtask types

    if not issue_type? or not jira_project_id?
      return

    if issue_type is "Epic"
      return 1

    query =
      "jira_projects.#{jira_project_id}.issue_types.name": issue_type

    # Since minimongo doesn't support positional operator ($), we have seperate logic for client and server.
    if Meteor.isServer
      query_options =
        fields:
          "jira_projects.#{jira_project_id}.issue_types.$": 1
      issue_type_def = @jira_collection.findOne(query, query_options)?.jira_projects?[jira_project_id]?.issue_types?[0]

    if Meteor.isClient
      query_options =
        fields:
          "jira_projects.#{jira_project_id}.issue_types": 1
      issue_types = @jira_collection.findOne(query, query_options)?.jira_projects?[jira_project_id]?.issue_types
      issue_type_def = _.find issue_types, (issue_type_obj) -> issue_type_obj.name is issue_type

    if not issue_type_def?
      throw @_error "fatal", "Issue type not found"

    if issue_type_def.subtask
      return -1

    return 0

  getRankedIssueTypesInJiraProject: (jira_project_id) ->
    # Default issue type rank:
    #   1: Epic
    #   0: Other non-subtask types
    #   -1: Subtask types

    query =
      "jira_projects.#{jira_project_id}":
        $ne: null
    query_options =
      fields:
        "jira_projects.#{jira_project_id}.issue_types": 1

    ranked_issue_types =
      "1": []
      "0": []
      "-1": []

    @jira_collection.findOne(query, query_options)?.jira_projects?[jira_project_id]?.issue_types?.forEach (issue_type_def) ->
      rank = 0

      if issue_type_def.subtask
        rank = -1

      if issue_type_def.name is "Epic"
        rank = 1

      ranked_issue_types[rank].push issue_type_def
      return

    return ranked_issue_types
