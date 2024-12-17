_.extend JustdoDeliveryPlanner.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @setupRouter()
    if @isProjectsCollectionEnabled()
      @_setupProjectsCollectionFeatures()

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
  
  getSupportedProjectsCollectionTypes: -> JustdoDeliveryPlanner.projects_collections_types

  getProjectsCollectionTypeById: (type_id) ->
    if not type_id?
      return

    return _.find @getSupportedProjectsCollectionTypes(), (type) -> type.type_id is type_id

  getTaskObjProjectsCollectionTypeId: (task_obj) ->
    return  task_obj?.projects_collection?.projects_collection_type

  isProjectsCollectionClosed: (task_obj) ->
    if not @getTaskObjProjectsCollectionTypeId(task_obj)?
      return false
    
    return task_obj?.projects_collection?.is_closed

  _setupProjectsCollectionFeatures: ->
    @_setupProjectsCollectionTaskType()

    if Meteor.isClient
      @_setupProjectsCollectionContextmenu()
        
    return

  _setupProjectsCollectionTaskType: ->
    closed_project_collection_prefix = "closed_"
    self = @

    APP.justdo_task_type.registerTaskTypesGenerator "default", "projects-collection-type",
      possible_tags: _.map self.getSupportedProjectsCollectionTypes(), (type_def) -> type_def.type_id

      required_task_fields_to_determine:
        "projects_collection": 1

      generator: (task_obj) ->
        types = []

        if (type_id = self.getTaskObjProjectsCollectionTypeId task_obj)
          if self.isProjectsCollectionClosed task_obj
            type_id = "#{closed_project_collection_prefix}#{type_id}"
          types.push type_id

        return types

      propertiesGenerator: (type_id) -> 
        is_closed = type_id.startsWith closed_project_collection_prefix
        type_id = type_id.replace closed_project_collection_prefix, ""
        type_def = self.getProjectsCollectionTypeById type_id

        type_label_i18n = type_def.type_label_i18n
        if is_closed
          type_label_i18n = type_def.closed_label_i18n
          
        type_properties = 
          text: TAPi18n.__ type_label_i18n, {}, JustdoI18n.default_lang
          text_i18n: type_label_i18n
          filter_list_order: 1
          customFilterQuery: (filter_state_id, column_state_definitions, context) ->
            return {"projects_collection.projects_collection_type": type_id}
        return type_properties

    return

  getAllProjectsCollectionsUnderJustdoCursorOptionsSchema: new SimpleSchema
    include_closed:
      type: Boolean
      optional: true
      defaultValue: false
    projects_collection_type:
      type: String
      optional: true
    fields:
      type: Object
      optional: true
      blackbox: true
      defaultValue: JustdoDeliveryPlanner.projects_collection_default_fields_to_fetch
  getAllProjectsCollectionsUnderJustdoCursor: (justdo_id, options, user_id) ->
    check justdo_id, String
    if not user_id?
      user_id = Meteor.userId()
    check user_id, String

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @getAllProjectsCollectionsUnderJustdoCursorOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    query = 
      project_id: justdo_id
      users: user_id
      "projects_collection.projects_collection_type":
        $ne: null
      "projects_collection.is_closed": 
        $ne: true
    if Meteor.isClient
      delete query.users
    if options.include_closed
      delete query["projects_collection.is_closed"]
    if _.isString options.projects_collection_type
      query["projects_collection.projects_collection_type"] = options.projects_collection_type
    
    query_options = 
      fields: options.fields
      
    return @tasks_collection.find(query, query_options)

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
      [JustdoDeliveryPlanner.task_is_project_field_name]: true
      [JustdoDeliveryPlanner.task_is_archived_project_field_name]: 
        $ne: true
    
    if Meteor.isServer
      query["parents2.parent"] = projects_collection_id
    if Meteor.isClient
      delete query.users
      query["parents.#{projects_collection_id}"] = {$ne: null}
    
    if options.include_closed
      delete query[JustdoDeliveryPlanner.task_is_archived_project_field_name]
      
    query_options = 
      fields: options.fields
    
    return @tasks_collection.find(query, query_options)
  
  getProjectsCollectionsOfProjectCursorOptionsSchema: new SimpleSchema
    include_closed:
      type: Boolean
      optional: true
      defaultValue: false
    projects_collection_type:
      type: String
      optional: true
    fields:
      type: Object
      optional: true
      blackbox: true
      defaultValue: JustdoDeliveryPlanner.projects_collection_default_fields_to_fetch
  getProjectsCollectionsOfProjectCursor: (justdo_id, project_id, options, user_id) ->
    check justdo_id, String
    check project_id, String
    if not user_id?
      user_id = Meteor.userId()
    check user_id, String

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @getProjectsCollectionsOfProjectCursorOptionsSchema,
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
      delete get_project_parents_query.users
      get_project_parents_query_options.fields.parents = 1
      project_parent_ids = _.keys @tasks_collection.findOne(get_project_parents_query, get_project_parents_query_options)?.parents

    get_parent_project_collections_query = 
      project_id: justdo_id
      users: user_id
      _id: 
        $in: project_parent_ids
      "projects_collection.projects_collection_type":
        $ne: null
      "projects_collection.is_closed":
        $ne: true
    if Meteor.isClient
      delete get_parent_project_collections_query.users
    if options.include_closed
      delete get_parent_project_collections_query["projects_collection.is_closed"]
    if _.isString options.projects_collection_type
      get_parent_project_collections_query["projects_collection.projects_collection_type"] = options.projects_collection_type

    get_parent_project_collections_query_options =
      fields: options.fields    
    return @tasks_collection.find(get_parent_project_collections_query, get_parent_project_collections_query_options)
