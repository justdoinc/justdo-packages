_.extend JustdoDeliveryPlanner.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @setupRouter()
    @_setupTaskType()

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

  getKnownProjectsOptionsSchema: JustdoDeliveryPlanner.schemas.getKnownProjectsOptionsSchema
  getKnownProjects: (project_id, options, user_id) ->
    # Get all the active projects known to

    if not user_id?
      return []

    check user_id, String

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @getKnownProjectsOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

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

  isProjectsCollectionEnabledGlobally: -> JustdoDeliveryPlanner.is_projects_collection_enabled_globally

  isProjectsCollectionEnabledOnProjectId: (project_id) ->
    return APP.projects.isPluginInstalledOnProjectId(JustdoDeliveryPlanner.projects_collection_plugin_id, project_id)

  isProjectsCollectionEnabled: (project_id) -> 
    if not project_id?
      if Meteor.isClient 
        project_id = JD.activeJustdoId()
      if Meteor.isServer
        throw @_error "missing-argument", "project_id is required"

    return @isProjectsCollectionEnabledGlobally() or @isProjectsCollectionEnabledOnProjectId(project_id)

  getSupportedProjectsCollectionTypes: -> JustdoDeliveryPlanner.projects_collections_types

  getProjectsCollectionTypeById: (type_id) ->
    if not type_id?
      return

    return _.find @getSupportedProjectsCollectionTypes(), (type) -> type.type_id is type_id

  getTaskObjProjectsCollectionTypeId: (task_obj) ->
    return task_obj?.projects_collection?.projects_collection_type

  isTaskProjectsCollection: (task) ->
    if _.isString task
      query = 
        _id: task
        "projects_collection.projects_collection_type": 
          $ne: null
      query_options = 
        fields:
          "projects_collection.projects_collection_type": 1
      task = @tasks_collection.findOne(query, query_options)

    return @getTaskObjProjectsCollectionTypeId(task)?

  isProjectsCollectionClosed: (task_obj) ->
    if not @getTaskObjProjectsCollectionTypeId(task_obj)?
      return false
    
    return task_obj?.projects_collection?.is_closed

  _setupTaskType: ->
    tags_properties =
      "project":
        text: "Project"
        text_i18n: "project"

        filter_list_order: 0

        customFilterQuery: (filter_state_id, column_state_definitions, context) ->
          return {[JustdoDeliveryPlanner.task_is_project_field_name]: true, [JustdoDeliveryPlanner.task_is_archived_project_field_name]: {$ne: true}}
      "closed_project":
        text: "Closed Project"
        text_i18n: "closed_project_type_label"
        is_conditional: true

        filter_list_order: 1

        customFilterQuery: (filter_state_id, column_state_definitions, context) ->
          return {[JustdoDeliveryPlanner.task_is_project_field_name]: true, [JustdoDeliveryPlanner.task_is_archived_project_field_name]: true}

    possible_tags = []
    conditional_tags = []
    for tag_id, tag_def of tags_properties
      if tag_def.is_conditional
        conditional_tags.push tag_id
      else
        possible_tags.push tag_id

    APP.justdo_task_type.registerTaskTypesGenerator "default", "is-project",
      possible_tags: possible_tags
      conditional_tags: conditional_tags

      required_task_fields_to_determine:
        [JustdoDeliveryPlanner.task_is_project_field_name]: 1
        [JustdoDeliveryPlanner.task_is_archived_project_field_name]: 1

      generator: (task_obj) ->
        tags = []

        if task_obj[[JustdoDeliveryPlanner.task_is_project_field_name]] is true
          if task_obj[[JustdoDeliveryPlanner.task_is_archived_project_field_name]] is true
            tags.push "closed_project"
          else
            tags.push "project"
        
        return tags

      propertiesGenerator: (tag) -> tags_properties[tag]

    return

  getAllProjectsCollectionsUnderJustdoCursorOptionsSchema: JustdoDeliveryPlanner.schemas.getAllProjectsCollectionsUnderJustdoCursorOptionsSchema
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

  getAllProjectsGroupedByProjectsCollectionsUnderJustdoOptionsSchema: new SimpleSchema
    projects_collection_options: 
      type: JustdoDeliveryPlanner.schemas.getAllProjectsCollectionsUnderJustdoCursorOptionsSchema
    projects_options: 
      type: JustdoDeliveryPlanner.schemas.getKnownProjectsOptionsSchema
  getAllProjectsGroupedByProjectsCollectionsUnderJustdo: (justdo_id, options, user_id) ->
    check justdo_id, String
    if not user_id?
      user_id = Meteor.userId()
    check user_id, String

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @getAllProjectsGroupedByProjectsCollectionsUnderJustdoOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    # `projects_grouped_by_projects_collections` is the returned obj with the following structure:
    # {
    #   <project_collection_task_id>: {
    #     ...project_collection_fields
    #     project_ids: [<project_id>, ...]
    #   },
    #   "projects_without_pc": {
    #     project_ids: [<project_id>, ...]
    projects_grouped_by_projects_collections = {}

    # We set the projects_collection_type to null to get all projects collections
    # 
    options.projects_collection_options.projects_collection_type = null
    @getAllProjectsCollectionsUnderJustdoCursor(justdo_id, options.projects_collection_options, user_id).forEach (project_collection) ->
      project_collection.project_ids = []
      projects_grouped_by_projects_collections[project_collection._id] = project_collection
      return
    
    projects_without_pc_doc = 
      _id: "projects_without_pc"
      title: TAPi18n.__ "ppm_projects_without_department_label"
      project_ids: []
    projects_grouped_by_projects_collections[projects_without_pc_doc._id] = projects_without_pc_doc
    
    # We force these fields because they're what's needed
    options.projects_options.fields = 
      _id: 1
      parents: 1
    
    projects = @getKnownProjects(justdo_id, options.projects_options, user_id)
    for project in projects
      project_parent_ids = _.keys project.parents
      is_project_under_any_pc = _.find(project_parent_ids, (parent_id) -> projects_grouped_by_projects_collections[parent_id]?)?

      if is_project_under_any_pc
        for parent_id in project_parent_ids
          if projects_grouped_by_projects_collections[parent_id]?
            projects_grouped_by_projects_collections[parent_id].project_ids.push project._id
      else
        projects_grouped_by_projects_collections["projects_without_pc"].project_ids.push project._id
    
    return projects_grouped_by_projects_collections

  getProjectsUnderCollectionCursorOptionsSchema: new SimpleSchema
    include_closed:
      type: Boolean
      optional: true
      defaultValue: false
    query:
      type: Object
      optional: true
      blackbox: true
    fields:
      type: Object
      optional: true
      blackbox: true
      defaultValue: JustdoDeliveryPlanner.projects_collection_default_fields_to_fetch
    sort:
      type: Object
      optional: true
      blackbox: true
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
    if options.query?
      # If query is provided, extend it to the query without overriding the existing query
      query = _.extend {}, options.query, query
    
    if Meteor.isServer
      query["parents2.parent"] = projects_collection_id
    if Meteor.isClient
      delete query.users
      query["parents.#{projects_collection_id}"] = {$ne: null}
    
    if options.include_closed
      delete query[JustdoDeliveryPlanner.task_is_archived_project_field_name]
      
    query_options = 
      fields: options.fields
    if options.sort?
      query_options.sort = options.sort
    
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

  # Helper function to extract parent IDs from a task
  _getParentIds: (task) ->
    if not task?.parents?
      return []
    
    return _.chain(task.parents)
      .keys()
      .filter((parent_id) -> parent_id isnt "0")
      .value()

  # This is an internal method that should not be called directly
  # Use getParentProjectsCollectionsGroupedByDepth instead it also gives a detailed
  # documentation for returned value.
  _getParentProjectsCollectionsGroupedByDepth: (parent_task_ids, fields={}) ->
    parent_projects_collections = []

    # Convert single ID to array
    if _.isString parent_task_ids
      parent_task_ids = [parent_task_ids]

    if _.isEmpty parent_task_ids
      return parent_projects_collections
    
    # Find which tasks are projects collections
    query = 
      _id: 
        $in: parent_task_ids
      "projects_collection.projects_collection_type": 
        $ne: null
    default_fields = 
      parents: 1
      projects_collection: 1
    query_options = 
      fields: _.extend {}, fields, default_fields
      
    collections_cursor = @tasks_collection.find(query, query_options)
    
    # If none are projects collections, depth is 0
    if collections_cursor.count() is 0
      return parent_projects_collections
    
    parent_projects_collections.push collections_cursor.fetch()

    # Get parent IDs of all projects collections
    all_parent_ids = []
    collections_cursor.forEach (task) =>
      all_parent_ids = all_parent_ids.concat(@_getParentIds(task))
    
    # Remove duplicates
    parent_ids = _.uniq all_parent_ids
    
    # If no parents, depth is 1 (base case)
    if _.isEmpty parent_ids
      return parent_projects_collections
    
    # Otherwise, depth is 1 + max depth of parents
    return parent_projects_collections.concat @_getParentProjectsCollectionsGroupedByDepth(parent_ids, fields)

  # A task is considered to belong to a project collections only if they are its immediate parents.
  # Further, a project collection is considered to be a sub-project collection of another project
  # collection only if that project collection is its direct parent.
  #
  # Examples: PC means PC, P means project and T means regular tasks
  #
  # Example 1:
  #
  # PC -> T -> P
  #
  # P isn't considered to belong to PC, T does.
  #
  # Example 2:
  #
  # PC1 -> PC2 -> PC3 -> P -> T
  #
  # From the perspective of P it belongs to the sub-sub project collection PC3, whose ancestors collections are
  # PC2 and PC1
  #
  # From the perspective of T is doesn't belong to a project collection.
  #
  # From the perspective of PC2 it belongs to the project collection PC1.
  #
  # This method implements the above description - It returns the parent projects collections grouped by their depth.
  #
  # Note, because of multi-parents there might be multi-departments in each depth.
  #
  # options:
  #   forced_parent_ids: an array of parent IDs to use instead of the task's parents. we prioritize it over the task's parents.
  #   task: the task id or object to get the ancestor projects collections for, if forced_parent_ids is not provided
  #   fileds: the fileds to include for every task document.
  #
  # To allow situations where tasks aren't yet written to the DB, we allow a mechanism to force
  # parents ids to appear as the actual parents (the purpose for forced_parent_ids).
  #
  # Returned value:
  #
  # returns an array of arrays, where each inner array contains projects collections at that depth
  # e.g. [[task1, task2], [task3, task4], [task5]]
  # where task 1 and 2 are the immediate parents, task 3 and 4 are the parents of either task 1 or 2, and so on.
  getParentProjectsCollectionsGroupedByDepth: (options) ->
    if options.forced_parent_ids?
      parent_ids = options.forced_parent_ids
    else
      if not (task = options.task)?
        throw @_error "missing-argument", "options.task is required"
        
      if _.isString task
        query = 
          _id: task
        task = @tasks_collection.findOne(query, {fields: {parents: 1}})

      if not task.parents?
        throw @_error "fatal", "Task document does not have a parent object."

      parent_ids = @_getParentIds(task)
    
    return @_getParentProjectsCollectionsGroupedByDepth(parent_ids, options.fields)

  _isProjectsCollectionDepthLteMaxDepth: (parent_projects_collections_depth, max_depth) ->
    return parent_projects_collections_depth <= max_depth

  isProjectsCollectionDepthLteMaxDepth: (options, max_depth) ->
    parent_projects_collections_depth = @getParentProjectsCollectionsGroupedByDepth(options).length
    return @_isProjectsCollectionDepthLteMaxDepth(parent_projects_collections_depth, max_depth)

  requireProjectsCollectionDepthLteMaxDepth: (options, max_depth) ->
    parent_projects_collections = @getParentProjectsCollectionsGroupedByDepth(options)
    parent_projects_collections_depth = parent_projects_collections.length

    if not @_isProjectsCollectionDepthLteMaxDepth(parent_projects_collections_depth, max_depth)
      # If a custom error message is provided, use it
      if options.custom_error_message?
        throw @_error "not-supported", TAPi18n.__ options.custom_error_message

      # Else, attempt to get the type of the nearest parent projects collection for a better error message
      parent_projects_collection_type = parent_projects_collections[0]?.projects_collection?.projects_collection_type
      if not parent_projects_collection_type?
        # If no type is found, use the first supported type
        parent_projects_collection_type = JustdoDeliveryPlanner.projects_collections_types[0].type_id

      parent_projects_collection_label = TAPi18n.__ @getProjectsCollectionTypeById(parent_projects_collection_type)?.type_label_plural_i18n
      throw @_error "not-supported", TAPi18n.__ "projects_collection_depth_gt_max_depth_default_err", {projects_collection_label: parent_projects_collection_label, count: max_depth}

    return true
  