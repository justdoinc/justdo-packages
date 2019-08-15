Template.justdo_calendar_project_pane.onCreated ->
  @view_start_date = new ReactiveVar
  @view_start_date.set(new Date)
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

  refreshHack: ->
    d = Template.instance().view_start_date.get()
    return true





Template.justdo_calendar_project_pane.events
  "click .calendar-view-prev-week": ->
    date = moment(Template.instance().view_start_date.get())
    date.subtract(7, 'days');
    Template.instance().view_start_date.set(date)
    return

  "click .calendar-view-next-week": ->
    date = moment(Template.instance().view_start_date.get())
    date.add(7, 'days');
    Template.instance().view_start_date.set(date)
    return

  "click .calendar-view-back-to-today": ->
    Template.instance().view_start_date.set(new Date)
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

    q =
      follow_up: {$in: data.dates_to_display}
      $or: [{owner_id:  data.user_id},{pending_owner_id: data.user_id}]

    APP.collections.Tasks.find(q).forEach (task)->
      #deal with followups
      if task.follow_up
        day_index = data.dates_to_display.indexOf(task.follow_up)
        if day_index > -1
          day_column = days_matrix[day_index]
          row_index = 0
          while true
            if !day_column[row_index]?
              day_column[row_index] =
                task:
                  id: task._id
                  title: task.title
                type: "F" # F for followup, R for regular
                span: 1
              break
            row_index++

      self.days_matrix.set(days_matrix)
      return


    return

  return



Template.justdo_calendar_project_pane_user_view.helpers

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

  taskTitle: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=1
      if (info=matrix[col_num-1]?[row_num])
        return info.task.title
    return ""

  taskId: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=1
      if (info=matrix[col_num-1]?[row_num])
        return info.task.id
    return ""

  isFollowupDate: ->
    col_num = @-1
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if col_num>=1
      if (info=matrix[col_num-1]?[row_num])
        return info.type == 'F'
    return false


Template.justdo_calendar_project_pane_user_view.events
  "click .calendar_task_cell": (e, tpl)->
    if (task_id = e.target.getAttribute("task_id"))?
      gcm = APP.modules.project_page.getCurrentGcm()
      gcm.setPath(["main", task_id], {collection_item_id_mode: true})
      return
    return



