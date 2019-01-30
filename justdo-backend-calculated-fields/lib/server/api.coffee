last_task_change_prop_name_ddp_connection = "backend_calc_field_last_task_change"
consequent_tasks_counter_prop_name_ddp_connection = "backend_calc_field_consequent_tasks_changes_counter"
# Subsequent task changes are series of task changes that the time passed between each
# one of them isn't longer than time_since_last_call_to_reset_subsequent_tasks_counter_ms
time_since_last_call_to_reset_subsequent_tasks_counter_ms = 1 * 1000
max_permitted_handled_subsequent_task_changes_per_connection = 50
updateSubsequentTaskLimiterAndThrowIfLimitExceeded = ->
  op_mem_space = JustdoHelpers.getDdpConnectionObjectOrTickObject()

  consequent_task_change = false
  if (last_change = op_mem_space[last_task_change_prop_name_ddp_connection])? and
     ((new Date()) - last_change) <= time_since_last_call_to_reset_subsequent_tasks_counter_ms
    consequent_task_change = true

  op_mem_space[last_task_change_prop_name_ddp_connection] = new Date()

  if not consequent_task_change
    op_mem_space[consequent_tasks_counter_prop_name_ddp_connection] = 1
  else
    op_mem_space[consequent_tasks_counter_prop_name_ddp_connection] += 1

  if op_mem_space[consequent_tasks_counter_prop_name_ddp_connection] > max_permitted_handled_subsequent_task_changes_per_connection
    error_type = "rate-limiter-exceeded"
    error_message = "Up to #{max_permitted_handled_subsequent_task_changes_per_connection} subsequent tasks changes can be handled by justdo-backend-calculated-fields per connection per #{time_since_last_call_to_reset_subsequent_tasks_counter_ms / 1000} seconds"

    console.error("[justdo-backend-calculated-fields] [#{error_type}] #{error_message}")
    throw new Meteor.Error(error_type, error_message)

  return

