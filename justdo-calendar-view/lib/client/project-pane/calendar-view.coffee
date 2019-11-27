config =
  bottom_line:
    show_number_of_tasks: false
    show_flat_hours_per_day: false
    show_workload: true

  #the following controls the zoom in/out options of the view. Each array should hold the same number of vars
  supported_days_resolution:  [7, 14, 28, 56]
  days_resolution_small_step: [1,  3,  7, 14]
  days_resolution_big_step:   [7, 14, 21, 42]


# setting the following 5 functions as global here to make it easy to call them from justdo_calendar_project_pane_user_view
onSetScrollLeft = -> return
onClickScrollLeft = -> return
onSetScrollRight = -> return
onClickScrollRight = -> return
onUnsetScrollLeftRight = -> return

members_collapse_state_vars = {}

dates_to_display = new ReactiveVar([])
number_of_days_to_display = new ReactiveVar(7)



# Create Wrapper (Layer) with droppable divs under the existing table
createDroppableWrapper = ->
  $(".calendar_view_droppable_wrapper").remove()
  leftPositionArray = []
  topPositionArray = []
  userIds = []
  dateArray = []
  heightArray = []
  width = $(".calendar_view_date").outerWidth()
  $table = $(".calendar_view_main_table")

  # Get Data to create DroppableWrapper (coordinates, width, height, dates, user_id)
  for item in $(".calendar_view_date")
    leftPositionArray.push $(item).position().left

  for item in $(".calendar_table_user")
    heightArray.push $(item).css "height"
    topPositionArray.push $(item).position().top

  for item in $(".calendar_view_date")
    dateArray.push Blaze.getData(item)

  for item in $(".calendar_view_tasks_row")
    userIds.push $(item).attr "user_id"

  userIds = _.uniq(userIds)

  # Build and append DroppableWrapper
  droppableWrapper = """<div class="calendar_view_droppable_wrapper">"""

  for leftPosition, i in leftPositionArray
    for height, j in heightArray
      droppableWrapper += """
        <div class="calendar_view_droppable_item" style="height:#{height}; width:#{width}px; left:#{leftPosition}px; top:#{topPositionArray[j]}px">
          <div class="calendar_view_droppable_area" user_id="#{userIds[j]}" date="#{dateArray[i]}"></div>
        </div>
      """

  droppableWrapper += """</div>"""

  $(".calendar_view_main_table_wrapper").append droppableWrapper

  # Make Wrapper Droppable
  $('.calendar_view_droppable_area').droppable
    tolerance: "pointer"
    classes: "ui-droppable-hover": "highlight"
    drop: (e, ui) ->
      set_param = {}
      target_user_id = $(e.target).attr "user_id"
      task_obj = APP.collections.Tasks.findOne({_id: ui.helper[0].attributes.task_id.value})
      task_users = ui.helper.attr("task_users").split(",")
      task_acceptable = task_users.indexOf(target_user_id) > -1

      if task_acceptable
        # calculating task owner as it is on the calendar
        calendar_view_owner_id = task_obj.owner_id
        if task_obj.pending_owner_id
          calendar_view_owner_id = task_obj.pending_owner_id

        changing_owner = false
        if calendar_view_owner_id != target_user_id
          changing_owner = true

        # for changing followups or regular tasks (but not private followup), we also allow to change the owner
        if changing_owner and (ui.draggable[0].attributes.type.value == 'F' or ui.draggable[0].attributes.type.value == 'R')
          if Meteor.userId() == target_user_id
            set_param['owner_id'] = target_user_id
            set_param['pending_owner_id'] = null
          #if we return a task with pending owner to prev owner
          else if task_obj.owner_id == target_user_id and task_obj.pending_owner_id?
            set_param['pending_owner_id'] = null
          else
            set_param['pending_owner_id'] = target_user_id

        # if we change owner of a regular task, we need to transfer the planned hours to the target owner,
        # and assign all unassigned hours to the target owner
        if changing_owner and ui.draggable[0].attributes.type.value == 'R'
          original_owner_planning_time = 0 + task_obj["p:rp:b:work-hours_p:b:user:#{calendar_view_owner_id}"]

          record =
            delta: - original_owner_planning_time
            resource_type: "b:user:#{calendar_view_owner_id}"
            stage: "p"
            source: "jd-calendar-view-plugin"
            task_id: task_obj._id
          APP.resource_planner.rpAddTaskResourceRecord record

          record.delta = original_owner_planning_time
          record.resource_type = "b:user:#{target_user_id}"
          APP.resource_planner.rpAddTaskResourceRecord record

          if (unassigned_hours = task_obj['p:rp:b:unassigned-work-hours'])
            record.delta = unassigned_hours
            APP.resource_planner.rpAddTaskResourceRecord record
            set_param['p:rp:b:unassigned-work-hours'] = 0


        if ui.draggable[0].attributes.class.value.indexOf("calendar_view_draggable")>=0
          #dealing with Followups
          if ui.draggable[0].attributes.type.value == 'F'
            set_param['follow_up'] = e.target.attributes.date.value
            APP.collections.Tasks.update({_id: ui.helper[0].attributes.task_id.value},
                                          $set:set_param
                                         )
          #dealing with Private followups
          else if ui.draggable[0].attributes.type.value == 'P'
            set_param['priv:follow_up'] = e.target.attributes.date.value
            APP.collections.Tasks.update({_id: ui.helper[0].attributes.task_id.value},
              $set: set_param
            )

          #dealing with Regular
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
            if original_start_date < original_end_date
              d = moment(original_start_date)
              while d < moment(original_end_date)
                if justdo_level_workdays.weekly_work_days[d.day()] == 1
                  new_end_date_moment.add(1,'days')
                  #skip non working days
                  while(justdo_level_workdays.weekly_work_days[new_end_date_moment.day()] == 0)
                    new_end_date_moment.add(1,'days')
                d.add(1, 'days')

            if task_obj.start_date?
              set_param['start_date'] = new_start_date

            if task_obj.end_date?
              set_param['end_date'] = new_end_date_moment.format("YYYY-MM-DD")

            #todo: calculate how to move the due-date
            APP.collections.Tasks.update({_id: ui.helper[0].attributes.task_id.value},
              $set: set_param
            )
      else # Task not acceptable
        JustdoSnackbar.show
          text: "Ownership transfer is not possible due to permissions"
          actionText: "Close"
          duration: 5000
          onActionClick: =>
            JustdoSnackbar.close()
            return
      return #end of drop
  return

