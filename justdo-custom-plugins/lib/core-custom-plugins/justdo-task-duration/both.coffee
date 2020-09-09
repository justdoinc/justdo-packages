APP.justdo_custom_plugins.justdo_task_duration = {
  recalculateDatesAndDuration_getRequiredTaskFields: ->
    return _.extend {}, {
      start_date: 1
      end_date: 1
      "#{JustdoCustomPlugins.justdo_task_duration_pseudo_field_id}": 1
      project_id: 1
      pending_owner_id: 1
      owner_id: 1
      "#{JustdoGridGantt.is_milestone_pseudo_field_id}": 1
    }

  recalculateDatesAndDuration: (task_id_or_task, new_values) ->
    self = @

    if new_values.start_date isnt undefined and
        new_values["#{JustdoCustomPlugins.justdo_task_duration_pseudo_field_id}"] isnt undefined and 
        new_values.end_date isnt undefined
      # The change really means to set all three values manully, no need to do any auto calculation
      return null

    if _.isString task_id_or_task
      task = APP.collections.Tasks.findOne task_id_or_task,
        fields: self.recalculateDatesAndDuration_getRequiredTaskFields()
    else
      task = task_id_or_task

    if not task?
      return null
    
    if task[JustdoGridGantt.is_milestone_pseudo_field_id] == "true" and isGridGanttEnabled task.project_id
      ret = {
        "#{JustdoCustomPlugins.justdo_task_duration_pseudo_field_id}": null
        start_date: null
        end_date: null
      }

      if new_values.start_date isnt undefined
        ret.start_date = ret.end_date = new_values.start_date
      else if new_values.end_date isnt undefined
        ret.start_date = ret.end_date = new_values.end_date
      else if task.start_date isnt undefined
        ret.start_date = ret.end_date = task.start_date
      
      return ret

    recal_fields = new Set ["start_date", "end_date", JustdoCustomPlugins.justdo_task_duration_pseudo_field_id]
    keep_fields = {}

    keep = (field, val) ->
      if val == null
        return true

      if recal_fields.has field
        recal_fields.delete field
        keep_fields[field] = val
      
      if recal_fields.size == 1 
        return true
      
      return false

    do ->
      if new_values.start_date isnt undefined and 
          keep "start_date", new_values.start_date
        return 
      if new_values[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id] isnt undefined and 
          keep JustdoCustomPlugins.justdo_task_duration_pseudo_field_id, new_values[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id]
        return
      if new_values.end_date isnt undefined and 
          keep "end_date", new_values.end_date
        return
      
      # The sequence of the if statements determine the keep priority of each field
      if task.start_date? and 
          keep "start_date", task.start_date
        return
      if task[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id]? and
          keep JustdoCustomPlugins.justdo_task_duration_pseudo_field_id, task[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id]
        return
      if task.end_date? and 
          keep "end_date", task.end_date
        return
      
      return
    
    if recal_fields.size > 1 # Cannot determine which field to recal
      return null
    
    owner_id = task.pending_owner_id or task.owner_id
    ret = null
    recal_fields.forEach (field) -> # Although using forEach here, it will only execute once because recal_fields will always have a size of 1
      if field == "start_date"
        keep_fields.start_date = _recalculateStartDate task.project_id, owner_id, keep_fields
      else if field == "end_date"
        keep_fields.end_date = _recalculateEndDate task.project_id, owner_id, keep_fields
      else if field == JustdoCustomPlugins.justdo_task_duration_pseudo_field_id
        keep_fields[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id] = _recalculateDuration task.project_id, owner_id, keep_fields

      return

    return keep_fields
  
  isPluginInstalled: (justdo_id) -> # XXX need to optimize
    justdo = APP.collections.Projects.findOne justdo_id,
      fields:
        conf: 1

    return justdo? and APP.projects.isPluginInstalledOnProjectDoc(JustdoCustomPlugins.justdo_task_duration_custom_feature_id, justdo)
}


isGridGanttEnabled = (justdo_id) ->
  return APP.justdo_grid_gantt.isGridGanttInstalledInJustDo justdo_id

_recalculateStartDate = (justdo_id, user_id, keep_fields) ->
  return APP.justdo_resources_availability.finishToStartForUser justdo_id, user_id, 
    keep_fields.end_date, keep_fields[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id], "days"
  
_recalculateEndDate = (justdo_id, user_id, keep_fields) ->
  return APP.justdo_resources_availability.startToFinishForUser justdo_id, user_id, 
    keep_fields.start_date, keep_fields[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id], "days"

_recalculateDuration = (justdo_id, user_id, keep_fields) ->
  {working_days, avail_hrs} = APP.justdo_resources_availability.userAvailabilityBetweenDates keep_fields.start_date, keep_fields.end_date, justdo_id, user_id

  return working_days