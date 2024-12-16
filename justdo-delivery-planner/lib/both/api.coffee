_.extend JustdoDeliveryPlanner.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @setupRouter()
    @_setupCustomFeatures()

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  _getProjectRelevantFieldsProjection: ->
    fields =
      _id: 1
      project_id: 1
      users: 1
      start_date: 1
      "#{JustdoDeliveryPlanner.task_is_project_field_name}": 1
      "#{JustdoDeliveryPlanner.task_is_archived_project_field_name}": 1
      "#{JustdoDeliveryPlanner.task_project_members_availability_field_name}": 1
      "#{JustdoDeliveryPlanner.task_base_project_workdays_field_name}": 1
      "#{JustdoDeliveryPlanner.task_baseline_projection_data_field_name}": 1
      "#{JustdoDeliveryPlanner.task_is_committed_field_name}": 1

    return fields

  isTaskObjProject: (item_obj) ->
    return item_obj?[JustdoDeliveryPlanner.task_is_project_field_name]? and item_obj[JustdoDeliveryPlanner.task_is_project_field_name]

  isTaskObjArchivedProject: (item_obj) ->
    return item_obj[JustdoDeliveryPlanner.task_is_archived_project_field_name]? and item_obj[JustdoDeliveryPlanner.task_is_archived_project_field_name]

  toggleTaskArchivedProjectState: (item_id) ->
    if not (item_obj = @tasks_collection.findOne(item_id))?
      console.warn "Unknown task #{item_id}"

      return

    task_obj_is_archived_project = @isTaskObjArchivedProject(item_obj)

    new_state = not task_obj_is_archived_project

    @tasks_collection.update(item_id, {$set: {"#{JustdoDeliveryPlanner.task_is_archived_project_field_name}": new_state}})

    return new_state

  getKnownProjects: (project_id, options, user_id) ->
    # Get all the active projects known to

    if not user_id?
      return []

    check user_id, String

    default_options =
      active_only: false
      fields:
        _id: 1
        seqId: 1
        title: 1
        "#{JustdoDeliveryPlanner.task_is_archived_project_field_name}": 1
      sort_by: {seqId: -1}

      exclude_tasks: null

      customize_query: {}

    options = _.extend default_options, options

    query = _.extend {
      "#{JustdoDeliveryPlanner.task_is_project_field_name}": true
      project_id: project_id
      users: user_id
    }, options.customize_query

    if Meteor.isClient
      # In the client-side Tasks docs don't have the users field.
      delete query.users

    if (exclude_tasks = options.exclude_tasks)?
      if _.isString exclude_tasks
        exclude_tasks = [exclude_tasks]

      query._id = {$nin: exclude_tasks}

    if options.active_only
      query[JustdoDeliveryPlanner.task_is_archived_project_field_name] = {$ne: true}

    return @tasks_collection.find(query, {fields: options.fields, sort: options.sort_by}).fetch()

  isProjectsCollectionEnabled: -> JustdoDeliveryPlanner.is_projects_collection_enabled

  isTaskObjProjectsCollection: (task_obj) ->
    return task_obj?.projects_collection?.is_projects_collection is true
  
  isProjectsCollectionClosed: (task_obj) ->
    if not @isTaskObjProjectsCollection task_obj
      return false
    
    return task_obj?.projects_collection?.is_closed

  _setupCustomFeatures: ->
    if not @isProjectsCollectionEnabled()
      return

    @_setupTaskType()

    if Meteor.isClient
      @_setupContextmenu()
        
    return

  _setupTaskType: ->
    self = @
    
    tags_properties =
      "is_projects_collection":
        text: TAPi18n.__ JustdoDeliveryPlanner.projects_collection_term_i18n, {}, JustdoI18n.default_lang
        text_i18n: JustdoDeliveryPlanner.projects_collection_term_i18n

        filter_list_order: 15

        customFilterQuery: (filter_state_id, column_state_definitions, context) ->
          return {"projects_collection.is_projects_collection": true}

    APP.justdo_task_type.registerTaskTypesGenerator "default", "is-projects-collection",
      possible_tags: ["is_projects_collection"]

      required_task_fields_to_determine:
        "projects_collection": 1

      generator: (task_obj) ->
        tags = []

        if self.isTaskObjProjectsCollection task_obj
          tags.push "is_projects_collection"

        return tags

      propertiesGenerator: (tag) -> tags_properties[tag]

    return

  getAllProjectsCollectionsUnderJustdoOptionsSchema: new SimpleSchema
    include_closed:
      type: Boolean
      optional: true
      defaultValue: false
    fields:
      type: Object
      optional: true
      blackbox: true
      defaultValue: JustdoDeliveryPlanner.projects_collection_default_fields_to_fetch
  getAllProjectsCollectionsUnderJustdo: (justdo_id, options, user_id) ->
    check justdo_id, String
    if not user_id?
      user_id = Meteor.userId()
    check user_id, String

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @getAllProjectsCollectionsUnderJustdoOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    query = 
      project_id: justdo_id
      users: user_id
      "projects_collection.is_projects_collection": true
      "projects_collection.is_closed": 
        $ne: true
    if options.include_closed
      delete query["projects_collection.is_closed"]
    
    query_options = 
      fields: options.fields
      
    return @tasks_collection.find(query, query_options).fetch()

  getProjectsUnderCollectionCursorOptionsSchema: new SimpleSchema
    include_closed:
      type: Boolean
      optional: true
      defaultValue: false
    fields:
      type: Object
      optional: true
      blackbox: true
      defaultValue: JustdoDeliveryPlanner.projects_collection_default_fields_to_fetch
  getProjectsUnderCollectionCursor: (justdo_id, projects_collection_id, options, user_id) ->
    check justdo_id, String
    check projects_collection_id, String
    if not user_id?
      user_id = Meteor.userId()
    check user_id, String

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @getProjectsUnderCollectionCursorOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    query = 
      project_id: justdo_id
      users: user_id
      [JustdoDeliveryPlanner.task_is_archived_project_field_name]: false
    
    if Meteor.isServer
      query["parents2.parent"] = projects_collection_id
    if Meteor.isClient
      query["parents.#{projects_collection_id}"] = {$exists: true}
    
    if options.include_closed
      delete query[JustdoDeliveryPlanner.task_is_archived_project_field_name]
      
    query_options = 
      fields: options.fields
    
    return @tasks_collection.find(query, query_options)
  
  getProjectsCollectionOfProjectCursorOptionsSchema: new SimpleSchema
    include_closed:
      type: Boolean
      optional: true
      defaultValue: false
    fields:
      type: Object
      optional: true
      blackbox: true
      defaultValue: JustdoDeliveryPlanner.projects_collection_default_fields_to_fetch
  getProjectsCollectionOfProjectCursor: (justdo_id, project_id, options, user_id) ->
    check justdo_id, String
    check project_id, String
    if not user_id?
      user_id = Meteor.userId()
    check user_id, String

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @getProjectsCollectionOfProjectCursorOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    get_project_parents_query = 
      project_id: justdo_id
      _id: project_id
      users: user_id
    get_project_parents_query_options =
      fields: {}
    if Meteor.isServer
      get_project_parents_query_options.fields["parents2.parent"] = 1
      project_parent_ids = @tasks_collection.findOne(get_project_parents_query, get_project_parents_query_options)?.parents2?.map (parent) -> parent.parent
    if Meteor.isClient
      get_project_parents_query_options.fields.parents = 1
      project_parent_ids = _.keys @tasks_collection.findOne(get_project_parents_query, get_project_parents_query_options)?.parents

    get_parent_project_collections_query = 
      project_id: justdo_id
      users: user_id
      _id: 
        $in: project_parent_ids
      "projects_collection.is_projects_collection": true
      "projects_collection.is_closed": false
    if options.include_closed
      delete get_parent_project_collections_query["projects_collection.is_closed"]

    get_parent_project_collections_query_options =
      fields: options.fields    
    return @tasks_collection.find(get_parent_project_collections_query, get_parent_project_collections_query_options)