destroyDroppableWrapper = ->
  $(".calendar_view_droppable_wrapper").remove()
  return

setDragAndDrop = ->
  allowScroll = null
  $('.calendar_view_draggable').draggable
    cursor: 'none'
    helper: 'clone'
    zIndex: 100
    refreshPositions: true
    start: (e, ui) ->
      # To avoid size changes while dragging set the width of ui.helper equal to the width of an active task
      $(ui.helper).width($(event.target).closest(".calendar_task_cell").width())
      # Append an element to the table to avoid destruction when updating the table
      $(ui.helper).appendTo(".calendar_view_main_table_wrapper")
      createDroppableWrapper()
      return
    stop: (e, ui) ->
      destroyDroppableWrapper()
      return

  $('.calendar_view_scroll_cell').droppable
    tolerance: 'pointer'
    out: (e, ui) ->
      allowScroll = false
      return
    over: (e, ui) ->
      allowScroll = true
      delayAction (->
        if allowScroll
          $tableWrapper = $(".calendar_view_main_table_wrapper")
          $tableWrapper.addClass "fadeOut"
          if $(e.target).hasClass "calendar_view_scroll_left_cell"
            $(e.target).click()
          if $(e.target).hasClass "calendar_view_scroll_right_cell"
            $(e.target).click()

          setTimeout (->
            createDroppableWrapper()
            $tableWrapper.removeClass "fadeOut"
            return
          ), 300
      ), 300
      return
  return

fixHeaderOnScroll = ->
  $(".tab-justdo-calendar-container").on "scroll", ->
    scrollTop = $(this).scrollTop()
    $tableHeader = $(".main_table_fixed_header")
    tableWidth = $(".calendar_view_main_table").width()
    if scrollTop > 0
      $tableHeader.width(tableWidth).show()
    else
      $tableHeader.hide()
    return
  return

