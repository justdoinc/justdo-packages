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
delivery_planner_project_id = new ReactiveVar ("*") # '*' for the entire JustDo
sub_tree_task_ids = new ReactiveVar []

addResourceRecord = (record, task_id) ->
  record = _.extend {}, record
  sub = JD.subscribeItemsAugmentedFields [task_id], ["users"], {}, ->
    res_obj = APP.resource_planner.generateTaskResourcesObject
      task_id: task_id, 
      grid_control: APP.modules.project_page.gridControl()
      project_object: APP.modules.project_page.curProj()
    res_obj.addResourceRecord record, {}, ->
      sub.stop()

      return
    
    return
  
  return

findProjectName = (task_obj) ->
  if not task_obj?
    return null

  if task_obj["p:dp:is_project"]
    return task_obj.title

  for parent_id of task_obj.parents
    if (task_obj = APP.collections.Tasks.findOne(parent_id))?
      if (project_name = findProjectName(task_obj))?
        return project_name

  return null

# Create Wrapper (Layer) with droppable divs under the existing table
createDroppableWrapper = ->
  $(".calendar_view_droppable_wrapper").remove()
  left_position_array = []
  top_position_array = []
  user_ids = []
  date_array = []
  height_array = []
  width = $(".calendar_view_date").outerWidth()
  $table = $(".calendar_view_main_table")

  # Get Data to create DroppableWrapper (coordinates, width, height, dates, user_id)
  for item in $(".calendar_view_date")
    left_position_array.push $(item).position().left

  for item in $(".calendar_table_user")
    height_array.push $(item).css "height"
    top_position_array.push $(item).position().top

  for item in $(".calendar_view_date")
    date_array.push Blaze.getData(item)

  for item in $(".calendar_view_tasks_row")
    user_ids.push $(item).attr "user_id"

  table_top = $table.position().top
  table_height = $table.height()

  user_ids = _.uniq(user_ids)

  # Build and append DroppableWrapper
  droppable_wrapper = """<div class="calendar_view_droppable_wrapper" style="height:#{table_height}px">"""

  for leftPosition, i in left_position_array
    for height, j in height_array
      droppable_wrapper += """
        <div class="calendar_view_droppable_item" style="height:#{height}; width:#{width}px; left:#{leftPosition}px; top:#{top_position_array[j] - table_top}px">
          <div class="calendar_view_droppable_area" user_id="#{user_ids[j]}" date="#{date_array[i]}"></div>
        </div>
      """

  droppable_wrapper += """</div>"""

  $(".calendar_view_main_table_wrapper").append droppable_wrapper

  # Make Wrapper Droppable
  $(".calendar_view_droppable_area").droppable
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
        if changing_owner and (ui.draggable[0].attributes.type.value == "F" or ui.draggable[0].attributes.type.value == "R")
          if Meteor.userId() == target_user_id
            set_param["owner_id"] = target_user_id
            set_param["pending_owner_id"] = null
          #if we return a task with pending owner to prev owner
          else if task_obj.owner_id == target_user_id and task_obj.pending_owner_id?
            set_param["pending_owner_id"] = null
          else
            set_param["pending_owner_id"] = target_user_id

        # if we change owner of a regular task, we need to transfer the planned hours to the target owner,
        # and assign all unassigned hours to the target owner
        if changing_owner and ui.draggable[0].attributes.type.value == "R"
          if (original_owner_planning_time = task_obj["p:rp:b:work-hours_p:b:user:#{calendar_view_owner_id}"])?
            record =
              delta: -original_owner_planning_time
              resource_type: "b:user:#{calendar_view_owner_id}"
              stage: "p"
              source: "jd-calendar-view-plugin"
              task_id: task_obj._id
            
            addResourceRecord record, task_obj._id

            record.delta = original_owner_planning_time
            record.resource_type = "b:user:#{target_user_id}"
            addResourceRecord record, task_obj._id

          if (unassigned_hours = task_obj["p:rp:b:unassigned-work-hours"])?
            record.delta = unassigned_hours
            addResourceRecord record, task_obj._id
            set_param["p:rp:b:unassigned-work-hours"] = 0

        if ui.draggable[0].attributes.class.value.indexOf("calendar_view_draggable") >= 0
          #dealing with Followups
          if ui.draggable[0].attributes.type.value == "F"
            set_param["follow_up"] = e.target.attributes.date.value
            if (task_id = ui.helper[0]?.attributes?.task_id?.value)?
              APP.collections.Tasks.update(task_id, {$set: set_param})
          #dealing with Private followups
          else if ui.draggable[0].attributes.type.value == "P"
            set_param["priv:follow_up"] = e.target.attributes.date.value
            if (task_id = ui.helper[0]?.attributes?.task_id?.value)?
              APP.collections.Tasks.update(task_id, {$set: set_param})

          #dealing with Regular

          # Important notice - moving tasks around is performed now based on users' workdays, and not based on their
          # available hours. This is following Ofer's style. Future compatible wise - we can do it based on hours needed.

          else if ui.draggable[0].attributes.type.value == "R"
            # Note: from the query definitions we must have at least one of start or end or due dates.

            # if there is only due-date (i.e. no start and no end date)
            if (not task_obj.start_date) and (not task_obj.end_date)
              set_param.due_date = e.target.attributes.date.value
              if (task_id = ui.helper[0]?.attributes?.task_id?.value)?
                APP.collections.Tasks.update(task_id, {$set: set_param})
              return

            original_start_date = task_obj.start_date
            if not original_start_date
              original_start_date = task_obj.end_date

            original_end_date = task_obj.end_date
            if not original_end_date
              original_end_date = task_obj.start_date

            #now we need to know how many working days the original owner had between start and end date.
            original_user_availability = APP.justdo_resources_availability.userAvailabilityBetweenDates original_start_date, original_end_date,
                JD.activeJustdo({_id: 1})._id, calendar_view_owner_id

            new_start_date = e.target.attributes.date.value
            new_end_date = APP.justdo_resources_availability.startToFinishForUser JD.activeJustdo({_id: 1})._id, target_user_id,
              new_start_date, original_user_availability.working_days, "days"

            if task_obj.start_date?
              set_param["start_date"] = new_start_date

            if task_obj.end_date?
              set_param["end_date"] = new_end_date

            if (task_id = ui.helper[0]?.attributes?.task_id?.value)?
              APP.collections.Tasks.update(task_id, {$set: set_param})
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
  allow_scroll = null
  $(".calendar_view_draggable").draggable
    cursor: "none"
    helper: "clone"
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

  $(".calendar_view_scroll_cell").droppable
    tolerance: "pointer"
    out: (e, ui) ->
      allow_scroll = false
      return
    over: (e, ui) ->
      allow_scroll = true
      delayAction (->
        if allow_scroll
          $table_wrapper = $(".calendar_view_main_table_wrapper")
          $table_wrapper.addClass "fadeOut"
          if $(e.target).hasClass "calendar_view_scroll_left_cell"
            $(e.target).click()
          if $(e.target).hasClass "calendar_view_scroll_right_cell"
            $(e.target).click()

          setTimeout (->
            createDroppableWrapper()
            $table_wrapper.removeClass "fadeOut"
            return
          ), 300
      ), 300
      return
  return

