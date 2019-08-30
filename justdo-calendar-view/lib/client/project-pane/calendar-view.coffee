setDragAndDrop = ->
  $('.calendar_view_draggable').draggable
    cursor: 'move'
    helper: 'clone'
  $('.uni-date-formatter').draggable
    cursor: 'move'
    helper: 'clone'

  $('.calendar_view_droppable').droppable
    drop: (e, ui)->

      set_param = {}
      row_user_id = e.target.parentElement.attributes.user_id.value
      task_obj = APP.collections.Tasks.findOne({_id: ui.draggable[0].attributes.task_id.value})
      # calculating task owner as it is on the calendar
      owner_id = task_obj.owner_id
      if task_obj.pending_owner_id
        owner_id = task_obj.pending_owner_id
      # for changing followups (but not private followup), we also allow to change the owner
      if row_user_id != owner_id and ui.draggable[0].attributes.type.value == 'F'
        if Meteor.userId() == row_user_id
          set_param['owner_id'] = row_user_id
          set_param['pending_owner_id'] = null
        #if we return a task with pending owner to prev owner
        else if task_obj.owner_id == row_user_id and task_obj.pending_owner_id?
          set_param['pending_owner_id'] = null
        else
          set_param['pending_owner_id'] = row_user_id
      if ui.draggable[0].attributes.class.value.indexOf("calendar_view_draggable")>=0
        if ui.draggable[0].attributes.type.value == 'F'
          set_param['follow_up'] = e.target.attributes.date.value
          APP.collections.Tasks.update({_id: ui.draggable[0].attributes.task_id.value},
                                        $set:set_param
                                       )

        else if ui.draggable[0].attributes.type.value == 'P'
          set_param['priv:follow_up'] = e.target.attributes.date.value
          APP.collections.Tasks.update({_id: ui.draggable[0].attributes.task_id.value},
            $set: set_param
          )
      return
  return

Template.justdo_calendar_project_pane.onCreated ->
  @view_start_date = new ReactiveVar
  #calculate the first day to display based on the beginning of the week of the user
  @resetFirstDay = ->
    d = new Date
    dow = d.getDay()
    user_first_day_of_week = 1
    if Meteor.user().profile?.first_day_of_week?
      user_first_day_of_week = Meteor.user().profile.first_day_of_week

    if dow < user_first_day_of_week
      dow += 7
    d.setDate(d.getDate() - (dow - user_first_day_of_week))
    @view_start_date.set(d)
    return
  @resetFirstDay()

  return

Template.justdo_calendar_project_pane.helpers
  title_date: ->
    return moment(Template.instance().view_start_date.get()).format("YYYY-MM-DD")

  currentUserId: ->
    return Meteor.userId()

  allOtherUsers: ->
    return _.map Meteor.users.find({_id: {$ne: Meteor.userId()}},{fields: {_id:1}}).fetch(), (u)->
     return u._id

  datesToDisplay: ->
    dates = []
    d = moment(Template.instance().view_start_date.get())
    for i in [0..6]
      dates.push(d.format("YYYY-MM-DD"))
      d.add(1,"days")
    return dates

Template.justdo_calendar_project_pane.events
  "click .calendar-view-prev-week": ->
    date = moment(Template.instance().view_start_date.get())
    date.subtract(7, 'days');
    Template.instance().view_start_date.set(date)
    return

  "click .calendar-view-prev-day": ->
    date = moment(Template.instance().view_start_date.get())
    date.subtract(1, 'days');
    Template.instance().view_start_date.set(date)
    return

  "click .calendar-view-next-day": ->
    date = moment(Template.instance().view_start_date.get())
    date.add(1, 'days');
    Template.instance().view_start_date.set(date)
    return

  "click .calendar-view-next-week": ->
    date = moment(Template.instance().view_start_date.get())
    date.add(7, 'days');
    Template.instance().view_start_date.set(date)
    return

  "click .calendar-view-back-to-today": ->
    Template.instance().resetFirstDay()
    return