fixAvatarOnScroll = ->
  avatar_fixed = false
  $(".tab-justdo-calendar-container").on "scroll", ->
    $sticky_avatar_helper = $(".sticky-avatar-helper")

    $(".calendar_table_user").each (e, obj) ->
      height = $(obj).outerHeight()
      sticky_y = $sticky_avatar_helper[0].getBoundingClientRect().y
      obj_y_top = obj.getBoundingClientRect().y
      obj_y_bottom = obj_y_top + height
      gap = 52

      if obj_y_top + gap < sticky_y < obj_y_bottom - gap
        if !avatar_fixed
          $(obj).find(".justdo-avatar").clone().hide().appendTo($sticky_avatar_helper).fadeIn()
          avatar_fixed = true

      if obj_y_top < sticky_y < obj_y_top + gap or obj_y_bottom - gap < sticky_y < obj_y_bottom
        if avatar_fixed
          $sticky_avatar_helper.empty()
          avatar_fixed = false
      return
    return
  return

# Delay action
delayAction = do ->
  timer = 0
  (callback, ms) ->
    clearTimeout timer
    timer = setTimeout(callback, ms)
    return

justdo_level_workdays = {} #intentionally making this one a non-reactive var, otherwise we will hit it too many times

Template.justdo_calendar_project_pane.onCreated ->
  self = @

  @justdo_level_holidays = new ReactiveVar(new Set())

  # to handle highlighting the header of 'today', when the day changes...
  # could be optimized to hit once per day, but this is good enough
  start_of_day = new moment
  start_of_day = start_of_day.startOf('day')
  @today = new ReactiveVar(start_of_day)
  setInterval( =>
    start_of_day = new moment
    start_of_day = start_of_day.startOf('day')
    self.today.set(start_of_day)
    return
  ,
    1000 * 60
  )



  @delivery_planner_project_id = new ReactiveVar ("*") # '*' for the entire JustDo
  @all_other_users = new ReactiveVar([])
  @view_start_date = new ReactiveVar
  active_item_id = null

  #calculate the first day to display based on the beginning of the week of the user
  @resetFirstDay = (date)->
    d = new Date(date)
    dow = d.getDay()
    user_first_day_of_week = 1
    if Meteor.user().profile?.first_day_of_week?
      user_first_day_of_week = Meteor.user().profile.first_day_of_week

    if dow < user_first_day_of_week
      dow += 7
    d.setDate(d.getDate() - (dow - user_first_day_of_week))
    @view_start_date.set(d)
    return

  @resetFirstDay(new Date)

  #scrolling left and right control flow
  @scroll_left_right_handler = null

  @setToPrevWeek = (keep_scroll_handler)->
    d = self.view_start_date.get()
    dow = d.getDay()
    index = config.supported_days_resolution.indexOf number_of_days_to_display.get()
    step_size = config.days_resolution_big_step[index]
    user_first_day_of_week = 1
    if Meteor.user().profile?.first_day_of_week?
      user_first_day_of_week = Meteor.user().profile.first_day_of_week

    if dow == user_first_day_of_week
      d.setDate(d.getDate() - step_size)
    else
      if dow < user_first_day_of_week
        dow += 7
      d.setDate(d.getDate() - (dow - step_size))
    self.view_start_date.set(d)

    if !keep_scroll_handler and self.scroll_left_right_handler
      clearInterval(self.scroll_left_right_handler)
    return

  onClickScrollLeft = @setToPrevWeek

  @setToNextWeek = (keep_scroll_handler)->
    d = self.view_start_date.get()
    index = config.supported_days_resolution.indexOf number_of_days_to_display.get()
    step_size = config.days_resolution_big_step[index]
    d.setDate(d.getDate() + step_size)
    dow = d.getDay()
    user_first_day_of_week = 1
    if Meteor.user().profile?.first_day_of_week?
      user_first_day_of_week = Meteor.user().profile.first_day_of_week

    if dow < user_first_day_of_week
      dow += 7
    d.setDate(d.getDate() - (dow - user_first_day_of_week))
    self.view_start_date.set(d)

    if !keep_scroll_handler and self.scroll_left_right_handler
      clearInterval(self.scroll_left_right_handler)
    return

  onClickScrollRight = @setToNextWeek

  onSetScrollLeft = ->
    if self.scroll_left_right_handler
      clearInterval(self.scroll_left_right_handler)
    self.scroll_left_right_handler = setInterval( =>
      self.setToPrevWeek(true)
      return
    ,
      1500
    )
    return

  onSetScrollRight = ->
    if self.scroll_left_right_handler
      clearInterval(self.scroll_left_right_handler)
    self.scroll_left_right_handler = setInterval( =>
      self.setToNextWeek(true)
      return
    ,
      1500
    )
    return

  onUnsetScrollLeftRight = ->
    if self.scroll_left_right_handler
      clearInterval(self.scroll_left_right_handler)
      self.scroll_left_right_handler = null
    return

  findSelectedTask = (taskId) ->
    $activeTask = $(".calendar_task_cell[task_id=#{taskId}]")
    if $activeTask[0]?
      $(".tab-justdo-calendar-container").animate { scrollTop: $activeTask.position().top - 30 }, 500
      $activeTask.addClass "show_cell"
      setTimeout (->
        $activeTask.removeClass "show_cell"
        return
      ), 1000
    return

  #todo: become future compatible - the project level workdays and holidays will come from the delivery planner
  #todo: check with Daniel how to ensure plugins dependencies during load time.
  #todo: once we apply project filters, take the workdays from the project record.

  if APP.justdo_delivery_planner?.justdo_level_workdays
    @autorun =>
      justdo_level_workdays = APP.justdo_delivery_planner.justdo_level_workdays.get()
  else
    justdo_level_workdays =
      weekly_work_days: [1, 1, 1, 1, 1, 1, 1] #sunday at index 0, default set to Monday-Friday
      specific_off_days: [] # and no holidays by default
      working_hours_per_day: 8
    user_first_day_of_week = 1
    if Meteor.user().profile?.first_day_of_week?
      user_first_day_of_week = Meteor.user().profile.first_day_of_week
    user_first_day_of_week--
    if(user_first_day_of_week<0)
      user_first_day_of_week=6
    justdo_level_workdays.weekly_work_days[user_first_day_of_week]=0
    user_first_day_of_week--
    if(user_first_day_of_week<0)
      user_first_day_of_week=6
    justdo_level_workdays.weekly_work_days[user_first_day_of_week]=0


  # commenting out for now, as it's UX is not good. -AL
  #@autorun =>
  #  if (active_item_id = APP.modules.project_page.activeItemId())?
  #    findSelectedTask(active_item_id)
  #  return

  @tasks_to_users = {}
  @users_to_tasks = {}
  @project_members_to_dependency = {}

  @onTaskAddedOrChanged = (task_id, fields)->
    if !(task = APP.collections.Tasks.findOne(task_id))?
      return

    #############
    # In this section we find which users are relevant to the task
    #############
    current_users = new Set() #we start by cleaning the association to all users.
    current_users.add task.owner_id
    if(pending_owner = task.pending_owner_id)
      current_users.add pending_owner
    if task["priv:follow_up"]
      current_users.add Meteor.userId()

    # dealing with users that have planned or executed times
    for k,v of task
      if k.indexOf("p:rp:b:work-hours_p:b:user:") == 0
        current_users.add k.substr(27)
      if k.indexOf("p:rp:b:work-hours_e:b:user:") == 0
        current_users.add k.substr(27)

    if not(prev_users = self.tasks_to_users[task_id])
      self.tasks_to_users[task_id] = new Set()
      prev_users = self.tasks_to_users[task_id]

    else #check if current and prev are the same, if so, nothing to do now...
      if prev_users.size == current_users.size
        found_difference = false
        prev_users.forEach (prev_user_id)->
          if not current_users.has(prev_user_id)
            found_difference = true
        if not found_difference
          return


    # we know that the lists diverged. so now, remove users that are on the prev list and not on the
    # current list
    prev_users.forEach (prev_user_id)->
      if not current_users.has(prev_user_id) #i.e. a user was on the task before and now he is not there
        if (user_to_tasks = self.users_to_tasks[prev_user_id])
          user_to_tasks.delete task_id
          self.project_members_to_dependency[prev_user_id].changed()
    # in a similar way, add the users that are on the new list and were not on the prev list
    current_users.forEach (current_user_id)->
      if not prev_users.has(current_user_id)
        if not self.users_to_tasks[current_user_id]
          self.users_to_tasks[current_user_id] = new Set()
        self.users_to_tasks[current_user_id].add task_id
        self.project_members_to_dependency[current_user_id].changed()

    self.tasks_to_users[task_id] = current_users

    return

  @onTaskRemoved = (task_id)->
    if !(users = self.tasks_to_users[task_id])
      return
    users.forEach (user_id)->
      if (user_to_tasks = self.users_to_tasks[user_id])
        user_to_tasks.delete task_id
        self.project_members_to_dependency[user_id].changed()
    delete self.tasks_to_users[task_id]

    return

  @autorun =>
    dates = []
    d = moment(new Date(Template.instance().view_start_date.get()))
    for i in [0..(number_of_days_to_display.get()-1)]
      dates.push(d.format("YYYY-MM-DD"))
      d.add(1,"days")
    dates_to_display.set(dates)
    @justdo_level_holidays.set(APP.justdo_resources_availability?.workdaysAndHolidaysFor(JD.activeJustdo()._id, dates).holidays)
    return

  @autorun =>
    #making reactive to changes in project members
    all_members = APP.modules.project_page.curProj().getMembersIds()
    for member in all_members
      if not self.project_members_to_dependency[member]
        self.project_members_to_dependency[member] = new Tracker.Dependency()
      if !self.users_to_tasks[member]
        self.users_to_tasks[member] = new Set()
      else if self.users_to_tasks[member].size > 0
        self.project_members_to_dependency[member].changed()
        self.users_to_tasks[member].clear()
      self.tasks_to_users={}

    include_tasks = []
    project_id = self.delivery_planner_project_id.get()

    if project_id != "*"
      include_tasks.push project_id
      path = APP.modules.project_page.gridData().getCollectionItemIdPath(project_id)
      gc = APP.modules.project_page.mainGridControl()
      gc._grid_data.each path, (section, item_type, item_obj, path) ->
        include_tasks.push item_obj._id
        return

    d = moment(Template.instance().view_start_date.get())
    dates = dates_to_display.get()

    first_date_to_display = dates[0]
    last_date_to_display = dates[dates.length-1]

    dates_part = [
      #regular followup date
      {follow_up: {$in: dates}},
      #private followup date
      {'priv:follow_up': {$in: dates}},
      #due date in between the dates
      {$and: [
        {end_date: {$gte: first_date_to_display}},
        {end_date: {$lte: last_date_to_display}}
      ]},
      #start date in between the dates
      {$and: [
        {start_date: {$gte: first_date_to_display}},
        {start_date: {$lte: last_date_to_display}}
      ]},
      #start date before and due date after
      {$and: [
        {start_date: {$lt: first_date_to_display}},
        {end_date: {$gt: last_date_to_display}}
#        ,
#        end_date: {$exists: true},
#        start_date: {$exists: true}
      ]}
    ]

    project_part =
      project_id: APP.modules.project_page.project.get()?.id

    query_parts = []
    query_parts.push {$or: dates_part}
    query_parts.push project_part
    if include_tasks.length > 0
      query_parts.push {_id: $in: include_tasks}

    APP.collections.Tasks.find({$and: query_parts}).observeChanges
      added: (id, fields) ->
        self.onTaskAddedOrChanged id, fields
        return
      changed: (id, fields) ->
        self.onTaskAddedOrChanged id, fields
        return
      removed: (id) ->
        self.onTaskRemoved id
        return
    #end of autorun
  return # end onCreated

