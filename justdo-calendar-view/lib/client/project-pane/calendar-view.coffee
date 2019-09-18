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

      # for changing followups or regular tasks (but not private followup), we also allow to change the owner
      if row_user_id != owner_id and
          (ui.draggable[0].attributes.type.value == 'F' or ui.draggable[0].attributes.type.value == 'R')

        if Meteor.userId() == row_user_id
          set_param['owner_id'] = row_user_id
          set_param['pending_owner_id'] = null
        #if we return a task with pending owner to prev owner
        else if task_obj.owner_id == row_user_id and task_obj.pending_owner_id?
          set_param['pending_owner_id'] = null
        else
          set_param['pending_owner_id'] = row_user_id

      if ui.draggable[0].attributes.class.value.indexOf("calendar_view_draggable")>=0
        #dealing with Followups:
        if ui.draggable[0].attributes.type.value == 'F'
          set_param['follow_up'] = e.target.attributes.date.value
          APP.collections.Tasks.update({_id: ui.draggable[0].attributes.task_id.value},
                                        $set:set_param
                                       )
        #dealing with Private followups
        else if ui.draggable[0].attributes.type.value == 'P'
          set_param['priv:follow_up'] = e.target.attributes.date.value
          APP.collections.Tasks.update({_id: ui.draggable[0].attributes.task_id.value},
            $set: set_param
          )

        #dealing with Private followups
        else if ui.draggable[0].attributes.type.value == 'R'
          # from the query definitions we must have at least one of start or end dates.
          original_start_date = task_obj.start_date
          if !original_start_date
            original_start_date = task_obj.end_date

          original_end_date = task_obj.end_date
          if !original_end_date
            original_end_date = task_obj.start_date

          new_start_date = e.target.attributes.date.value
          #calculating the new end date taking days off into consideration:
          new_end_date_moment = moment(e.target.attributes.date.value)
          if original_start_date<original_end_date
            d = moment(original_start_date)
            while d < moment(original_end_date)
              if justdo_level_workdays.weekly_work_days[d.day()] == 1
                new_end_date_moment.add(1,'days')
                #skip non working days
                while(justdo_level_workdays.weekly_work_days[new_end_date_moment.day()] == 0)
                  new_end_date_moment.add(1,'days')
              d.add(1, 'days')

          set_param['start_date'] = new_start_date
          set_param['end_date'] = new_end_date_moment.format("YYYY-MM-DD")

          #todo: calculate how to move the due-date
          APP.collections.Tasks.update({_id: ui.draggable[0].attributes.task_id.value},
            $set: set_param
          )
      return #end of drop

  return

justdo_level_workdays = {} #intentionally making this one a non-reactive var, otherwise we will hit it too many times

Template.justdo_calendar_project_pane.onCreated ->
  self = @

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

  #scrolling left and right control flow
  @scroll_left_right_handler = null

  @setToPrevWeek = ->
    date = moment(@view_start_date.get())
    date.subtract(7, 'days');
    @view_start_date.set(date)
    return

  @setToNextWeek = ->
    date = moment(@view_start_date.get())
    date.add(7, 'days');
    @view_start_date.set(date)
    return

  @onSetScrollLeft = ->
    self.scroll_left_right_handler = setInterval( =>
      self.setToPrevWeek()
      return
    ,
      2000
    )
    return

  @onSetScrollRight = ->
    self.scroll_left_right_handler = setInterval( =>
      self.setToNextWeek()
      return
    ,
      2000
    )
    return

  @onUnsetScrollLeftRight = ->
    if self.scroll_left_right_handler
      clearInterval(self.scroll_left_right_handler)
      self.scroll_left_right_handler = null
    return

  #todo: become future compatible - the project level workdays and holidays will come from the delivery planner
  #todo: check with Daniel how to ensure plugins dependancies during load time.
  #todo: once we apply project filters, take the workdays from the project record.

  if APP.justdo_delivery_planner?.justdo_level_workdays
    @autorun =>
      justdo_level_workdays = APP.justdo_delivery_planner.justdo_level_workdays.get()
  else
    justdo_level_workdays =
      weekly_work_days: [0, 1, 1, 1, 1, 1, 0] #sunday at index 0, default set to Monday-Friday
      specific_off_days: [] # and no holidays by default


  return # end onCreated

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

  formatDate: ->
    return moment(@).format("ddd, Mo")

