Template.meetings_dialog_task_subtask.onCreated ->
  return

Template.meetings_dialog_task_subtask.helpers
  taskOwner: ->
    if (task_obj = Template.instance().data)?
      if not (owner = task_obj.pending_owner_id)?
        owner = task_obj.owner_id
      return Meteor.users.findOne {_id: owner}
    return

  tasksUsers: ->
    task_obj = Template.instance().data
    return Meteor.users.find {_id: {$in: task_obj.users}}


Template.meetings_dialog_task_subtask.events
  "blur .task-subject-box": (e, tpl) ->
    JD.collections.Tasks.update {_id: tpl.data._id}, {$set: {title: e.target.value}}
    return

  "blur .task-due-date": (e, tpl) ->
    JD.collections.Tasks.update {_id: tpl.data._id}, {$set: {due_date: e.target.value}}
    return


  "click .select-pending-owner": (e, tpl) ->
    selected_user_id = e.target.getAttribute("user_id")
    #if set to 'me'
    if selected_user_id == Meteor.userId()
      JD.collections.Tasks.update _id: tpl.data._id, {
        $set: {owner_id: selected_user_id}
        $unset: {"pending_owner_id": ""}
      }
      return
    #else if set to the task owner
    if selected_user_id == tpl.data.owner_id
      JD.collections.Tasks.update _id: tpl.data._id,
        $unset: "pending_owner_id"
      return
    #else
    JD.collections.Tasks.update _id: tpl.data._id,
      $set: {pending_owner_id: selected_user_id}
    return



