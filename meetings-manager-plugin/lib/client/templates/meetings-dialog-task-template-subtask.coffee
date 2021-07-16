Template.meetings_dialog_task_subtask.onCreated ->
  self = @
  @task_subject_diverged_ra = new ReactiveVar(false)
  @autorun =>
    task_id = @data.task_id
    JD.subscribeItemsAugmentedFields [task_id], ["users"]
    self.task_obj = JD.collections.Tasks.findOne task_id
    self.task_aug = APP.collections.TasksAugmentedFields.findOne task_id
  return

Template.meetings_dialog_task_subtask.helpers
  onRerender: ->  # A hack to bind handlers on template rerendered
    tpl = Template.instance()
    Meteor.defer ->
      tpl.$(".task-due-date").datepicker
        dateFormat: "yy-mm-dd"
        onSelect: (date) ->
          tmpl = Blaze.getView($(tpl)[0]).parentView._templateInstance
          if tmpl.task_obj
            if tmpl.data.may_edit
              JD.collections.Tasks.update {_id: tmpl.task_obj._id}, {$set: {due_date: date}}
          return

    return

  taskId: ->
    return Template.instance.task_obj?._id

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
    date_format = Meteor.user().profile.date_format
    if dueDate?
      return moment(dueDate).format(date_format)
    return null
    
  dueDateLabel: ->APP.collections.Tasks.simpleSchema()._schema["due_date"].label

  taskOwner: ->
    if (task_obj = Template.instance().task_obj)
      if not (owner = task_obj.pending_owner_id)?
        owner = task_obj.owner_id
      return Meteor.users.findOne {_id: owner}
    return

  tasksUsers: ->
    if (task_aug = Template.instance().task_aug)?
      return Meteor.users.find {_id: {$in: task_aug.users}}
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
    return """<div class="task-subject-box flex-grow-1" contenteditable="true" placeholder="Untitled Task..." data-task-id="#{Template.instance().task_obj._id}">""" + subject + """</div>"""

  onSaveMeetingNote: ->
    meeting_task_id = this.meeting_task_id
    added_task_id = this.task_id
    return (changes) =>
      changes =
        note_lock: changes.lock
        note: changes.content
        
      APP.meetings_manager_plugin.meetings_manager.updateAddedTaskNote meeting_task_id, added_task_id, changes, (err) ->
        if err?
          console.error err

        return
      
      return

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

  "click .task-subject-box, click .task-priority, click .task-seqId-box": (e, tmpl) ->
    task_id = tmpl.data.task_id
    gcm = APP.modules.project_page.getCurrentGcm()
    gcm.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(task_id)
    return
