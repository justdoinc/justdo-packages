APP.executeAfterAppLibCode ->
  Template.dashboard_projects.onCreated ->
    @projects_search_input_rv = new ReactiveVar null

    return

  Template.dashboard_projects.onRendered ->
    $(".dashboard-search-input").focus()

    return

  Template.dashboard_projects.helpers
    projects: ->
      projects_search_input_rv = Template.instance().projects_search_input_rv.get()
      default_title = JustdoHelpers.getCollectionSchemaForField(APP.collections.Projects, "title")?.defaultValue

      projects = APP.collections.Projects.find({}, {sort: {createdAt: 1}}).fetch()

      modified_projects = _.map projects, (project) ->
        if not project.title? or project.title == ""
          project.title = default_title

        return project

      if not projects_search_input_rv?
        return modified_projects

      filter_regexp = new RegExp("\\b#{JustdoHelpers.escapeRegExp(projects_search_input_rv)}", "i")

      modified_projects = _.filter modified_projects, (doc) ->
        if filter_regexp.test(doc.title)
          return true
        return false

      return modified_projects

  Template.dashboard_projects.events
    "click .create-project": ->
      APP.projects.createNewProject({}, (err, project_id) -> Router.go 'project', {_id: project_id})

      return

    "keyup .dashboard-search-input": (e, tpl) ->
      value = $(e.target).val().trim()

      if _.isEmpty value
        tpl.projects_search_input_rv.set null

      tpl.projects_search_input_rv.set value

      return

  Template.dashboard_projects_project_card.onCreated ->

    data = Template.currentData()

    project_id = data._id

    @autorun =>
      # call(@) is used so subscribeProjectMembersInfo will use template.subscribe
      @members_subscription_comp =
        APP.helpers.subscribeProjectMembersInfo.call(@, project_id)

    return

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
