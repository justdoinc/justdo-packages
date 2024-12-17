_.extend JustdoDeliveryPlanner.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  getProjectTaskWithRelevantFields: (task_id, user_id) ->
    fields = @_getProjectRelevantFieldsProjection()

    return @tasks_collection.findOne({_id: task_id, users: user_id}, {fields: fields})

  getUserTimeZone: (user_id) -> Meteor.users.findOne(user_id)?.profile?.timezone or JustdoDeliveryPlanner.default_time_zone

  getDateStringInTimezone: (timezone, date) ->
    if not date?
      date = new Date()

    return moment.tz(date, timezone).format("YYYY-MM-DD")

  _getNewMemberObjStructure: (member_id) ->
    new_member_doc =
      user_id: member_id
      availability_type: "simple"
      simple_daily_availability: JustdoDeliveryPlanner.default_simple_member_daily_availability_seconds

    return new_member_doc

  toggleTaskIsProject: (task_id, user_id) ->
    check user_id, String
    check user_id, String

    # Note, we check user belongs to task in the query
    if not (task_doc = @getProjectTaskWithRelevantFields(task_id, user_id))?
      throw @_error("unknown-task")

    task_obj_is_project = @isTaskObjProject(task_doc)

    new_state = not task_obj_is_project

    update =
      "#{JustdoDeliveryPlanner.task_is_project_field_name}": new_state

    if new_state is true
      if not task_doc["#{JustdoDeliveryPlanner.task_base_project_workdays_field_name}"]?
        update["#{JustdoDeliveryPlanner.task_base_project_workdays_field_name}"] =
          JustdoDeliveryPlanner.default_base_project_workdays

      if not task_doc["#{JustdoDeliveryPlanner.task_project_members_availability_field_name}"]?
        update["#{JustdoDeliveryPlanner.task_project_members_availability_field_name}"] = []

    @tasks_collection.update(task_id, {$set: update})

    return new_state
  
  setTaskProjectCollectionType: (task_id, type_id, user_id) ->
    check task_id, String
    check type_id, String
    check user_id, String

    query = 
      _id: task_id
      users: user_id
    modifier = 
      $set: 
        "projects_collection.projects_collection_type": type_id 
          
    return @tasks_collection.update query, modifier
  
  unsetTaskProjectCollectionType: (task_id, user_id) ->
    check task_id, String
    check user_id, String

    query = 
      _id: task_id
      users: user_id      
    modifier = 
      # Note: We set the projects_collection field to an empty object instead of using $unset
      # because $unset will set projects_collection as null, which interferes with setTaskProjectCollectionType.
      $set: 
        projects_collection: {}
          
    return @tasks_collection.update query, modifier
  
  closeProjectsCollection: (task_id, user_id) ->
    check task_id, String
    check user_id, String

    query = 
      _id: task_id
      users: user_id
      "projects_collection.projects_collection_type": 
        $ne: null
    modifier = 
      $set: 
        "projects_collection.is_closed": true

    return @tasks_collection.update query, modifier
  
  reopenProjectsCollection: (task_id, user_id) ->
    check task_id, String
    check user_id, String

    query = 
      _id: task_id
      users: user_id
      "projects_collection.projects_collection_type": 
        $ne: null

    modifier = 
      $set: 
        "projects_collection.is_closed": false

    return @tasks_collection.update query, modifier