Template.justdo_calendar_project_pane.helpers
  currentUserDependency: ->
    return Template.instance().project_members_to_dependency[Meteor.userId()]

  userDependency: ->
    return Template.instance().project_members_to_dependency[@]

  currentUserTasksSet: ->
    return Template.instance().users_to_tasks[Meteor.userId()]

  userTasksSet: ->
    return Template.instance().users_to_tasks[@]


  title_date: ->
    return moment(Template.instance().view_start_date.get()).format("YYYY-MM-DD")

  currentUserId: ->
    return Meteor.userId()


  allOtherUsers: ->
    if Template.instance().delivery_planner_project_id.get() == "*"
      return _.difference(APP.modules.project_page.curProj().getMembersIds(), [Meteor.userId()])
    else
      return Template.instance().all_other_users.get()

  projectsInJustDo: ->
    project = APP.modules.project_page.project.get()
    if project?
      return APP.collections.Tasks.find({
          "p:dp:is_project": true
          project_id: project.id
        }, {sort: {"title": 1}}).fetch()

  datesToDisplay: ->
    return dates_to_display.get()

  deliveryPlannerProjectId: ->
    return Template.instance().delivery_planner_project_id.get()

  formatDate: ->
    formattedDate = "<span class='week_day'>" + moment.utc(@).format("ddd") + "</span>" + moment.utc(@).format("Do")
    return formattedDate

  isToday: (date) ->
    if moment(date).isSame(Template.instance().today.get(), "d")
      return true
    return false

  isHoliday: (date) ->
    if Template.instance().justdo_level_holidays.get().has(date)
      return "is_holiday"
    return ""