Template.justdo_calendar_project_pane.events
  "click .calendar-view-prev-week": ->
    Template.instance().setToPrevWeek()
    return

  "click .calendar-view-prev-day": ->
    Template.instance().setToNextWeek()
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
        end_date: {$gte: first_date_to_display},
        end_date: {$lte: last_date_to_display}
      ]},
      #start date in between the dates
      {$and: [
        start_date: {$gte: first_date_to_display},
        start_date: {$lte: last_date_to_display}
      ]},
      #start date before and due date after
      {$and: [
        start_date: {$lt: first_date_to_display},
        end_date: {$gt: last_date_to_display}
      ]}
    ]

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
        seqId: 1
        title: 1
        start_date: 1
        due_date: 1
        end_date: 1
        owner_id: 1
        state: 1
        pending_owner_id: 1
        "priv:follow_up": 1
        follow_up: 1
        "#{planned_seconds_field}": 1
        "#{executed_seconds_field}": 1
        "p:rp:b:unassigned-work-hours": 1

    APP.collections.Tasks.find({$and: query_parts},options).forEach (task)->

      task_details =
        _id: task._id
        title: task.title
        pending_owner_id: task.pending_owner_id
        owner_id: task.owner_id
        sequence_id: task.seqId
        end_date: task.end_date
        state: task.state

      #deal with  regular followups

      if task.follow_up and
            (task.owner_id == data.user_id or task.pending_owner_id == data.user_id) and
            data.dates_to_display.indexOf(task.follow_up) >-1
        day_index = data.dates_to_display.indexOf(task.follow_up)
        day_column = days_matrix[day_index]
        row_index = 0
        while true
          if !day_column[row_index]?

            day_column[row_index] =
              task: task_details
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
              task: task_details
              type: 'P' # F for followup, P for private followup, R for regular
              span: 1
            break
          row_index++

      #deal with regular tasks
      if (task.start_date? and task.start_date >= first_date_to_display and task.start_date <= last_date_to_display) or
         (task.end_date? and task.end_date >= first_date_to_display and task.end_date <= last_date_to_display) or
         (task.start_date? and task.end_date? and task.start_date < first_date_to_display and task.end_date > last_date_to_display)
        start_date = ""
        starts_before_view = false
        if task.start_date?
          start_date = task.start_date
        else
          start_date = task.end_date
        end_date = ""
        ends_after_view = false
        if task.end_date?
          end_date = task.end_date
        else
          end_date = task.start_date
        start_day_index = data.dates_to_display.indexOf(start_date)
        if start_day_index == -1 and start_date < data.dates_to_display[0]
          start_day_index = 0
          starts_before_view = true
        end_day_index = data.dates_to_display.indexOf(end_date)
        if end_day_index == -1 and end_date > data.dates_to_display[data.dates_to_display.length-1]
          end_day_index = data.dates_to_display.length-1
          ends_after_view = true

        # deal in situations where the start date is after the due date...
        start_date_after_due_date = false
        if end_date < start_date
          start_date_after_due_date = true
          if end_day_index >= 0
            start_day_index = end_day_index
          else if start_day_index >= 0
            end_day_index = start_day_index
          # else should never happen

        # find a row in the matrix where all days are free
        row_index = 0
        while true
          row_is_free = true
          for column_index in [start_day_index..end_day_index]
            if days_matrix[column_index][row_index]?
              row_is_free = false
          if row_is_free

            task_details.planned_seconds = task[planned_seconds_field]
            task_details.executed_seconds = task[executed_seconds_field]

            days_matrix[start_day_index][row_index] =
              task: task_details
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