Template.justdo_calendar_project_pane_user_view.onCreated ->
  self = @
  @days_matrix = new ReactiveVar([])
  @autorun =>
    data = Template.currentData()

    #days_matrix is eventually a matrix that represents the table that we are going to display,
    # where each column represents a day and each cell holds a task in such a way that we could later
    # display the table easily. after calculation, we set it into the reactive var, and trigger the templates
    # invalidation


    days_matrix = []
    for i in [0..data.dates_to_display.length]
      days_matrix.push []
    self.days_matrix.set(days_matrix)

    first_date_to_display = data.dates_to_display[0]
    last_date_to_display = data.dates_to_display[data.dates_to_display.length-1]

    planned_seconds_field = "p:rp:b:work-hours_p:b:user:#{data.user_id}"
    executed_seconds_field = "p:rp:b:work-hours_e:b:user:#{data.user_id}"

    dates_part = [
      #regular followup date
      {follow_up: {$in: data.dates_to_display}},
      #private followup date
      {priv:follow_up: {$in: data.dates_to_display}},
      #due date in between the dates
      {$and: [
        due_date: {$gte: first_date_to_display},
        due_date: {$lte: last_date_to_display}
      ]},
      #start date in between the dates
      {$and: [
        start_date: {$gte: first_date_to_display},
        start_date: {$lte: last_date_to_display}
      ]},
      #start date before and due date after
      {$and: [
        start_date: {$lt: first_date_to_display},
        due_date: {$gt: last_date_to_display}
      ]}
    ]

    if data.user_id == "unassigned_user_hours"
      owner_part = [
        {"p:rp:b:unassigned-work-hours": {$gt: 0}}
      ]
    else
      owner_part = [
          {owner_id:  data.user_id}, #user is owner, and there is no pending owner
          {pending_owner_id: data.user_id}, #user is the pending owner
          {"#{planned_seconds_field}": {$gt: 0}} #user has planned hours on the task
        ]

    query_parts = []
    query_parts.push {$or: dates_part}
    query_parts.push {$or: owner_part}

    options =
      fields:
        _id: 1
        title: 1
        start_date: 1
        due_date: 1
        owner_id: 1
        pending_owner_id: 1
        "priv:follow_up": 1
        follow_up: 1
        "#{planned_seconds_field}": 1
        "#{executed_seconds_field}": 1
        "p:rp:b:unassigned-work-hours": 1

    APP.collections.Tasks.find({$and: query_parts},options).forEach (task)->
      #deal with  regular followups
      if task.follow_up and data.dates_to_display.indexOf(task.follow_up) >-1
        day_index = data.dates_to_display.indexOf(task.follow_up)
        day_column = days_matrix[day_index]
        row_index = 0
        while true
          if !day_column[row_index]?

            day_column[row_index] =
              task:
                id: task._id
                title: task.title
                pending_owner_id: task.pending_owner_id
                owner_id: task.owner_id
              type: 'F'# F for followup, P for private followup, R for regular
              span: 1
            break
          row_index++

      #deal with private followups
      if task['priv:follow_up'] and data.dates_to_display.indexOf(task['priv:follow_up']) >-1 and data.user_id == Meteor.userId()
        day_index = data.dates_to_display.indexOf(task['priv:follow_up'])
        day_column = days_matrix[day_index]
        row_index = 0
        while true
          if !day_column[row_index]?
            day_column[row_index] =
              task:
                id: task._id
                title: task.title
                pending_owner_id: task.pending_owner_id
                owner_id: task.owner_id
              type: 'P' # F for followup, P for private followup, R for regular
              span: 1
            break
          row_index++

      #deal with regular tasks
      if (task.start_date? and task.start_date >= first_date_to_display and task.start_date <= last_date_to_display) or
         (task.due_date? and task.due_date >= first_date_to_display and task.due_date <= last_date_to_display) or
         (task.start_date? and task.due_date? and task.start_date<first_date_to_display and task.due_date>last_date_to_display)
        start_date = ""
        starts_before_view = false
        if task.start_date?
          start_date = task.start_date
        else
          start_date = task.due_date
        end_date = ""
        ends_after_view = false
        if task.due_date?
          end_date = task.due_date
        else
          end_date = task.start_date
        start_day_index = data.dates_to_display.indexOf(start_date)
        if start_day_index == -1
          start_day_index = 0
          starts_before_view = true
        end_day_index = data.dates_to_display.indexOf(end_date)
        if end_day_index == -1
          end_day_index = data.dates_to_display.length-1
          ends_after_view = true

        # deal in situations where the start date is after the due date...
        start_date_after_due_date = false
        if end_day_index < start_day_index
          start_day_index = end_day_index
          start_date_after_due_date = true

        # find a row in the matrix where all days are free
        row_index = 0
        while true
          row_is_free = true
          for column_index in [start_day_index..end_day_index]
            if days_matrix[column_index][row_index]?
              row_is_free = false
          if row_is_free

            planned_seconds = task[planned_seconds_field]
            if data.user_id == "unassigned_user_hours"
              planned_seconds = task["p:rp:b:unassigned-work-hours"]

            days_matrix[start_day_index][row_index] =
              task:
                id: task._id
                title: task.title
                pending_owner_id: task.pending_owner_id
                owner_id: task.owner_id
                planned_seconds: planned_seconds
                executed_seconds: task[executed_seconds_field]

              type: 'R' # F for followup, P for private followup, R for regular
              span: end_day_index-start_day_index + 1
              starts_before_view: starts_before_view
              ends_after_view: ends_after_view
              start_date_after_due_date: start_date_after_due_date



            if start_day_index != end_day_index
              for i in [start_day_index+1..end_day_index]
                days_matrix[i][row_index] =
                  slot_is_taken: true

            break
          row_index++

      self.days_matrix.set(days_matrix)

      Tracker.afterFlush ->
        setDragAndDrop()
      return
    return
  return