Template.justdo_calendar_project_pane.events
  "click .calendar_view_zoom_out": ->
    index = config.supported_days_resolution.indexOf number_of_days_to_display.get()
    if index < config.supported_days_resolution.length-1
      number_of_days_to_display.set(config.supported_days_resolution[index + 1])
    return

  "click .calendar_view_zoom_in": ->
    index = config.supported_days_resolution.indexOf number_of_days_to_display.get()
    if index > 0
      number_of_days_to_display.set(config.supported_days_resolution[index - 1])
    return


  "click .expand_all": ->
    for member, state of members_collapse_state_vars
      state.set(false)
    return

  "click .collapse_all": ->
    for member, state of members_collapse_state_vars
      state.set(true)
    return

  "click .calendar-view-prev-week": ->
    Template.instance().setToPrevWeek()
    return

  "click .calendar-view-prev-day": ->
    d = Template.instance().view_start_date.get()
    index = config.supported_days_resolution.indexOf number_of_days_to_display.get()
    d.setDate(d.getDate() - config.days_resolution_small_step[index])
    Template.instance().view_start_date.set(d)
    return

  "click .calendar-view-next-day": ->
    d = Template.instance().view_start_date.get()
    index = config.supported_days_resolution.indexOf number_of_days_to_display.get()
    d.setDate(d.getDate() + config.days_resolution_small_step[index])
    Template.instance().view_start_date.set(d)

    return

  "click .calendar-view-next-week": ->
    Template.instance().setToNextWeek()
    return

  "click .calendar-view-back-to-today": ->
    Template.instance().resetFirstDay(new Date)
    return

  "click .calendar_view_project_selector a": (e) ->
    project = $(e.currentTarget).attr "project_id"
    project_name = $(e.currentTarget).text()
    $(".calendar_view_project_selector button").text(project_name)
    Template.instance().delivery_planner_project_id.set(project)

    if project == "*"
      Template.instance().all_other_users.set(
        _.map Meteor.users.find({_id: {$ne: Meteor.userId()}},{fields: {_id:1}}).fetch(), (u)-> u._id
      )
    else
      other_users = []
      _.map APP.collections.Tasks.findOne(project).users, (u)->
        if u != Meteor.userId()
          other_users.push u
        return
      Template.instance().all_other_users.set(other_users)
    return

  "mouseover .calendar_view_main_table tr": (e, tmpl) ->
    $(".justdo-avatar").removeClass "highlight"
    focused_tr = $(e.target).closest "tr"
    focused_user_id = $($(focused_tr)[0]).attr "user_id"
    focused_users_tr = $("[user_id=" + focused_user_id + "]")
    $(focused_users_tr[0]).find(".justdo-avatar").addClass "highlight"
    return

  "mouseleave .calendar_view_main_table tr": (e, tmpl) ->
    $(".justdo-avatar").removeClass "highlight"
    return

