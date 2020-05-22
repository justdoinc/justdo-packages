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

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

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

  _ensureMembersDocsExistsForAllInvolvedMembers: (task, involved_members, user_id) ->
    # Task can be either a task document, or a task_id, if a document is provided,
    # no request will be made to fetch it.

    if _.isString task
      task = @getProjectTaskWithRelevantFields(task, user_id)

    if not involved_members?
      involved_members =
        @getProjectBurndownData(task._id, user_id, {involved_members_only: true, skip_ensure_membership: true}).involved_members

    if not (existing_members_availability_array = task["#{JustdoDeliveryPlanner.task_project_members_availability_field_name}"])?
      existing_members_availability_array = []    

    existing_involved_members = _.map existing_members_availability_array, (member) -> member.user_id

    new_members_ids = _.difference involved_members, existing_involved_members

    new_members_docs = _.map new_members_ids, (member_id) => @_getNewMemberObjStructure(member_id)

    if not _.isEmpty new_members_docs
      modifier = 
        $push:
          "#{JustdoDeliveryPlanner.task_project_members_availability_field_name}": 
            $each: new_members_docs

      @tasks_collection.update(task._id, modifier)

    return

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

    @_ensureMembersDocsExistsForAllInvolvedMembers(task_doc, null, user_id)

    return new_state

  commitProjectPlan: (project_task_id, user_id) ->
    check project_task_id, String
    check user_id, String

    # Note, we check user belongs to task in the query
    if not (task_doc = @tasks_collection.findOne({_id: project_task_id, users: user_id}))?
      throw @_error("unknown-task")

    if not task_doc.start_date?
      throw @_error("no-start-date") # note, error message is on errors-types.coffee

    @tasks_collection.update(project_task_id, {$set: {"#{JustdoDeliveryPlanner.task_is_committed_field_name}": new Date()}})

    return

  removeProjectPlanCommit: (project_task_id, user_id) ->
    check project_task_id, String
    check user_id, String

    # Note, we check user belongs to task in the query
    if not (task_doc = @tasks_collection.findOne({_id: project_task_id, users: user_id}))?
      throw @_error("unknown-task")

    if not task_doc[JustdoDeliveryPlanner.task_is_committed_field_name]?
      throw @_error("project-isnt-committed") # note, error message is on errors-types.coffee

    @tasks_collection.update(project_task_id, {$set: {"#{JustdoDeliveryPlanner.task_is_committed_field_name}": null}})

    return

  getProjectBurndownData: (task_id, user_id, options) ->
    check task_id, String
    check user_id, String

    default_options =
      involved_members_only: false
      skip_ensure_membership: false

    options = _.extend default_options, options

    # For findSubTree below, we don't require the user to belong to all the tasks of the subtree
    # in order to get its data, but, at the minimum we require here the user to belong to its root.
    if not (task_doc = @getProjectTaskWithRelevantFields(task_id, user_id))?
      throw @_error "unknown-task"

    user_tz = @getUserTimeZone(user_id)

    tree_map = @tasks_collection.findSubTree task_id, {base_query: {project_id: task_doc.project_id}, fields: {}}

    involved_members = {}
    burndown = {}
    resources = @tasks_resources_collection.find({task_id: {$in: _.keys(tree_map)}}).forEach (resource) =>
      if resource.resource_type.substr(0, 6) == "b:user"
        user_id = resource.resource_type.substr(7)

        involved_members[user_id] = true

        if not options.involved_members_only
          date_str = @getDateStringInTimezone(user_tz, resource.updatedAt)

          if not burndown[date_str]?
            burndown[date_str] =
              total: 0
              users: {}

          if not burndown[date_str].users[user_id]
            burndown[date_str].users[user_id] = 0

          if resource.stage == "p"
            burndown[date_str].total += resource.delta
            burndown[date_str].users[user_id] += resource.delta
          else if resource.stage == "e"
            burndown[date_str].total -= resource.delta
            burndown[date_str].users[user_id] -= resource.delta

    involved_members = _.keys(involved_members)

    if not options.skip_ensure_membership
      @_ensureMembersDocsExistsForAllInvolvedMembers(task_doc, involved_members, user_id)

    return {burndown: burndown, involved_members: involved_members}

  _saveBaselineProjectionDataSchema: new SimpleSchema
    series:
      type: [[String, Number]] # [[String, Number]] is not fully supported, both are converted to strings...
      decimal: true
  saveBaselineProjection: (task_id, data, user_id) ->
    check task_id, String
    check data, Object
    check user_id, String

    # Note, we check user belongs to task in the query
    if not (task_doc = @tasks_collection.findOne({_id: task_id, users: user_id}))?
      throw @_error("unknown-task")

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_saveBaselineProjectionDataSchema,
        data,
        {self: @, throw_on_error: true}
      )
    data = cleaned_val

    data.series = _.map data.series, (data_point) -> [data_point[0], parseFloat(data_point[1])] # [[String, Number]] is not fully supported, both are converted to strings...

    data.saved_by = user_id
    data.as_of = new Date()

    @tasks_collection.update(task_id, {$set: {"#{JustdoDeliveryPlanner.task_baseline_projection_data_field_name}": data}})

    return

  removeBaselineProjection: (task_id, user_id) ->
    check user_id, String
    check task_id, String

    # Note, we check user belongs to task in the query
    if not (task_doc = @tasks_collection.findOne({_id: task_id, users: user_id}))?
      throw @_error("unknown-task")

    @tasks_collection.update(task_id, {$set: {"#{JustdoDeliveryPlanner.task_baseline_projection_data_field_name}": null}})

    return

