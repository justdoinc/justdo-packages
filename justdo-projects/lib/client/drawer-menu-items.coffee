DrawerProjectsControllerOptionsSchema = new SimpleSchema
  projects_query:
    type: Object
    blackbox: true
    optional: true
    # Note: The default value returns a function that calls and returns the value of getActiveOrgId
    defaultValue: {}

Projects.DrawerProjectsController = (options) ->
  EventEmitter.call this

  if not options?
    options = {}

  {cleaned_val} =
    JustdoHelpers.simpleSchemaCleanAndValidate(
      DrawerProjectsControllerOptionsSchema,
      options,
      {self: @, throw_on_error: true}
    )

  @projects_query_rv = new ReactiveVar cleaned_val.projects_query

  return @

Util.inherits Projects.DrawerProjectsController, EventEmitter

_.extend Projects.DrawerProjectsController.prototype,
  getProjectsQuery: -> @projects_query_rv.get()

  setProjectsQuery: (query) -> @projects_query_rv.set query

  projects: ->
    query_options =
      fields:
        _id: 1
        title: 1
      sort:
        createdAt: 1

    return APP.collections.Projects.find(@projects_query_rv.get(), {fields: {_id: 1, title: 1}, sort: {createdAt: 1}}).fetch()

_.extend Projects.prototype,
  _registerDrawerPlaceholders: ->
    APP.executeAfterAppLibCode =>
      JD.registerPlaceholderItem "create-new-project-icon",
        data:
          html: """<svg class="create-new-project text-primary"><use xlink:href="/layout/icons-feather-sprite.svg#jd-create"/></svg>"""
        domain: "drawer-header"
        position: 1

      @drawer_projects_list_controller = new Projects.DrawerProjectsController()
      JD.registerPlaceholderItem "projects-list",
        data:
          template: "drawer_projects"
          template_data:
            controller: @drawer_projects_list_controller
        domain: "drawer-body"
        position: 1

    return
