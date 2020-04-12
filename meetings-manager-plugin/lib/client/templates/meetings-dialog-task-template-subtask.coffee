Template.meetings_dialog_task_subtask.onCreated ->
  self = @
  @task_subject_diverged_ra = new ReactiveVar(false)
  @autorun =>
    self.task_obj = JD.collections.Tasks.findOne {_id: @data.task_id}
  return

Template.meetings_dialog_task_subtask.onRendered ->
  instance = this

  $(".task-due-date").datepicker
    dateFormat: "yy-mm-dd"
    onSelect: (date) ->
      tmpl = Blaze.getView($(this)[0]).parentView._templateInstance
      if tmpl.task_obj
        if tmpl.data.may_edit
          JD.collections.Tasks.update {_id: tmpl.task_obj._id}, {$set: {due_date: date}}
      return

  return

Template.meetings_dialog_task_subtask.helpers
  seqId: ->
    return Template.instance().task_obj?.seqId

  taskSubjectDiverged: ->
    return Template.instance().task_subject_diverged_ra.get()

  divergedSubjectTitle: ->
    if Template.instance().task_subject_diverged_ra.get()
      return "Task subject diverged."
    return ""

  taskPriority: ->
    priority = Template.instance().task_obj?.priority
    color = JustdoColorGradient.getColorRgbString priority
    return color

  subject: ->
    task_meeting_title = ""
    meeting_id = Template.instance().data.meeting_id;
    parent_task_id = Template.instance().data.parent_task_id;
    this_task_id = Template.instance().data.task_id;
    meeting_task = APP.meetings_manager_plugin.meetings_manager.meetings_tasks.findOne({meeting_id: meeting_id, task_id: parent_task_id})
    for added_task in meeting_task.added_tasks
      if added_task.task_id == this_task_id
        task_meeting_title = added_task.title
        break

    if Template.instance().task_obj?.title != task_meeting_title
      Template.instance().task_subject_diverged_ra.set true
    else
      Template.instance().task_subject_diverged_ra.set false

    return task_meeting_title

  dueDate: ->
    dueDate = Template.instance().task_obj?.due_date
    if dueDate?
      return moment(new Date(dueDate)).format("D MMM YYYY")
    return "Due Date"

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

  allowAddingTasks: ->
    return Template.instance().data.may_edit

  # Because of the issue with Blaze contenteditable reactivity, we need to isolate editable content from Blaze generated DOM elements using this Helper.
  taskSubjectBox: (subject) ->
    if !subject?
      subject = ""
    return """<div class="task-subject-box flex-grow-1" contenteditable="true" placeholder="Untitled Task...">""" + subject + """</div>"""


Template.meetings_dialog_task_subtask.events
  "blur .task-subject-box": (e, tpl) ->
    if tpl.task_obj
      subject = $(e.target).text()
      if tpl.data.may_edit
        JD.collections.Tasks.update {_id: tpl.task_obj._id}, {$set: {title: subject}}
        APP.meetings_manager_plugin.meetings_manager.saveSubTaskSubject tpl.data.meeting_id, tpl.data.parent_task_id, tpl.task_obj._id, subject
    return

  "click .select-pending-owner": (e, tpl) ->
    if not tpl.task_obj
      return
    if not tpl.data.may_edit
      return

    selected_user_id = e.target.getAttribute("user_id")
    #if set to 'me'
    if selected_user_id == Meteor.userId()
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

  "click .remove-sub-task": (e, tmpl) ->

    bootbox.confirm
      message: "You are about to delete the task (not only remove it from the meeting's agenda). Please confirm."
      className: "bootbox-new-design members-management-alerts"
      closeButton: false
      callback: (res) =>
        if res
          meeting_id = tmpl.data.meeting_id
          subtask_id = tmpl.data.task_id
          parent_task_id = tmpl.data.parent_task_id
          APP.meetings_manager_plugin.meetings_manager.removeSubtaskFromMeeting meeting_id, parent_task_id, subtask_id
          Meteor.setTimeout =>
            Session.set "updateTaskOrder", true
          , 100
          return
        return
    return

  "click .task-subject-box, click .task-priority": (e, tmpl) ->
    task_id = tmpl.data.task_id
    gcm = APP.modules.project_page.getCurrentGcm()
    gcm.setPath(["main", task_id], {collection_item_id_mode: true})
    return