_.extend JustdoBackendCalculatedFields.prototype,
  commands:
    max_due_date_of_direct_subtasks:
      label: "Max due date by direct child-tasks"
    max_due_date_of_all_subtasks:
      label: "Max due date by all child tasks"
    max_due_date_of:
      label: "Max due date of specific tasks"
    due_date_offset:
      label: "Due date by offset"

  getCustomFieldsDefinition: ->
    commands_select_options = []
    for command_id, command_def of @commands
      commands_select_options.push {
        option_id: command_id
        label: command_def.label
      }

    return [
      {
        "field_id" : "backend_calc_field_cmd",
        "field_type" : "select",
        "grid_editable_column" : true,
        "grid_visible_column" : true,
        "label" : "Calc command",
        "default_width" : 240,
        "field_options" : {
          "select_options" : commands_select_options
        }
      },
      {
        "field_id" : "backend_calc_field_cmd_params",
        "field_type" : "string",
        "grid_editable_column" : true,
        "grid_visible_column" : true,
        "label" : "Calc parameters",
        "default_width" : 250
      }
    ]

  setupCustomFieldsForProject: (project_id, user_id) ->
    # Read comment on collection-hooks.coffee
    @removeCustomFieldsForProject(project_id, user_id)

    if not (project_doc = @projects_collection.findOne(project_id))?
      return

    custom_fields = (project_doc.custom_fields or []).concat(@getCustomFieldsDefinition())

    APP.projects.setProjectCustomFields(project_id, custom_fields, user_id)

    return

  removeCustomFieldsForProject: (project_id, user_id) ->
    if not (project_doc = @projects_collection.findOne(project_id))?
      return

    if not (existing_custom_fields = project_doc.custom_fields)?
      # nothing to do ...
      return

    our_custom_fields_keys = _.map @getCustomFieldsDefinition(), (doc) -> doc.field_id

    new_custom_fields = []
    for custom_field_def in existing_custom_fields
      if custom_field_def.field_id not in our_custom_fields_keys
        new_custom_fields.push custom_field_def

    APP.projects.setProjectCustomFields(project_id, new_custom_fields, user_id)

    return

  updateDueDate: (task_id, due_date, user_id) ->
    @tasks_collection.update({_id: task_id, due_date: {$ne: due_date}}, {$set: {due_date: due_date, updated_by: user_id}})

    return

  validateBackendCalcOrReplaceWithError: (task) ->
    command = task.backend_calc_field_cmd
    params = task.backend_calc_field_cmd_params

    if @isParamsValueIsSystemMessage(params)
      return false

    if command == "max_due_date_of_direct_subtasks" and _.isEmpty(params)
      return true

    if command == "max_due_date_of_all_subtasks" and _.isEmpty(params)
      return true

    if command == "max_due_date_of"
      re = /^\s*\d+(\s*,\s*\d+)*\s*$/

      if params?.match(re)
        return true

      info_message = "Usage:\n• To set the due date as the max date of tasks 1 and 5 use: '1, 5'"

    if command == "due_date_offset"
      re = /^\s*\d+\s*,\s*[+-]?\d+\s*$/

      if params?.match(re)
        return true

      info_message = "Usage:\n• To set the due date as the date of task 5 minus 3 days use: '5,-3'\n• To set the due date as the date of task 5 plus days use: '5,3'"

    @tasks_collection.direct.update(_id:task._id, {$set: {backend_calc_field_cmd_params: info_message, updated_by: 0}}, {bypassCollection2: true})

    return false

  triggerDueDatesCommandsUpdatesForTaskChange: (task_doc, user_id) ->
    if not task_doc.project_id?
      # We are dealing with an item that had been pseudo removed, we ignore that case.
      # (the same way that we didn't handle real tasks removes before the introduction
      # of the pseudo removes, things keep working as planned).

      return
    
    updateSubsequentTaskLimiterAndThrowIfLimitExceeded()

    if not user_id?
      user_id = 0

    # Generate a cache for all project commands.
    commands = []
    @tasks_collection.find({backend_calc_field_cmd: {$exists: true}, project_id: task_doc.project_id, _raw_removed_date: null}).forEach (task) =>
      if @validateBackendCalcOrReplaceWithError(task)
        commands.push
          task_id: task._id
          command: task.backend_calc_field_cmd
          params: task.backend_calc_field_cmd_params

    # Generate a cache for all the project tasks.
    project_tasks = {}

    #
    # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee of package justdo-projects
    # and to drop obsolete indexes (see FETCH_PROJECT_NON_REMOVED_TASKS_INDEX there)
    #
    @tasks_collection.find({project_id: task_doc.project_id, _raw_removed_date: null}, {fields: {_id: 1, parents: 1, due_date: 1, seqId: 1}}).forEach (task) ->
      project_tasks[task._id] = task

      return

    due_date_updates = {}
    getAllDirectSubTasks = (parent_task) ->
      ids = {}

      for id, task of project_tasks
        if task.parents?[parent_task]
          ids[id] = true

      return ids

    getAllSubTasks = (parent_task) ->
      all_ids = {}

      for id of getAllDirectSubTasks(parent_task)
        all_ids[id] = true

        for sub_id of getAllSubTasks(id)
          all_ids[sub_id] = true

      return all_ids

    getTasksByStringOfSeqIds = (s) ->
      seq_set = new Set()

      s.split(",").forEach (s_id) ->
        seq_set.add(parseInt(s_id.trim(), 10))

      ids = new Set()
      for id, task of project_tasks
        if seq_set.has(task.seqId)
          ids.add id

      return ids

    isDateChanged = (new_date, task_id) ->
      if due_date_updates[task_id]
        if due_date_updates[task_id] != new_date
          return true
      else # does not exist in the due_date_updates
        if not _.isEmpty project_tasks[task_id].due_date
          if project_tasks[task_id].due_date != new_date
            return true
        else
          if not _.isEmpty new_date
            return true

      return false

    getMaxDate = (task_id, max_date) ->
      due_date = null

      if not (due_date = due_date_updates[task_id])?
        due_date = project_tasks[task_id].due_date

      if due_date and (due_date > max_date or max_date == "")
        return due_date

      return max_date


    accepted_changes_set = {} # keys are tasks_ids vals are the amount of changes we currently accept for them
    max_accepted_changes_per_task = 10 # Allow up to max_accepted_changes_per_task, before assuming we got an infinite loop

    first_call = true
    runCommandsAffectedByTaskChange = (proposed_change_task_id, recursive) =>
      first_call = false
      # The purpose of recursion is to avoid infinite loop.

      # If we didn't have the infinte loop issue we could have let the hooks trigger the
      # derived changes.

      for command in commands
        new_date = null

        if command.command == "max_due_date_of_direct_subtasks"
          max_date = ""
          subtasks = getAllDirectSubTasks(command.task_id)
          if proposed_change_task_id of subtasks or task_doc._id == command.task_id
            for task_id of subtasks
              max_date = getMaxDate task_id, max_date

            if isDateChanged(max_date, command.task_id)
              new_date = max_date

        else if command.command == "max_due_date_of_all_subtasks"
          max_date = ""
          allSubtasks = getAllSubTasks(command.task_id)
          if proposed_change_task_id of allSubtasks or task_doc._id == command.task_id
            for task_id of allSubtasks
              max_date = getMaxDate task_id, max_date

            if isDateChanged(max_date, command.task_id)
              new_date = max_date

        else if command.command == "max_due_date_of"
          max_date = ""

          tasks = getTasksByStringOfSeqIds(command.params)
          if tasks.has(proposed_change_task_id) or (task_doc._id == command.task_id)
            tasks.forEach (task_id) ->
              max_date = getMaxDate task_id, max_date

            if isDateChanged(max_date, command.task_id)
              new_date = max_date

        else if command.command == "due_date_offset"
          task_seq = parseInt(command.params.split(",")[0].trim(), 10)
          offset = parseInt(command.params.split(",")[1].trim(), 10)

          calculated_date = ""
          ref_task_id = null

          for id, task of project_tasks
            if task.seqId == task_seq
              ref_task_id = task._id
              break

          if ref_task_id? and (ref_task_id == proposed_change_task_id or task_doc._id == command.task_id)
            if ref_task_id == proposed_change_task_id or task_doc._id == command.task_id
              if due_date_updates[ref_task_id]
                d = new Date(due_date_updates[ref_task_id])
                d.setDate(d.getDate() + offset)
                calculated_date = d.toISOString().substring(0, 10)
              else if project_tasks[ref_task_id].due_date
                d = new Date(task.due_date)
                d.setDate(d.getDate() + offset)
                calculated_date = d.toISOString().substring(0, 10)

              if isDateChanged(calculated_date, task_doc._id)
                new_date = calculated_date

        if new_date?
          if command.task_id of accepted_changes_set and (accepted_changes_set[command.task_id] + 1) > max_accepted_changes_per_task
            return false

          if not recursive or (first_call and task_doc._id == command.task_id) # if the task changed is the command's task, we are done here
            due_date_updates[command.task_id] = new_date
          else
            if command.task_id of accepted_changes_set
              accepted_changes_set[command.task_id] += 1
            else
              accepted_changes_set[command.task_id] = 1

            due_date_updates[command.task_id] = new_date

            ret = runCommandsAffectedByTaskChange command.task_id, recursive

            if ret == false
              params = @tasks_collection.findOne({_id:command.task_id})["backend_calc_field_cmd_params"]

              error = "Error: command caused infinte loop."

              if not _.isEmpty(params)
                error += " Parameters: #{params}"

              cached_command_doc = _.find commands, (cmd) -> cmd.task_id == command.task_id

              if not @isParamsValueIsSystemMessage(cached_command_doc.params)
                # Since we allow max_accepted_changes_per_task in case of infinite loop, we'll recognize the infinite loop
                # in (at least) the max_accepted_changes_per_task depth of the runCommandsAffectedByTaskChange, then each level
                # of the loop will start returning false and will attempt to set error message.
                # This ensures only the deepest level in which we recognized the infinite loop will set the infinite loop error.
                @tasks_collection.direct.update(command.task_id, {$set:{"#{"backend_calc_field_cmd_params"}": error, due_date: "", updated_by: user_id}}, {bypassCollection2: true})

              cached_command_doc.params = error

              delete due_date_updates[command.task_id]
              delete due_date_updates[proposed_change_task_id]

              return false

            due_date_updates[command.task_id] = new_date
            delete accepted_changes_set[command.task_id]

      return true

    runCommandsAffectedByTaskChange task_doc._id, true

    for task_id, new_due_date of due_date_updates
      @updateDueDate task_id, new_due_date, user_id

    return


  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @_stopEnabledProjectsCacheMaintainer()

    @destroyed = true

    @logger.debug "Destroyed"

    return