Template.justdo_calendar_project_pane_user_view.onCreated ->
  self = @
  @days_matrix = new ReactiveVar([])
  @dates_workload = new ReactiveVar({})
  @collapsed_view = new ReactiveVar(true)


  members_collapse_state_vars[Template.currentData().user_id] = @collapsed_view
  @justdo_user_holidays = new Set()

  @last_tasks_set_size = 0
  @autorun =>

    data = Template.currentData()
    data.dependency.depend()

    @justdo_user_holidays = APP.justdo_resources_availability?.workdaysAndHolidaysFor(JD.activeJustdo()._id,\
                            data.dates_to_display, Template.currentData().user_id).holidays

    if self.last_tasks_set_size == 0 and data.tasks_set.size == 0
      return

    self.last_tasks_set_size = data.tasks_set.size



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

    owner_part =
      $or: [
        {owner_id:  data.user_id}, #user is owner, and there is no pending owner
        {pending_owner_id: data.user_id}, #user is the pending owner
        {"#{planned_seconds_field}": {$gt: 0}}, #user has planned hours on the task
        {'priv:follow_up': {$exists: true}}
        ]

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
        "users": 1

    self.dates_workload.set({})
    APP.collections.Tasks.find({$and: [_id: {$in: Array.from(data.tasks_set)}, owner_part]}, options).forEach (task)->
      task_details =
        _id: task._id
        title: task.title
        pending_owner_id: task.pending_owner_id
        owner_id: task.owner_id
        sequence_id: task.seqId
        end_date: task.end_date
        start_date: task.start_date
        state: task.state
        unassigned_hours: task["p:rp:b:unassigned-work-hours"]
        users: task.users
        "priv:follow_up": task["priv:follow_up"]

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
                  task: task_details
                  type: 't' # F for followup, P for private followup, R for regular, t for cont task
