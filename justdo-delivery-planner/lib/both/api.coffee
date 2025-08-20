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

  getProjectsCollectionsUnderJustdoCursorOptionsSchema: JustdoDeliveryPlanner.schemas.getProjectsCollectionsUnderJustdoCursorOptionsSchema
  getProjectsCollectionsUnderJustdoCursor: (justdo_id, options, user_id) ->
    check justdo_id, String
    if not user_id?
      user_id = Meteor.userId()
    check user_id, String

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @getProjectsCollectionsUnderJustdoCursorOptionsSchema,
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
    if not _.isEmpty options.projects_collection_types
      query["projects_collection.projects_collection_type"] = 
        $in: options.projects_collection_types
    
    query_options = 
      fields: options.fields
      
    return @tasks_collection.find(query, query_options)

  getAllProjectsGroupedByProjectsCollectionsUnderJustdoOptionsSchema: new SimpleSchema
    projects_collection_options: 
      type: JustdoDeliveryPlanner.schemas.getProjectsCollectionsUnderJustdoCursorOptionsSchema
    projects_options: 
      type: JustdoDeliveryPlanner.schemas.getKnownProjectsOptionsSchema
    prune_tree:
      type: Boolean
      optional: true
      defaultValue: true
  getAllProjectsGroupedByProjectsCollectionsUnderJustdo: (justdo_id, options, user_id) ->
    # The purpose of this method is to return an object that represents the tree of projects-collections and their projects.
    #
    # Its design and main motivation is to fetch the projects collections and projects in manner that avoids unnecessary
    # reactivity events in the client side. The function is expensive. It requires in the client side 2 full Tasks collection
    # scans, in addition to various tree traversing. As such, we want to re-compute its result only when actually necessary.
    # Note, that in the server side, since there are likely (not tested), some indexes that can be useful, it is less likely
    # that 2x scans are necessary.
    #
    # RETURNED OBJECT:
    # 
    # Structure of returned obj:
    # {
    #   <project_collection_task_id>: {
    #     _id: project_collection_task_id
    #     parents: {...}
    #     project_ids: [<project_id>, ...]
    #     is_root_pc: (true if the pc is a root pc, not set otherwise)
    #     sub_pcs: (array of project_collection_task_ids that are sub-pcs of the current pc, not set otherwise)
    #     parent_pcs: (array of project_collection_task_ids that are parent_pcs of the current pc, not set otherwise)
    #   },
    #   [JustdoDeliveryPlanner.projects_without_pc_type_id]: {
    #     _id: JustdoDeliveryPlanner.projects_without_pc_type_id
    #     project_ids: [<project_id>, ...],
    #     is_root_pc: true
    #   } (only included if project_ids is not empty)
    # }
    # 
    # If there are not projects, and no root-projects-collections, returns an empty object.
    #
    # ARGS:
    #
    # justdo_id: the justdo for in which we are looking for.
    #
    # user_id: the user that is consider to execute the request, tasks not shared with this user_id
    # are considered as not existing.
    #
    # options: an object that can have the following optional options:
    #
    # projects_collection_options
    #
    #   The options that will be provided when calling @getProjectsCollectionsUnderJustdoCursor
    #   follows the structure of: JustdoDeliveryPlanner.schemas.getProjectsCollectionsUnderJustdoCursorOptionsSchema
    #
    #   The include_closed and projects_collection_types settings can be set by the user of this method
    #   but the fields setting is forced by us to _id to ensure no unnecessary invalidation except for things
    #   that might cause tree-rebuild.
    # 
    #   SPECIAL NOTE FOR the `include_closed` and `projects_collection_types` options: 
    #   If a Projects Collection (B) with valid child Projects is under another Projects Collection that is excluded from the result by the `include_closed` or `projects_collection_types` options,
    #   B will still be included in the results without the `parent_pcs`, `sub_pcs` and `is_root_pc` fields.
    #   The consumer of this method is responsible for handling this case.
    #
    # projects_options:
    #
    #   The options that will be provided when calling @getKnownProjects to retrieve the projects
    #   follows the structure of: JustdoDeliveryPlanner.schemas.getKnownProjectsOptionsSchema
    #
    #   The active_only, exclude_tasks, and customize_query settings can be set by the user of this method
    #   but the fields setting is forced by us to _id and parents to ensure no unnecessary invalidation except for things
    #   that might cause tree-rebuild.
    #
    #   Available options:
    #   - active_only: Boolean (default: false) - if true, excludes archived projects
    #   - fields: Ignored (forced to {_id: 1, parents: 1} to avoid unnecessary reactivity on the client side)
    #   - sort_by: Object (default: {seqId: -1}) - specifies sorting order for projects
    #   - exclude_tasks: [String] - array of task IDs to exclude from results
    #   - customize_query: Object (default: {}) - additional MongoDB query conditions to apply
    #
    # prune_tree:
    #
    #   Default to true. If false the returned object will include an entry for *every* project collection.
    #   If true, the response includes ONLY the project collections that satisfy at least one of the following
    #   rules:
    #
    #   1) Root project collections
    #      - A root collection is always returned, even if it contains no projects.
    #      - If a collection has multiple parents and ANY parent is root, treat it as root
    #        for this rule (include it even without qualifying projects).
    #
    #   2) Collections with a qualifying descendant project
    #      - The collection has ≥1 descendant project that passes
    #        projects_options.customize_query filter.
    #      - “Descendant project” means there exists an UNBROKEN chain composed ONLY of
    #        INCLUDED project-collection types from the starting collection down to a DIRECT
    #        parent-child edge: (collection → project).
    #      - Any non–project-collection node (e.g., task/sub-task) OR any project-collection
    #        of a type NOT included by the filter breaks the chain.
    #
    #   Additional notes
    #   ----------------
    #   • Direct-child requirement (for “under”):
    #     A project is considered “under” a project collection only if it is a DIRECT child
    #     of that collection (i.e., the final edge is collection → project).
    #
    #   • Pruning effect under rule (1):
    #     If a root collection has no qualifying descendant projects, it is still returned,
    #     but NONE of its descendant collections are included.
    #
    #   • Filters that enumerate specific collections or types:
    #     If projects_collection_options explicitly includes certain collections or
    #     collection TYPES, only projects that are DIRECT children of those included
    #     collections count toward rule (2). Encountering a non-included TYPE in the path
    #     breaks the chain; deeper projects do NOT count unless all intermediate collections
    #     are of included types.
    #
    #   Examples
    #   --------
    #   1) A → B → C → Project P (P passes the filter)
    #      Include A, B, and C (unbroken chain of included collection types ending in C → P).
    #
    #   2) Root R with no qualifying projects anywhere
    #      Include R only; exclude all its descendant collections.
    #
    #   3) X has parents {R, Y}, where R is root; X has no qualifying projects
    #      Include X (multiple parents, one is root).
    #
    #   4) PC1 → PC2 → PC3 → PC4 → Project P (P passes the filter)
    #      PC3 is NOT one of the included project-collection TYPES → the chain is broken at PC3.
    #      Do NOT treat P as a descendant of PC1 or PC2. Only PC4 can qualify under rule (2).
    #
    #   5) PC1 → PC2 → Task T → PC3 → Project P (P passes the filter)
    #      The task breaks the chain. Do NOT treat P as a descendant of PC1 or PC2.
    #      Only PC3 can qualify under rule (2).

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
    # options is now cleaned_val, which is a clone of the original options,
    # hence we'll modify the options in-place below.
    options = cleaned_val

    projects_grouped_by_projects_collections = {}

    # These fields are the bare minimum necessary to derive the tree structure, read more in the main comment
    # for this method.
    options.projects_collection_options.fields = 
      _id: 1
      parents: 1

    @getProjectsCollectionsUnderJustdoCursor(justdo_id, options.projects_collection_options, user_id).forEach (project_collection) ->
      project_collection.project_ids = []
      projects_grouped_by_projects_collections[project_collection._id] = project_collection
      return
    
    # Add info about sub_pcs, parent_pcs and is_root_pc
    for pc_id, pc of projects_grouped_by_projects_collections
      pc_parents = _.keys pc.parents
      for parent_id in pc_parents
        is_root_pc = parent_id is "0"
        if is_root_pc
          pc.is_root_pc = true

        if (parent_pc = projects_grouped_by_projects_collections[parent_id])?
          if not parent_pc.sub_pcs?
            parent_pc.sub_pcs = []
          parent_pc.sub_pcs.push pc_id

          if not pc.parent_pcs?
            pc.parent_pcs = []
          pc.parent_pcs.push parent_id
    
    projects_without_pc_doc = 
      _id: JustdoDeliveryPlanner.projects_without_pc_type_id
      project_ids: []
      is_root_pc: true
    
    # These fields are the bare minimum necessary to derive the tree structure, read more in the main comment
    # for this method.
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
        projects_without_pc_doc.project_ids.push project._id
    
    # Include "Projects without pc" only if it has projects
    # Note that if a project is under a non-passing Projects Collection, it will be considered as a project without a PC.
    if not _.isEmpty projects_without_pc_doc.project_ids
      projects_grouped_by_projects_collections[projects_without_pc_doc._id] = projects_without_pc_doc

    pcShouldBePruned = (projects_collection_id) ->
      projects_collection = projects_grouped_by_projects_collections[projects_collection_id]

      pc_has_child_projects = not _.isEmpty projects_collection.project_ids
      if pc_has_child_projects
        return false
        
      pc_has_child_pcs = not _.isEmpty projects_collection.sub_pcs
      if not pc_has_child_pcs
        return true

      # Recursively check each sub-pc on whether it should be pruned
      # If any sub-pc should not be pruned, the current pc should not be pruned
      for sub_projects_collection_id in projects_collection.sub_pcs
        if not pcShouldBePruned(sub_projects_collection_id)
          return false
      
      return true

    if options.prune_tree
      for pc_id, pc of projects_grouped_by_projects_collections
        # IMPORTANT: The condition check of `pc.is_root_pc` is DESIGNED to exist outside of `pcShouldBePruned` 
        # to prevent multi-parented root project collections from causing their other parents to NOT be pruned when they should.
        #
        # Example, if we took pc.is_root_pc into pcShouldBePruned the following:
        # ROOT -> PC1 -> NO PROJECTS
        # ROOT -> PC2 -> PC3 -> PC1 -> NO PROJECTS
        #
        # will cause PC1 to return true to pcShouldBePruned() and the recursive call on PC2, will end up
        # getting to it causing PC2 and PC3 to be returned despite the fact they shouldn't

        if (not pc.is_root_pc) and pcShouldBePruned(pc_id)
          if pc.parent_pcs?
            # Delete the current pc from the parent's sub_pcs array
            for parent_pc_id in pc.parent_pcs
              projects_grouped_by_projects_collections[parent_pc_id]?.sub_pcs = _.without(projects_grouped_by_projects_collections[parent_pc_id].sub_pcs, pc_id)

          # Delete the current pc from the projects_grouped_by_projects_collections object
          delete projects_grouped_by_projects_collections[pc_id]

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
  