Template.justdo_calendar_project_pane_user_view.onRendered ->
  setDragAndDrop()
  return

Template.justdo_calendar_project_pane_user_view.helpers

  userId: ->
    return Template.instance().data.user_id

  dimWhenPendingOwner: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=0
      if (info=matrix[col_num]?[row_num])
        if info.task?.pending_owner_id? and info.task.owner_id == Template.instance().data.user_id
          return "ownership_transfer_in_progress"
    return ""
  rowNumbers: ->
    days_matrix = Template.instance().days_matrix.get()
    ret = 1
    for i in [0..Template.instance().data.dates_to_display.length]
      if days_matrix[i]?.length > ret
        ret = days_matrix[i].length
    return [0..ret-1]

  topLeftCell: ->
    return (Template.parentData()==0 and @+1==1)

  leftCell: ->
    return (@+1==1)


  colNumbers: ->
    return [0..Template.instance().data.dates_to_display.length]

  numberOfRows: ->
    days_matrix = Template.instance().days_matrix.get()
    ret = 1 # we start with 1 because we need at least one raw for the user name
    for i in [0..Template.instance().data.dates_to_display.length]
      if days_matrix[i]?.length > ret
        ret = days_matrix[i].length
    return ret


  userObj: ->
    return  Meteor.users.findOne(Template.instance().data.user_id)

  rowForUnassignedUser:->
    return (Template.instance().data.user_id =="unassigned_user_hours")

  taskTitle: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=0
      if (info=matrix[col_num]?[row_num])
        return info.task.title
    return ""

  taskId: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=0
      if (info=matrix[col_num]?[row_num])
        if info.task?
          return info.task.id
    return ""

  startsBeforeView: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=0
      if (info=matrix[col_num]?[row_num])
        if info.starts_before_view?
          return info.starts_before_view
    return false

  endsAfterView: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=0
      if (info=matrix[col_num]?[row_num])
        if info.ends_after_view?
          return info.ends_after_view
    return false


  colSpan: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=0
      if (info=matrix[col_num]?[row_num])
        return "#{info.span}"
    return "1"


  skipTD: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=0
      if (info=matrix[col_num]?[row_num])
        return info.slot_is_taken
    return false

  type: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=0
      if (info=matrix[col_num]?[row_num])
        return info.type
    return ""

  startDateAfterDueDate: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=0
      if (info=matrix[col_num]?[row_num])
        if info.start_date_after_due_date
          return true
    return false

  isFollowupDate: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=0
      if (info=matrix[col_num]?[row_num])
        return info.type == 'F'
    return false

  isPrivateFollowupDate: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=0
      if (info=matrix[col_num]?[row_num])
        return info.type == 'P'
    return false

  plannedHours: ->

    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=0
      if (info=matrix[col_num]?[row_num])
        if info.type == 'R' and info.task.planned_seconds > 0
          seconds = info.task.planned_seconds
          if info.task.executed_seconds
            seconds -= info.task.executed_seconds
          overtime = false
          if seconds < 0
            seconds = -seconds
            overtime = true
          minutes = Math.floor(seconds/60)
          hours = Math.floor(minutes/60)
          mins = minutes - hours*60
          if ! overtime
            left = "left"
            if Template.instance().data.user_id == "unassigned_user_hours"
              left = ""
            return "[#{hours}:#{JustdoHelpers.padString(mins, 2)} H #{left}]"
          return "[#{hours}:#{JustdoHelpers.padString(mins, 2)} H overtime]"
    return ""



  isRegularTask: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=0
      if (info=matrix[col_num]?[row_num])
        return info.type == 'R'
    return false

  columnDate: ->
    return Template.instance().data.dates_to_display[@-1]


Template.justdo_calendar_project_pane_user_view.events
  "click .calendar_task_cell": (e, tpl)->
    if (task_id = e.target.getAttribute("task_id"))?
      gcm = APP.modules.project_page.getCurrentGcm()
      gcm.setPath(["main", task_id], {collection_item_id_mode: true})
      return
    return

  "mouseover .highlight_on_mouse_in" : (e, tpl)->
    e.target.style.backgroundColor = "lightyellow"
    return

  "mouseout .highlight_on_mouse_in" : (e, tpl)->
    e.target.style.backgroundColor = ""
    return