fixHeaderOnScroll = ->
  $(".calendar_view_main_table_wrapper").on "scroll", ->
    scroll_top = $(@).scrollTop()
    $table_header = $(".main_table_fixed_header")
    table_width = $(".calendar_view_main_table")[0]["clientWidth"]
    if scroll_top > 0
      $table_header.width(table_width).show()
    else
      $table_header.hide()
    return
  return

# Delay action
delayAction = do ->
  timer = 0
  (callback, ms) ->
    clearTimeout timer
    timer = setTimeout(callback, ms)
    return
  return

Template.justdo_calendar_project_pane.onCreated ->
  self = @

  @calendar_projects_filter_val = new ReactiveVar null
  @calendar_filtered_members = new ReactiveVar []
  @justdo_level_holidays = new ReactiveVar(new Set())
  @calendar_members_collapse_state_rv = new ReactiveVar false

  delivery_planner_project_id.set "*"  # '*' for the entire JustDo

  @autorun =>
    project_id = delivery_planner_project_id.get()
    other_users = []
    if project_id == "*"
      other_users = _.difference(APP.modules.project_page.curProj()?.getMembersIds(), [Meteor.userId()])
    else
      other_users = _.difference(APP.collections.TasksAugmentedFields.findOne(project_id)?.users, [Meteor.userId()])

    self.calendar_filtered_members.set []
    return

  # to handle highlighting the header of 'today', when the day changes...
  # could be optimized to hit once per day, but this is good enough
  start_of_day = new moment
  start_of_day = start_of_day.startOf("day")
  @today = new ReactiveVar(start_of_day)
  @refresh_today_interval = Meteor.setInterval =>
    start_of_day = new moment
    start_of_day = start_of_day.startOf("day")
    self.today.set(start_of_day)
    return
  ,
    1000 * 60

  @view_start_date = new ReactiveVar
  @view_end_date = new ReactiveVar
  active_item_id = null

  #calculate the first day to display based on the beginning of the week of the user
  @resetFirstDay = (date) ->
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

  @setToPrevWeek = (keep_scroll_handler) ->
    d = self.view_start_date.get()
    dow = d.getDay()
    index = config.supported_days_resolution.indexOf number_of_days_to_display.get()
    step_size = config.days_resolution_big_step[index]
    d.setDate(d.getDate() - step_size)
    self.view_start_date.set(d)

    if not keep_scroll_handler and self.scroll_left_right_handler
      clearInterval(self.scroll_left_right_handler)
    return

  onClickScrollLeft = @setToPrevWeek

  @setToNextWeek = (keep_scroll_handler) ->
    d = self.view_start_date.get()
    index = config.supported_days_resolution.indexOf number_of_days_to_display.get()
    step_size = config.days_resolution_big_step[index]
    d.setDate(d.getDate() + step_size)
    self.view_start_date.set(d)

    if not keep_scroll_handler and self.scroll_left_right_handler
      clearInterval(self.scroll_left_right_handler)
    return

  onClickScrollRight = @setToNextWeek

  onSetScrollLeft = ->
    if self.scroll_left_right_handler
      clearInterval(self.scroll_left_right_handler)
    self.scroll_left_right_handler = setInterval =>
      self.setToPrevWeek(true)
      return
    ,
      1500

    return

  onSetScrollRight = ->
    if self.scroll_left_right_handler
      clearInterval(self.scroll_left_right_handler)
    self.scroll_left_right_handler = setInterval =>
      self.setToNextWeek(true)
      return
    ,
      1500

    return

  onUnsetScrollLeftRight = ->
    if self.scroll_left_right_handler
      clearInterval(self.scroll_left_right_handler)
      self.scroll_left_right_handler = null
    return

  findSelectedTask = (taskId) ->
    $activeTask = $(".calendar_task_cell[task_id=#{taskId}]")
    if $activeTask[0]?
      $(".tab-justdo-calendar-container").animate {scrollTop: $activeTask.position().top - 30}, 500
      $activeTask.addClass "show_cell"
      setTimeout (->
        $activeTask.removeClass "show_cell"
        return
      ), 1000
    return

  #todo: become future compatible - the project level workdays and holidays will come from the delivery planner
  #todo: check with Daniel how to ensure plugins dependencies during load time.
  #todo: once we apply project filters, take the workdays from the project record.

  user_first_day_of_week = 1
  if Meteor.user().profile?.first_day_of_week?
    user_first_day_of_week = Meteor.user().profile.first_day_of_week
  user_first_day_of_week -= 1
  if(user_first_day_of_week < 0)
    user_first_day_of_week = 6
  user_first_day_of_week -= 1
  if(user_first_day_of_week < 0)
    user_first_day_of_week = 6

  # commenting out for now, as it's UX is not good. -AL
  #@autorun =>
  #  if (active_item_id = APP.modules.project_page.activeItemId())?
  #    findSelectedTask(active_item_id)
  #  return

  @tasks_to_users = {}
  @users_to_tasks = {}
  @project_members_to_dependency = {}

  @onTaskAddedOrChanged = (task_id, fields) ->
    if not (task = APP.collections.Tasks.findOne(task_id))?
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
    for k, v of task
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
        prev_users.forEach (prev_user_id) ->
          if not current_users.has(prev_user_id)
            found_difference = true
        if not found_difference
          return

    # we know that the lists diverged. so now, remove users that are on the prev list and not on the
    # current list
    prev_users.forEach (prev_user_id) ->
      if not current_users.has(prev_user_id) #i.e. a user was on the task before and now he is not there
        if (user_to_tasks = self.users_to_tasks[prev_user_id])
          user_to_tasks.delete task_id
          self.project_members_to_dependency[prev_user_id].changed()
    # in a similar way, add the users that are on the new list and were not on the prev list
    current_users.forEach (current_user_id) ->
      if not prev_users.has(current_user_id)
        if not self.users_to_tasks[current_user_id]
          self.users_to_tasks[current_user_id] = new Set()
        self.users_to_tasks[current_user_id].add task_id
        self.project_members_to_dependency[current_user_id].changed()

    self.tasks_to_users[task_id] = current_users

    return

  @onTaskRemoved = (task_id) ->
    if not (users = self.tasks_to_users[task_id])
      return
    users.forEach (user_id) ->
      if (user_to_tasks = self.users_to_tasks[user_id])
        user_to_tasks.delete task_id
        self.project_members_to_dependency[user_id].changed()
    delete self.tasks_to_users[task_id]

    return

  # Handle dates to display
  @autorun =>
    dates = []
    d = moment(new Date(Template.instance().view_start_date.get()))
    for i in [0..(number_of_days_to_display.get() - 1)]
      dates.push(d.format("YYYY-MM-DD"))
      d.add(1, "days")
    dates_to_display.set(dates)
    Template.instance().view_end_date.set(dates[dates.length - 1])
    @justdo_level_holidays.set(APP.justdo_resources_availability?.workdaysAndHolidaysFor(JD.activeJustdo({_id: 1})._id, dates).holidays)
    return

  @autorun =>
    #making reactive to changes in project members
    all_members = APP.modules.project_page.curProj().getMembersIds()
    for member in all_members
      if not self.project_members_to_dependency[member]
        self.project_members_to_dependency[member] = new Tracker.Dependency()
      if not self.users_to_tasks[member]
        self.users_to_tasks[member] = new Set()
      else if self.users_to_tasks[member].size > 0
        self.project_members_to_dependency[member].changed()
        self.users_to_tasks[member].clear()
      self.tasks_to_users = {}

    include_tasks = []
    project_id = delivery_planner_project_id.get()

    if project_id != "*"
      include_tasks.push project_id
      path = APP.modules.project_page.gridData().getCollectionItemIdPath(project_id)
      gc = APP.modules.project_page.mainGridControl()
      gc._grid_data.each path, (section, item_type, item_obj, path) ->
        include_tasks.push item_obj._id
        return

    dates = dates_to_display.get()

    first_date_to_display = dates[0]
    last_date_to_display = dates[dates.length - 1]

    dates_part = [
      #regular followup date
      {follow_up: {$in: dates}},
      #private followup date
      {"priv:follow_up": {$in: dates}},
      #end date in between the dates
      {$and: [
        {end_date: {$gte: first_date_to_display}},
        {end_date: {$lte: last_date_to_display}}
      ]},
      #due date in between the dates
      {$and: [
        {due_date: {$gte: first_date_to_display}},
        {due_date: {$lte: last_date_to_display}}
      ]},
      #start date in between the dates
      {$and: [
        {start_date: {$gte: first_date_to_display}},
        {start_date: {$lte: last_date_to_display}}
      ]},
      # start before and end after
      {$and: [
        {start_date: {$lt: first_date_to_display}},
        {end_date: {$gt: last_date_to_display}}
      ]},
      # start before and due after
      {$and: [
        {start_date: {$lt: first_date_to_display}},
        {due_date: {$gt: last_date_to_display}}
        {end_date: {$exists: false}}  # we will mark a task between start and due only if it has no end_date
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
    return

  @autorun =>
    project_id = delivery_planner_project_id.get()
    if project_id? and project_id != "*"
      # project_id in this case is actually a task id
      descendants = APP.modules.project_page.mainGridControl()._grid_data._grid_data_core.getAllItemsKnownDescendantsIdsObj([project_id])
      task_ids = _.keys(descendants)
      task_ids.push project_id
      sub_tree_task_ids.set task_ids
      JD.subscribeItemsAugmentedFields task_ids, ["users"]

    return

  return # end onCreated

Template.justdo_calendar_project_pane.onRendered ->
  instance = @

  $(".calendar_view_project_selector").on "shown.bs.dropdown", ->
    $(".calendar-view-project-search").focus().val ""
    instance.calendar_projects_filter_val.set ""
    return

  return # end onRendered

Template.justdo_calendar_project_pane.helpers
  onSelectedMembersChange: ->
    tpl = Template.instance()
    return (members) ->
      tpl.calendar_filtered_members.set members

      return

  currentUserDependency: ->
    return Template.instance().project_members_to_dependency[Meteor.userId()]

  userDependency: ->
    return Template.instance().project_members_to_dependency[@]

  currentUserTasksSet: ->
    return Template.instance().users_to_tasks[Meteor.userId()]

  userTasksSet: ->
    return Template.instance().users_to_tasks[@]

  membersCollapseState: ->
    return Template.instance().calendar_members_collapse_state_rv.get()

  title_date: ->
    view_resolution = number_of_days_to_display.get()

    if view_resolution >= 56
      date_format = "MMMM Do, YYYY"
    else
      date_format = "MMMM Do"

    return "#{moment(Template.instance().view_start_date.get()).format(date_format)} - #{moment(Template.instance().view_end_date.get()).format(date_format)} "

  currentUserId: ->
    return Meteor.userId()

  allOtherUsers: ->
    filtered_members = Template.instance().calendar_filtered_members.get()
    return _.sortBy filtered_members, (user_id) -> JustdoHelpers.displayName(user_id).toLowerCase()

  projectsInJustDo: ->
    tmpl = Template.instance()
    calendar_projects_filter_val = tmpl.calendar_projects_filter_val.get()

    project = APP.modules.project_page.project.get()

    if project?
      projects = APP.collections.Tasks.find({
        "p:dp:is_project": true
        "p:dp:is_archived_project":
          $ne: true
        project_id: project.id
      }, {sort: {"title": 1}}).fetch()

      if not calendar_projects_filter_val? or calendar_projects_filter_val == ""
        return projects

      filter_regexp = new RegExp("#{JustdoHelpers.escapeRegExp(calendar_projects_filter_val)}", "i")

      projects = _.filter projects, (doc) ->

        if filter_regexp.test(doc.title)
          return true

        return false

      return projects

  datesToDisplay: ->
    return dates_to_display.get()

  deliveryPlannerProjectId: ->
    return delivery_planner_project_id.get()

  formatDate: (viewResolution) ->
    date = moment.utc(@, "YYYY-MM-DD")
    if number_of_days_to_display.get() == 7
      formattedDate = "<span class='week_day'>" + date.format("ddd") + "</span>" + date.format("Do")
    if number_of_days_to_display.get() == 14
      formattedDate = "<span class='week_day'>" + date.format("dd") + "</span>" + date.format("D")
    if number_of_days_to_display.get() > 14
      formattedDate = date.format("D")
    return formattedDate

  isToday: (date) ->
    if moment(date).isSame(Template.instance().today.get(), "d")
      return true
    return false

  isHoliday: (date) ->
    if Template.instance().justdo_level_holidays.get().has(date)
      return "is_holiday"
    return ""

  isFirstDayOfWeek: (date) ->
    return moment.utc(date, "YYYY-MM-DD").day() == Meteor.user().profile.first_day_of_week

  weekNumber: ->
    return moment(@).isoWeek()

  calendarViewResolution: -> number_of_days_to_display.get()

  currentMemberAvatar: ->
    user = Meteor.user()
    if user?
      return JustdoAvatar.showUserAvatarOrFallback(user)

  currentMemberName: ->
    return JustdoHelpers.displayName(Meteor.userId())

  members: ->
    tmpl = Template.instance()
    project_id = delivery_planner_project_id.get()
    other_users = []

    if project_id == "*"
      other_users = _.difference(APP.modules.project_page.curProj()?.getMembersIds(), [Meteor.userId()])
    else
      task_ids = sub_tree_task_ids.get()

      other_users = new Set()

      APP.collections.TasksAugmentedFields.find
        _id:
          $in: task_ids
      ,
        fields:
          users: 1
      .forEach (task) ->
        if task.users?
          for user_id in task.users
            other_users.add user_id

        return

      other_users.delete Meteor.userId()
      other_users = Array.from other_users

    other_users_docs = []

    for user_id in other_users
      if (user_doc = Meteor.users.findOne(user_id, {_id: 1}))?
        other_users_docs.push user_doc

    membersDocs = other_users_docs

    membersDocsSortByName = JustdoHelpers.sortUsersDocsArray membersDocs

    members = []

    for member_doc in membersDocsSortByName
      members.push member_doc._id

    return members

Template.justdo_calendar_project_pane.events
  "click .calendar_view_zoom_out": ->
    index = config.supported_days_resolution.indexOf number_of_days_to_display.get()
    if index < config.supported_days_resolution.length - 1
      number_of_days_to_display.set(config.supported_days_resolution[index + 1])
    return

  "click .calendar_view_zoom_in": ->
    index = config.supported_days_resolution.indexOf number_of_days_to_display.get()
    if index > 0
      number_of_days_to_display.set(config.supported_days_resolution[index - 1])
    return

  "click .expand_all": (e, tpl) ->
    for member, state of members_collapse_state_vars
      state.set(false)

    tpl.calendar_members_collapse_state_rv.set false

    return

  "click .collapse_all": (e, tpl) ->
    for member, state of members_collapse_state_vars
      state.set(true)

    tpl.calendar_members_collapse_state_rv.set true

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
    delivery_planner_project_id.set(project)
    return

  "keyup .calendar-view-project-search": (e, tmpl) ->
    value = $(e.target).val().trim()
    if _.isEmpty value
      tmpl.calendar_projects_filter_val.set null
    else
      tmpl.calendar_projects_filter_val.set value
    return

  "click .calendar-filter-member-item": (e, tmpl) ->
    e.preventDefault()
    e.stopPropagation()

    user_id = Blaze.getData(e.target)
    filtered_members = tmpl.calendar_filtered_members.get()

    if (index = filtered_members.indexOf user_id) > -1
      filtered_members.splice(index, 1)
    else
      filtered_members.push user_id

    tmpl.calendar_filtered_members.set filtered_members

    return

  "keydown .calendar_view_project_selector .dropdown-menu": (e, tmpl) ->
    $dropdown_item = $(e.target).closest(".calendar-view-project-search,.dropdown-item")

    if e.keyCode == 38 # Up
      e.preventDefault()
      if ($prev_item = $dropdown_item.prevAll(".dropdown-item").first()).length > 0
        $prev_item.focus()
      else
        $(".calendar-view-project-search").focus()

    if e.keyCode == 40 # Down
      e.preventDefault()
      $dropdown_item.nextAll(".dropdown-item").first().focus()

    if e.keyCode == 27 # Escape
      $(".calendar_view_project_selector .dropdown-menu").dropdown "hide"

    return

Template.justdo_calendar_project_pane.onDestroyed ->
  if @refresh_today_interval?
    Meteor.clearInterval @refresh_today_interval

Template.justdo_calendar_project_pane_user_view.onCreated ->
  self = @
  @days_matrix = new ReactiveVar([])
  @dates_workload = new ReactiveVar({})
  @collapsed_view = new ReactiveVar @data.members_collapse_state

  if @data.user_id == Meteor.userId()
    @collapsed_view.set false

  members_collapse_state_vars[Template.currentData().user_id] = @collapsed_view
  @justdo_user_holidays = new Set()

  @last_tasks_set_size = 0
  @autorun =>

    data = Template.currentData()
    data.dependency.depend()

    @justdo_user_holidays = APP.justdo_resources_availability?.workdaysAndHolidaysFor(JD.activeJustdo({_id: 1})?._id, \
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
    last_date_to_display = data.dates_to_display[data.dates_to_display.length - 1]

    planned_seconds_field = "p:rp:b:work-hours_p:b:user:#{data.user_id}"
    executed_seconds_field = "p:rp:b:work-hours_e:b:user:#{data.user_id}"

    owner_part =
      $or: [
        {owner_id:  data.user_id}, #user is owner, and there is no pending owner
        {pending_owner_id: data.user_id}, #user is the pending owner
        {"#{planned_seconds_field}": {$gt: 0}}, #user has planned hours on the task
        {"priv:follow_up": {$exists: true}}
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
        priority: 1
        "#{JustdoPlanningUtilities.load_percent_field_id}": 1

    self.dates_workload.set({})
    query = {$and: [_id: {$in: Array.from(data.tasks_set)}, owner_part]}

    task_ids_need_to_sub = []
    APP.collections.Tasks.find query,
      fields:
        _id: 1
    .forEach (task) ->
      task_ids_need_to_sub.push task._id
    JD.subscribeItemsAugmentedFields task_ids_need_to_sub, ["users"]

    APP.collections.Tasks.find(query, options).forEach (task) ->
      task_details =
        _id: task._id
        title: task.title
        pending_owner_id: task.pending_owner_id
        owner_id: task.owner_id
        sequence_id: task.seqId
        end_date: task.end_date
        due_date: task.due_date
        start_date: task.start_date
        state: task.state
        unassigned_hours: task["p:rp:b:unassigned-work-hours"]
        users: APP.collections.TasksAugmentedFields.findOne(task._id)?.users
        "priv:follow_up": task["priv:follow_up"]
        priority: task.priority
        load_percent: task[JustdoPlanningUtilities.load_percent_field_id]

      #deal with  regular followups

      if task.follow_up and
            (task.owner_id == data.user_id or task.pending_owner_id == data.user_id) and
            data.dates_to_display.indexOf(task.follow_up) > -1
        day_index = data.dates_to_display.indexOf(task.follow_up)
        day_column = days_matrix[day_index]
        row_index = 0
        while true
          if not day_column[row_index]?

            day_column[row_index] =
              task: task_details
              type: "F"# F for followup, P for private followup, R for regular
              span: 1
            break
          row_index += 1

      #deal with private followups
      if task["priv:follow_up"] and data.dates_to_display.indexOf(task["priv:follow_up"]) > -1 and data.user_id == Meteor.userId()
        day_index = data.dates_to_display.indexOf(task["priv:follow_up"])
        day_column = days_matrix[day_index]
        row_index = 0
        while true
          if not day_column[row_index]?
            day_column[row_index] =
              task: task_details
              type: "P" # F for followup, P for private followup, R for regular
              span: 1
            break
          row_index += 1

      #deal with regular tasks
      if (task.start_date? and task.start_date >= first_date_to_display and task.start_date <= last_date_to_display) or
         (task.end_date? and task.end_date >= first_date_to_display and task.end_date <= last_date_to_display) or
         (task.due_date? and task.due_date >= first_date_to_display and task.due_date <= last_date_to_display) or
         (task.start_date? and task.end_date? and task.start_date < first_date_to_display and task.end_date > last_date_to_display) or
         (task.start_date? and task.due_date? and task.start_date < first_date_to_display and task.due_date > last_date_to_display)

        start_date = ""
        starts_before_view = false
        if task.start_date?
          start_date = task.start_date
        else if task.end_date?
          start_date = task.end_date
        else
          start_date = task.due_date

        end_date = ""
        ends_after_view = false
        if task.end_date?
          end_date = task.end_date
        else if task.due_date?
          end_date = task.due_date
        else
          end_date = task.start_date

        # Dealing with cases where start and end dates are out of the view, but due date is w/in.
        if ((
          (start_date < first_date_to_display and end_date < first_date_to_display) or
          (start_date > last_date_to_display and end_date > last_date_to_display )
          ) and task.due_date >= first_date_to_display and task.due_date <= last_date_to_display
        )
          start_date = task.due_date
          end_date = task.due_date

        start_day_index = data.dates_to_display.indexOf(start_date)
        if start_day_index == -1 and start_date < data.dates_to_display[0]
          start_day_index = 0
          starts_before_view = true
        end_day_index = data.dates_to_display.indexOf(end_date)
        if end_day_index == -1 and end_date > data.dates_to_display[data.dates_to_display.length - 1]
          end_day_index = data.dates_to_display.length - 1
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
            if days_matrix[column_index]?[row_index]?
              row_is_free = false
          if row_is_free

            task_details.planned_seconds = task[planned_seconds_field]
            task_details.executed_seconds = task[executed_seconds_field]

            days_matrix[start_day_index][row_index] =
              task: task_details
              type: "R" # F for followup, P for private followup, R for regular
              span: end_day_index - start_day_index + 1
              starts_before_view: starts_before_view
              ends_after_view: ends_after_view
              start_date_after_due_date: start_date_after_due_date

            if start_day_index != end_day_index
              for i in [start_day_index + 1..end_day_index]
                days_matrix[i][row_index] =
                  task: task_details
                  type: "t" # F for followup, P for private followup, R for regular, t for cont task

            break
          row_index += 1
          # end of while true
        # end of dealing with regular tasks

      #now we need to loop over all days, and for each day count the total working hours

      dates_workload = {}

      task_to_flat_hours_per_day = {} # this is a cache var to hold hours per day for each task,
                                      # based on flat distribution of planned hours over workdays.
                                      # We clear it and repopulate it when working on the dates_workload
      flatHoursPerDay = (row_data) ->
        # Optimization: avoid calculations for tasks that don't have planned_seconds.
        if not row_data.task.planned_seconds? or row_data.task.planned_seconds == 0
          return 0

        if task_to_flat_hours_per_day[row_data.task._id]
          return task_to_flat_hours_per_day[row_data.task._id]
        start_date = moment(row_data.task.start_date)
        end_date = moment(row_data.task.end_date)
        if not row_data.task.start_date
          start_date = end_date
        if not row_data.task.end_date
          end_date = start_date
        if end_date <= start_date
          task_to_flat_hours_per_day[row_data.task._id] = row_data.task.planned_seconds / 3600
          return task_to_flat_hours_per_day[row_data.task._id]

        user_availability = APP.justdo_resources_availability.userAvailabilityBetweenDates start_date.format("YYYY-MM-DD"),
            end_date.format("YYYY-MM-DD"), JD.activeJustdo({_id: 1})._id, data.user_id

        if user_availability.working_days == 0
          user_availability.working_days = 1
        task_to_flat_hours_per_day[row_data.task._id] = row_data.task.planned_seconds / 3600 / user_availability.working_days
        return task_to_flat_hours_per_day[row_data.task._id]

      for column_index of days_matrix
        date = data.dates_to_display[column_index]

        for row in days_matrix[column_index]
          task_id = null

          #due to tasks placements, there might be empty rows in the column. we will avoid those:
          if not row?
            continue

          if row.type == "R" or row.type == "t"
            Meteor._ensure dates_workload, date
            #calcualte number of tasks:
            if not dates_workload[date].number_of_tasks
              dates_workload[date].number_of_tasks = 0
            dates_workload[date].number_of_tasks += 1

            if row.task.owner_id == self.data.user_id and row.task.load_percent?
              if not dates_workload[date].total_load_percent?
                dates_workload[date].total_load_percent = 0
              dates_workload[date].total_load_percent += row.task.load_percent
            else
              #calculate number of hours, assuming flat distribution of task's time over workdays
              if not dates_workload[date].total_hours
                dates_workload[date].total_hours = 0
              dates_workload[date].total_hours += flatHoursPerDay(row)

      self.days_matrix.set(days_matrix)
      self.dates_workload.set(dates_workload)
      Tracker.afterFlush ->
        setDragAndDrop()
      return # end of tasks.forEach

    # MEETINGS part
    # add meetings to the days matrix only if the plugin is there and only for the current user
    if (meetings = APP.meetings_manager_plugin?.meetings_manager?.meetings)? and data.user_id == Meteor.userId()
      query =
        $and: [
          date:
            $gte: new Date(moment(first_date_to_display))
        ,
          date:
            $lte: new Date(moment(last_date_to_display))
        ]
      meetings.find(query).forEach (meeting) ->
        row_index = 0
        day_index = data.dates_to_display.indexOf(moment(meeting.date).format("YYYY-MM-DD"))
        while true
          if not days_matrix[day_index][row_index]
            days_matrix[day_index][row_index] =
              meeting: meeting
              span: 1
            break
          row_index += 1
        return

    # Set drag and drop after user info has been expanded
    @autorun =>
      if not @collapsed_view.get()
        setTimeout (->
          setDragAndDrop()
          return
        ), 300
      return

    return

  return

Template.justdo_calendar_project_pane_user_view.onDestroyed ->
  delete members_collapse_state_vars[Template.currentData().user_id]
  return

Template.justdo_calendar_project_pane_user_view.onRendered ->
  setDragAndDrop()
  fixHeaderOnScroll()
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
    column_date = Template.instance().data.dates_to_display[@]
    dates_workload = Template.instance().dates_workload.get()

    if( daily_workload = dates_workload[column_date])
      ret = ""
      if config.bottom_line.show_number_of_tasks
        ret += "#{daily_workload.number_of_tasks} task(s) "
      if config.bottom_line.show_flat_hours_per_day
        ret += "#{daily_workload.total_hours.toFixed(1)} H "
      if config.bottom_line.show_workload
        workload = 0
        if daily_workload.total_load_percent?
          workload += daily_workload.total_load_percent

        if daily_workload.total_hours? and JD.activeJustdo({_id: 1})?._id
          user_available_hours = APP.justdo_resources_availability.userAvailabilityBetweenDates(column_date, column_date,
            JD.activeJustdo({_id: 1})._id, Template.instance().data.user_id).available_hours
          if user_available_hours
            workload += Math.round(daily_workload.total_hours / user_available_hours * 100)
        if workload == 0
          ret += "--"
        else
          ret += _bottomLinePercentHtml workload
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

    return [0..ret - 1]

  # NEED TO FIX IN THE FUTURE: Helper has to return the number of all possible rows
  navRowspan: ->
    return 9999

  firstRow: ->
    return (@ + 1) == 1

  markDaysOff: ->
    column_date = Template.instance().data.dates_to_display[@]
    if Template.instance().justdo_user_holidays.has(column_date)
      return "calendar_view_mark_days_off"
    return ""

  colNumbers: ->
    return [0..Template.instance().data.dates_to_display.length - 1]

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

    if (info = matrix[col_num]?[row_num])
      if info.task?
        return info.task._id
    return ""

  isMeeting: ->
    col_num = @
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if (info = matrix[col_num]?[row_num])?
      if info.meeting?
        return true
    return false

  startsBeforeView: ->
    return @starts_before_view and @type == "R"

  endsAfterView: ->
    return @ends_after_view and @type == "R"

  skipTD: ->
    col_num = @
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()

    if (info = matrix[col_num]?[row_num])
      return info.type == "t"
    return false

  cellData: ->
    col_num = @
    row_num = Template.parentData()
    matrix = Template.instance().days_matrix.get()
    return matrix[col_num]?[row_num]

  startDateAfterDueDate: ->
    return @start_date_after_due_date

  unassignedHours: ->
    if @type == "R" and @task.unassigned_hours > 0 and @task.owner_id == Template.instance().data.user_id
      seconds = @task.unassigned_hours
      minutes = Math.floor(seconds / 60)
      hours = Math.floor(minutes / 60)
      mins = minutes - hours * 60
      return "#{hours}:#{JustdoHelpers.padString(mins, 2)} H unassigned"
    return ""

  hasDueDate: ->
    if @type == "R" and @task.due_date
      return true
    return false

  dueDate: ->
    return "Due: #{@task.due_date}"

  highlightPastDueDate: ->
    if @task.due_date < moment().format("YYYY-MM-DD") and (@task.state in ["pending", "in-progress", "on-hold", "duplicate"])
      return "highlighted_due_date"
    return ""

  plannedHours: ->
    if @type == "R" and @task.planned_seconds > 0
      seconds = @task.planned_seconds
      overtime = false
      # the following is in case that someday we will want to display (config base) the time left
      # if @task.executed_seconds
      #   seconds -= @task.executed_seconds
      #
      # if seconds < 0
      #   seconds = -seconds
      #   overtime = true

      minutes = Math.floor(seconds / 60)
      hours = Math.floor(minutes / 60)
      mins = minutes - hours * 60
      if not overtime
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

  userInitials: (userId) ->
    initials = Meteor.users.findOne(userId)?.profile?.first_name?.charAt(0) + Meteor.users.findOne(userId)?.profile?.last_name?.charAt(0)
    return initials

  userName: (user_id) ->
    return  JustdoHelpers.displayName(user_id)

  projectName: ->
    # if this is a project, no need to append anything
    task_obj = APP.collections.Tasks.findOne(@task._id)
    if task_obj?["p:dp:is_project"]
      return ""

    # if we filter to a certain project, no need to display project name as well
    if (delivery_planner_project_id.get() != "*")
      return ""

    if (project_name = findProjectName(task_obj))?
      return "#{project_name} : "

    return ""

  additionalInfo: ->
    ret = ""
    if @task.priority > 0
      ret += "\nPriority: #{@task.priority}"
    if @task.planned_seconds
      seconds = @task.planned_seconds
      minutes = Math.floor(seconds / 60)
      hours = Math.floor(minutes / 60)
      mins = minutes - hours * 60
      ret += "\nPlanned: #{hours}:#{JustdoHelpers.padString(mins, 2)} hours"

    return ret

  priorityColor: (priority) ->
    # priority < 15 and 25 < priority < 35 contrast is too bad, the following takes care
    # of that
    if priority < 15
      priority = 15
    else if priority > 24 and priority < 35
      priority = 35
    return JustdoColorGradient.getColorRgbString priority

  taskStateLabel: (state_id) ->
    gc = APP.modules.project_page.gridControl()
    state_label = gc?.getSchemaExtendedWithCustomFields()?.state?.grid_values?[state_id]?.txt
    return state_label

  showTaskState: ->
    if number_of_days_to_display.get() > 14
      return false
    return true

_bottomLinePercentHtml = (workload) ->
  color = "blue"
  if workload >= JustdoCalendarView.underload_level and workload < JustdoCalendarView.overload_level
    color = "green"
  else if workload >= JustdoCalendarView.overload_level
    color = "red"
  return "<span style='color: #{color}'>#{workload}% </span>"

Template.justdo_calendar_project_pane_user_view.events
  "click .calendar_task_cell": (e, tpl) ->
    if (task_id = $(e.target).closest(".calendar_task_cell").attr("task_id"))?
      if (gcm = APP.modules?.project_page?.getCurrentGcm())?
        gcm.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(task_id)

      return
    return
  "click .calendar_meeting": (e, tpl) ->
    if APP.meetings_manager_plugin?
      APP.meetings_manager_plugin.renderMeetingDialog(@meeting._id)
    return

  "click .expand_user": (e, tpl) ->
    tpl.collapsed_view.set(false)
    return

  "click .collapse_user": (e, tpl) ->
    tpl.collapsed_view.set(true)
    return

  "click .clock": (e, tpl) ->
    e.stopPropagation()
    if (ra = APP.justdo_resources_availability)
      ra.displayConfigDialog JD.activeJustdo({_id: 1})._id, tpl.data.user_id
    return

  # "mouseover .calendar_task_cell" : (e, tpl)->
  #   if (elm = $(e.target).find(".fa-map-marker")[0])
  #     elm.style.visibility = 'visible'
  #   return
  #
  # for now I think that it's better not to have the hover events -AL
  # "mouseover .calendar_view_scroll_left_cell" : (e, tpl)->
  #   onSetScrollLeft()
  #   return
  #
  # "mouseout .calendar_view_scroll_left_cell" : (e, tpl)->
  #   onUnsetScrollLeftRight()
  #   return
  #
  # "mouseover .calendar_view_scroll_right_cell" : (e, tpl)->
  #   onSetScrollRight()
  #   return
  #
  # "mouseout .calendar_view_scroll_right_cell" : (e, tpl)->
  #   onUnsetScrollLeftRight()
  #   return
  #

  "click .calendar_view_scroll_left_cell" : (e, tpl) ->
    onClickScrollLeft()
    return

  "click .calendar_view_scroll_right_cell" : (e, tpl) ->
    onClickScrollRight()
    return
