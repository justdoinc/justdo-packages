# Catching install/uninstall of justdo_task_duration and justdo_grid_gantt
APP.collections.Projects.after.update (user_id, doc, field_names, modifier, options) ->
  if not (new_custom_features = modifier?.$set?["conf.custom_features"])?
    return true

  old_custom_features = @previous?.conf?.custom_features or []
  added_custom_features = _.difference new_custom_features, old_custom_features
  removed_custom_features = _.difference old_custom_features, new_custom_features
  
  if JustdoCustomPlugins.justdo_task_duration_custom_feature_id in added_custom_features
    recalculateTasksDuration doc._id, {}
  
  if (JustdoGridGantt.project_custom_feature_id in added_custom_features or
      JustdoGridGantt.project_custom_feature_id in removed_custom_features) and
      APP.justdo_custom_plugins.justdo_task_duration.isPluginInstalled doc._id
    # recalculate milestones duration
    recalculateTasksDuration doc._id,
      "#{JustdoGridGantt.is_milestone_pseudo_field_id}": "true"

  return

recalculateTasksDuration = (justdo_id, filters) ->
  target_justdo = APP.collections.Projects.findOne justdo_id,
    fields:
      _id: 1
      conf: 1
  
  if not target_justdo?
    throw new Meteor.Error "justdo-not-found", "Justdo not found"

  if not filters?
    filters = {}
  
  filters.project_id = justdo_id

  is_grid_gantt_enabled = APP.justdo_grid_gantt.isGridGanttInstalledInJustDo target_justdo

  fields = _.extend {
    _id: 1
    start_date: 1
    end_date: 1
    pending_owner_id: 1
    owner_id: 1
    "#{JustdoCustomPlugins.justdo_task_duration_pseudo_field_id}": 1
    "#{JustdoGridGantt.is_milestone_pseudo_field_id}": 1
  }, APP.justdo_custom_plugins.justdo_task_duration.recalculateDatesAndDuration_getRequiredTaskFields()

  APP.collections.Tasks.find filters,
    fields: fields
  .forEach (task) ->
    changes = APP.justdo_custom_plugins.justdo_task_duration.recalculateDatesAndDuration task,
      start_date: task.start_date
      end_date: task.end_date

    new_duration = changes?[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id]

    if not changes? or not task[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id]? and new_duration == null or
        task[JustdoCustomPlugins.justdo_task_duration_pseudo_field_id] == new_duration
      return

    APP.collections.Tasks.update task._id,
      $set: changes

  return
