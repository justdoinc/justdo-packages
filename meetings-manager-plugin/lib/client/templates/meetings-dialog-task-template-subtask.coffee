Template.meetings_dialog_task_subtask.onCreated ->
  self = @
  @autorun =>
    self.task_obj = JD.collections.Tasks.findOne {_id: @data.task_id}
  return

Template.meetings_dialog_task_subtask.onRendered ->
  return

Template.meetings_dialog_task_subtask.helpers
  seqId: ->
    return Template.instance().task_obj?.seqId

  subject: ->
    return Template.instance().task_obj?.title

  dueDate: ->
    return Template.instance().task_obj?.due_date

  taskOwner: ->
    if (task_obj = Template.instance().task_obj)
      if not (owner = task_obj.pending_owner_id)?
        owner = task_obj.owner_id
      return Meteor.users.findOne {_id: owner}
    return

  tasksUsers: ->
    if (task_obj = Template.instance().task_obj)?
      return Meteor.users.find {_id: {$in: task_obj.users}}
    return

  readOnly: ->
    if not Template.instance().data.may_edit
      return "readonly"
    return ""

  disabled: ->
    if not Template.instance().data.may_edit
      return "disabled"
    return ""


Template.meetings_dialog_task_subtask.events
  "blur .task-subject-box": (e, tpl) ->
    if tpl.task_obj
      subject = e.target.value
      JD.collections.Tasks.update {_id: tpl.task_obj._id}, {$set: {title: subject}}
      APP.meetings_manager_plugin.meetings_manager.saveSubTaskSubject tpl.data.meeting_id, tpl.data.parent_task_id, tpl.task_obj._id, subject
    return

  "blur .task-due-date": (e, tpl) ->
    if tpl.task_obj
      JD.collections.Tasks.update {_id: tpl.task_obj._id}, {$set: {due_date: e.target.value}}
    return


  "click .select-pending-owner": (e, tpl) ->
    if not tpl.task_obj
      return
    selected_user_id = e.target.getAttribute("user_id")
    #if set to 'me'
    if selected_user_id == Meteor.userId()
#      JD.collections.Tasks.update _id: tpl.data.task._id, {
      JD.collections.Tasks.update _id: tpl.task_obj._id, {
        $set: {owner_id: selected_user_id}
        $unset: {"pending_owner_id": ""}
      }
      return
    #else if set to the task owner
    if selected_user_id == tpl.task_obj.owner_id
      JD.collections.Tasks.update _id: tpl.task_obj.task._id,
        $unset: "pending_owner_id"
      return
    #else
    JD.collections.Tasks.update _id: tpl.task_obj._id,
      $set: {pending_owner_id: selected_user_id}
    return



