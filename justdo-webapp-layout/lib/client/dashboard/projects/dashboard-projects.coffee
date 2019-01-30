APP.executeAfterAppLibCode ->
  Template.dashboard_projects.helpers
    projects: ->
      default_title = JustdoHelpers.getCollectionSchemaForField(APP.collections.Projects, "title")?.defaultValue

      projects = APP.collections.Projects.find({}, {sort: {createdAt: 1}}).fetch()

      modified_projects = _.map projects, (project) ->
        if not project.title? or project.title == ""
          project.title = default_title

        return project

      return modified_projects

  Template.dashboard_projects.events
    "click .create-project": ->
      APP.projects.createNewProject({}, (err, project_id) -> Router.go 'project', {_id: project_id})

  Template.dashboard_projects_project_card.onCreated ->
    data = Template.currentData()

    project_id = data._id

    @autorun =>
      # call(@) is used so subscribeProjectMembersInfo will use template.subscribe
      @members_subscription_comp =
        APP.helpers.subscribeProjectMembersInfo.call(@, project_id)

      @subscribe("requiredActions", project_id)

  Template.dashboard_projects_project_card.onDestroyed ->
    @members_subscription_comp?.stop()

  #
  # > dashboard_projects_project_card_members
  #

  Template.dashboard_projects_project_card_members.helpers
    box_grid:
      cols: 6

    primary_users: -> APP.projects.getAdminsIdsFromProjectDoc @

    secondary_users: -> APP.projects.getNonAdminsIdsFromProjectDoc @