#                  slot_is_taken: true
#                  slot_is_taken_by_task_id: task_details._id

            break
          row_index++

      #now we need to loop over all days, and for each day count the total working hours

      dates_workload = {}

      task_to_flat_hours_per_day = {} # this is a cache var to hold hours per day for each task,
                                      # based on flat distribution of planned hours over workdays.
                                      # We clear it and repopulate it when working on the dates_workload
      flatHoursPerDay = (row_data)->
        if row_data.task.planned_seconds == undefined
          row_data.task.planned_seconds = 0

        if task_to_flat_hours_per_day[row_data.task._id]
          return task_to_flat_hours_per_day[row_data.task._id]
        start_date = moment(row_data.task.start_date)
        end_date = moment(row_data.task.end_date)
        if !row_data.task.start_date
          start_date = end_date
        if !row_data.task.end_date
          end_date = start_date
        if end_date <= start_date
          task_to_flat_hours_per_day[row_data.task._id] = row_data.task.planned_seconds / 3600
          return task_to_flat_hours_per_day[row_data.task._id]

        days = 1
        while start_date < end_date
          if justdo_level_workdays.weekly_work_days[start_date.day()] == 1
            days++
          start_date.add(1,'days')
        task_to_flat_hours_per_day[row_data.task._id] = row_data.task.planned_seconds / 3600 / days
        return task_to_flat_hours_per_day[row_data.task._id]

      for column_index of days_matrix
        for row in days_matrix[column_index]
          task_id = null

          #due to tasks placements, there might be empty rows in the column. we will avoid those:
          if !row?
            continue

          if row.type == "R" or row.type == "t"
            date = data.dates_to_display[column_index]
            Meteor._ensure dates_workload, date
            #calcualte number of tasks:
            if !dates_workload[date].number_of_tasks
              dates_workload[date].number_of_tasks = 0
            dates_workload[date].number_of_tasks++

            #calculate number of hours, assuming flat distribution of task's time over workdays
            if !dates_workload[date].total_hours
              dates_workload[date].total_hours = 0
            dates_workload[date].total_hours += flatHoursPerDay(row)


      self.days_matrix.set(days_matrix)
      self.dates_workload.set(dates_workload)
      Tracker.afterFlush ->
        setDragAndDrop()
      return
    return

Template.justdo_calendar_project_pane_user_view.onDestroyed ->
    delete members_collapse_state_vars[Template.currentData().user_id]
    return

Template.justdo_calendar_project_pane_user_view.onRendered ->
  setDragAndDrop()
  fixHeaderOnScroll()
  fixAvatarOnScroll()
  return

