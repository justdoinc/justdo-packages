_.extend JustdoDeliveryPlanner.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @setupRouter()
    @_setupTaskType()
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

  _setupProjectsCollectionFeatures: ->
    @_setupProjectsCollectionTaskType()

    if Meteor.isClient
      @_setupProjectsCollectionContextmenu()
        
    return

  _setupProjectsCollectionTaskType: ->
    self = @

    closed_project_collection_prefix = "closed_"

    filter_list_order = 2
    tags_properties = 
      unknown_projects_collection_type:
        text: TAPi18n.__ "projects_collection_unknown_type_label", {}, JustdoI18n.default_lang
        text_i18n: "projects_collection_unknown_type_label"
        bg_color: "#f0f0f0"
        is_conditional: true
        filter_list_order: filter_list_order
        customFilterQuery: (filter_state_id, column_state_definitions, context) ->
            return {"projects_collection.projects_collection_type": {$ne: null, $nin: _.pluck self.getSupportedProjectsCollectionTypes(), "type_id"}}
    filter_list_order += 1

    for collection_type_def in self.getSupportedProjectsCollectionTypes()
      do (collection_type_def, filter_list_order) ->
        type_id = collection_type_def.type_id

        tags_properties[type_id] =
          text: TAPi18n.__ collection_type_def.type_label_i18n, {}, JustdoI18n.default_lang
          text_i18n: collection_type_def.type_label_i18n
          filter_list_order: filter_list_order
          bg_color: null
          customFilterQuery: (filter_state_id, column_state_definitions, context) ->
            return {"projects_collection.projects_collection_type": type_id, "projects_collection.is_closed": {$ne: true}}
        
        filter_list_order += 1

        tags_properties["#{closed_project_collection_prefix}#{type_id}"] =
          text: TAPi18n.__ collection_type_def.closed_label_i18n, {}, JustdoI18n.default_lang
          text_i18n: collection_type_def.closed_label_i18n
          filter_list_order: filter_list_order
          bg_color: null
          is_conditional: true
          customFilterQuery: (filter_state_id, column_state_definitions, context) ->
            type_id_without_closed_prefix = type_id.replace closed_project_collection_prefix, ""
            return {"projects_collection.projects_collection_type": type_id_without_closed_prefix, "projects_collection.is_closed": true}
        
        filter_list_order += 1 

    possible_tags = []
    conditional_tags = []
    for tag_id, tag_def of tags_properties
      if tag_def.is_conditional
        conditional_tags.push tag_id
      else
        possible_tags.push tag_id

    APP.justdo_task_type.registerTaskTypesGenerator "default", "projects-collection-type",
      possible_tags: possible_tags
      conditional_tags: conditional_tags

      required_task_fields_to_determine:
        "projects_collection": 1

      generator: (task_obj) ->
        types = []

        if (type_id = self.getTaskObjProjectsCollectionTypeId task_obj)
          if type_id not of tags_properties
            type_id = "unknown_projects_collection_type"

          if self.isProjectsCollectionClosed task_obj
            type_id = "#{closed_project_collection_prefix}#{type_id}"

          types.push type_id

        return types

      propertiesGenerator: (type_id) -> 
        return tags_properties[type_id]

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
  # Use getParentProjectsCollectionsGroupedByDepth instead
  # Recursively retrieves parent projects collections grouped by their depth
  # returns an array of arrays, where each inner array contains projects collections at that depth
  # e.g. [[task1, task2], [task3, task4], [task5]]
  # where task 1 and 2 are the immediate parents, task 3 and 4 are the parents of either task 1 or 2, and so on.
  _getParentProjectsCollectionsGroupedByDepth: (parent_task_ids) ->
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
    query_options = 
      fields:
        parents: 1
        projects_collection: 1
    
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
    return parent_projects_collections.push @_getParentProjectsCollectionsGroupedByDepth(parent_ids)

  # This method retrieves the parent projects collections grouped by their depth.
  # It first checks if there are any forced parent IDs provided in the options.
  # If forced parent IDs are provided, it uses them instead of the task's parents.
  # If no forced parent IDs are provided, it retrieves the task's parent IDs.
  # It then calls the internal method `_getParentProjectsCollectionsGroupedByDepth`
  # to get the parent projects collections grouped by their depth.
  # Finally, it returns the grouped parent projects collections.
  # options:
  #   forced_parent_ids: an array of parent IDs to use instead of the task's parents. we prioritize it over the task's parents.
  #   task: the task id or object to get the parent projects collections for, if forced_parent_ids is not provided
  # returns: check the comment of _getParentProjectsCollectionsGroupedByDepth
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
    
    return @_getParentProjectsCollectionsGroupedByDepth(parent_ids)
  
  isProjectsCollectionDepthLteMaxDepth: (options, max_depth) ->
    parent_projects_collections_depth = @getParentProjectsCollectionsGroupedByDepth(options).length
    return parent_projects_collections_depth <= max_depth

  requireProjectsCollectionDepthLteMaxDepth: (options, max_depth) ->
    if not @isProjectsCollectionDepthLteMaxDepth(options, max_depth)
      throw @_error "not-supported", "Cannot nest projects collections beyond #{max_depth} level(s)"

    return true
  