Template.justdo_calendar_project_pane_user_view.onRendered ->
  setDragAndDrop()
  return

Template.justdo_calendar_project_pane_user_view.helpers
  userId: ->
    return Template.instance().data.user_id

  dimWhenPendingOwner: ->
    if @task?.pending_owner_id? and @task.owner_id == Template.instance().data.user_id
          return "ownership_transfer_in_progress"
    return ""

  rowNumbers: ->
    days_matrix = Template.instance().days_matrix.get()
    ret = 1
    for i in [0..Template.instance().data.dates_to_display.length]
      if days_matrix[i]?.length > ret
        ret = days_matrix[i].length
    return [0..ret-1]

  firstRow: ->
    return (@+1)==1

  markDaysOff: ->
    column_date = Template.instance().data.dates_to_display[@]
    z = moment(column_date).day();
    if justdo_level_workdays.weekly_work_days[moment(column_date).day()] == 0
      return "calendar_view_mark_days_off"
    return ""

  colNumbers: ->
    return [0..Template.instance().data.dates_to_display.length-1]

  numberOfRows: ->
    days_matrix = Template.instance().days_matrix.get()
    ret = 1 # we start with 1 because we need at least one raw for the user name
    for i in [0..Template.instance().data.dates_to_display.length]
      if days_matrix[i]?.length > ret
        ret = days_matrix[i].length
    return ret


  userObj: ->
    return  Meteor.users.findOne(Template.instance().data.user_id)

  taskId: ->
    col_num = @
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if (info=matrix[col_num]?[row_num])
      if info.task?
        return info.task._id
    return ""

  startsBeforeView: ->
    return @starts_before_view and @type == 'R'

  endsAfterView: ->
    return @ends_after_view and @type == 'R'

  skipTD: ->
    col_num = @
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if (info=matrix[col_num]?[row_num])
      return info.slot_is_taken
    return false

  cellData: ->
    col_num = @
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()
    return matrix[col_num]?[row_num]

  startDateAfterDueDate: ->
    return @start_date_after_due_date

  plannedHours: ->
    if @type == 'R' and @task.planned_seconds > 0
      seconds = @task.planned_seconds
      if @task.executed_seconds
        seconds -= @task.executed_seconds
      overtime = false
      if seconds < 0
        seconds = -seconds
        overtime = true
      minutes = Math.floor(seconds/60)
      hours = Math.floor(minutes/60)
      mins = minutes - hours*60
      if ! overtime
        return "[#{hours}:#{JustdoHelpers.padString(mins, 2)} H left]"
      return "[#{hours}:#{JustdoHelpers.padString(mins, 2)} H overtime]"
    return ""



  columnDate: ->
    return Template.instance().data.dates_to_display[@]

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

  #todo: there is a bug here when the mouse is moving out or in left/right cell, from time to time
  # it throws an error.
  "mouseover .calendar_view_scroll_left_cell" : (e, tpl)->
    if (f = tpl.view?.parentView?.parentView?.parentView?.parentView?.templateInstance().onSetScrollLeft)
      f()
    return

  "mouseout .calendar_view_scroll_left_cell" : (e, tpl)->
    if( f = tpl.view?.parentView?.parentView?.parentView?.parentView?.templateInstance().onUnsetScrollLeftRight)
      f()
    return

  "mouseover .calendar_view_scroll_right_cell" : (e, tpl)->
    if(f = tpl.view?.parentView?.parentView?.parentView?.parentView?.templateInstance().onSetScrollRight)
      f()
    return

  "mouseout .calendar_view_scroll_right_cell" : (e, tpl)->
    if (f = tpl.view?.parentView?.parentView?.parentView?.parentView?.templateInstance().onUnsetScrollLeftRight)
      f()
    return