Template.justdo_calendar_project_pane_user_view.helpers
  fontSizeClass: ->
    index = config.supported_days_resolution.indexOf number_of_days_to_display.get()
    if index == 0
      return ""
    if index == 1
      return "smaller_text"
    if index == 2
      return "x_small_text"
    return "xx_small_text"

  isCollapsed: ->
    return Template.instance().collapsed_view.get()

  bottomLine: ->
    column_date = Template.instance().data.dates_to_display[this]
    workload = Template.instance().dates_workload.get()

    if( daily_workload = workload[column_date])
      ret = ""

      if config.bottom_line.show_number_of_tasks
        ret += "#{daily_workload.number_of_tasks} task(s) "
      if config.bottom_line.show_flat_hours_per_day
        ret += "#{daily_workload.total_hours.toFixed(1)} H "
      if config.bottom_line.show_workload
        ret += "#{(daily_workload.total_hours/justdo_level_workdays.working_hours_per_day*100).toFixed(0)}% "
      return ret

    return "--"

  userId: ->
    return Template.instance().data.user_id

  showNavigation: ->
    return Template.instance().data.show_navigation

  dimTask: ->
    if (@task?.pending_owner_id? and @task.owner_id == Template.instance().data.user_id) or
      (Template.instance().data.user_id == Meteor.userId() and @task.owner_id != Meteor.userId() and @task["priv:follow_up"]? )
          return "dim_task"

    return ""

  hideDuePendingOwner: ->
    if @task?.pending_owner_id? and @task.owner_id == Template.instance().data.user_id
      return true
    return false

  rowNumbers: ->
    days_matrix = Template.instance().days_matrix.get()
    ret = 1
    for i in [0..Template.instance().data.dates_to_display.length]
      if days_matrix[i]?.length > ret
        ret = days_matrix[i].length

    return [0..ret-1]

  # NEED TO FIX IN THE FUTURE: Helper has to return the number of all possible rows
  navRowspan: ->
    return 9999

  firstRow: ->
    return (@+1)==1

  markDaysOff: ->

    column_date = Template.instance().data.dates_to_display[@]
    if Template.instance().justdo_user_holidays.has(column_date)
      return "calendar_view_mark_days_off"
    return ""

  colNumbers: ->
    return [0..Template.instance().data.dates_to_display.length-1]

  numberOfRows: ->
    days_matrix = Template.instance().days_matrix.get()
    ret = 1 # we start with 1 because we need at least one row for the user name
    for i in [0..Template.instance().data.dates_to_display.length]
      if days_matrix[i]?.length > ret
        ret = days_matrix[i].length
    ret += 1 # we need one more row for resources
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
      return info.type == 't'
    return false

  cellData: ->
    col_num = @
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()
    return matrix[col_num]?[row_num]

  startDateAfterDueDate: ->
    return @start_date_after_due_date

  unassignedHours: ->
    if @type == 'R' and @task.unassigned_hours > 0 and @task.owner_id == Template.instance().data.user_id
      seconds = @task.unassigned_hours
      minutes = Math.floor(seconds/60)
      hours = Math.floor(minutes/60)
      mins = minutes - hours*60
      return "#{hours}:#{JustdoHelpers.padString(mins, 2)} H unassigned"
    return ""

  plannedHours: ->
    if @type == 'R' and @task.planned_seconds > 0
      seconds = @task.planned_seconds
      overtime = false
      ### the following is in case that someday we will want to display (config base) the time left
      if @task.executed_seconds
        seconds -= @task.executed_seconds

      if seconds < 0
        seconds = -seconds
        overtime = true
      ###
      minutes = Math.floor(seconds/60)
      hours = Math.floor(minutes/60)
      mins = minutes - hours*60
      if ! overtime
        return "#{hours}:#{JustdoHelpers.padString(mins, 2)} H planned"
      return "#{hours}:#{JustdoHelpers.padString(mins, 2)} H overtime"
    return ""

  columnDate: ->
    return Template.instance().data.dates_to_display[@]

  showType: (type) ->
    if type == "R"
      return false
    else
      return true

Template.justdo_calendar_project_pane_user_view.events
  "click .calendar_task_cell": (e, tpl)->
    if (task_id = $(e.target).closest(".calendar_task_cell").attr("task_id"))?
      gcm = APP.modules.project_page.getCurrentGcm()
      gcm.setPath(["main", task_id], {collection_item_id_mode: true})
      return
    return

  "click .expand": (e, tpl)->
    tpl.collapsed_view.set(false)
    return

  "click .collapse": (e, tpl)->
    tpl.collapsed_view.set(true)
    return

  "click .clock": (e, tpl)->
    if (ra = APP.justdo_resources_availability)
      ra.displayConfigDialog JD.activeJustdo()._id, tpl.data.user_id
    return

  # "mouseover .calendar_task_cell" : (e, tpl)->
  #   if (elm = $(e.target).find(".fa-map-marker")[0])
  #     elm.style.visibility = 'visible'
  #   return

  ### for now I think that it's better not to have the hover events -AL
  "mouseover .calendar_view_scroll_left_cell" : (e, tpl)->
    onSetScrollLeft()
    return

  "mouseout .calendar_view_scroll_left_cell" : (e, tpl)->
    onUnsetScrollLeftRight()
    return

  "mouseover .calendar_view_scroll_right_cell" : (e, tpl)->
    onSetScrollRight()
    return

  "mouseout .calendar_view_scroll_right_cell" : (e, tpl)->
    onUnsetScrollLeftRight()
    return
  ###

  "click .calendar_view_scroll_left_cell" : (e, tpl)->
    onClickScrollLeft()
    return

  "click .calendar_view_scroll_right_cell" : (e, tpl)->
    onClickScrollRight()
    return
