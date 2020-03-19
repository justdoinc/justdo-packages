Template.justdo_gantt.onCreated ->
  self = @

  @config =
    work_hours_per_day: 8

  @chart_warnings = new ReactiveVar [] # structure: [{text: , task: }]

  @dependencies_module_installed = new ReactiveVar false
  @autorun =>
    curProj = -> APP.modules.project_page.curProj()
    if curProj().isCustomFeatureEnabled(JustdoDependencies.project_custom_feature_id)
      self.dependencies_module_installed.set true
    else
      self.dependencies_module_installed.set false
    return

  @gantt_top_path = new ReactiveVar "/"
  @gantt_title = new ReactiveVar ""

  @moveDependentTasksDueToEndDateUpdate = (original_task_obj_id) ->
    original_task_obj = JD.collections.Tasks.findOne original_task_obj_id

    # todo: this brings tasks from outside of the gantt as well, and we need to consider if to alert the user on moving
    # those as well, or if to ignore tasks that are not in the chart... The current implementation is updating all.


    JD.collections.Tasks.find({justdo_task_dependencies: original_task_obj.seqId}).forEach (dependee) ->
      latest_date = null
      # due to the asynchronous nature of the client side, we need to check the database and then overrider it with information
      # from the chart data
      JD.collections.Tasks.find({seqId: {$in: dependee.justdo_task_dependencies}}).forEach (depender) ->
        end_date = null
        if depender.end_date?
          end_date = depender.end_date

        if not latest_date? or end_date > latest_date
          latest_date = end_date
        return

      next_date = moment(latest_date)
      next_date.add 1, 'day'
      self.moveTaskToNewStartDate dependee, next_date.format("YYYY-MM-DD")
    return

  @moveTaskToNewStartDate = (task_obj, new_start_date) ->
    set_value = {}
    set_value.start_date = new_start_date
    user_id = task_obj.pending_owner_id or task_obj.owner_id
    project_id = task_obj.project_id
    previous_task_duration =
      working_days: 1
    previous_start_date = task_obj.start_date
    previous_end_date = task_obj.end_date or task_obj.due_date
    if previous_start_date and previous_end_date

      previous_task_duration = APP.justdo_resources_availability.userAvailabilityBetweenDates previous_start_date,
        previous_end_date, project_id, user_id

    new_end_date = APP.justdo_resources_availability.startToFinishForUser project_id, user_id,
      set_value.start_date, previous_task_duration.working_days, 'days'
    set_value.end_date = new_end_date

    JD.collections.Tasks.update
      _id: task_obj._id
    ,
      $set: set_value
    ,
        () ->

          # important note - must call with the _id and not the object, because the object changes by the update
          # call, but task_obj doesn't
          self.moveDependentTasksDueToEndDateUpdate task_obj._id
          #move all children that have no dependency to match the start time given their existing offset
          JD.collections.Tasks.find({"parents.#{task_obj._id}": {$exists:true}, $or: [{justdo_task_dependencies: {$exists: false}}, {justdo_task_dependencies: {$size: 0}} ]}).forEach (child_task_obj) ->
            # find offset between the childd and the parent task
            child_new_start_date = new_start_date
            if (child_task_obj.start_date)?
              child_offset = APP.justdo_resources_availability.justDoLevelWorkingDaysOffset task_obj.project_id, previous_start_date, child_task_obj.start_date
              child_new_start_date = APP.justdo_resources_availability.justDoLevelDateOffset task_obj.project_id, new_start_date, child_offset
            self.moveTaskToNewStartDate child_task_obj, child_new_start_date
            return #end of forEach
          return #end of callback
    return

  @onDrop = (e) ->
    if not (task_obj = e.target.justdo_data_line.task_obj)?
      return

    # dealing with milestones:
    if e.target.milestone
      m = new moment(e.newPoint.start)
      m.subtract 1, 'day'
      JD.collections.Tasks.update
        _id: task_obj._id
      ,
        $set:
          due_date: m.format("YYYY-MM-DD")
      return


    ###
    Based on ganttpro:
    - if the user moves only the end date - the intention is to change the task's duration
    - if the user moves the start date (or the entire task) - the intention is to calculate the new end-date based
      on the task's duration from before moving the task. In other words - keep the previous duration net of vacations
      and holidays
    ###
    if e.newPoint.end and not e.newPoint.start
      set_value = {}
      m = new moment(e.newPoint.end)
      m.subtract 1, 'day'
      set_value.end_date = m.format("YYYY-MM-DD")

      if not task_obj.start_date?
        set_value.start_date = (new moment(e.target.start)).format("YYYY-MM-DD")

      JD.collections.Tasks.update
        _id: task_obj._id
      ,
        $set: set_value
      ,
        # important note - must call with the _id and not the object, because the object changes by the update
        # call, but task_obj doesn't
          () ->
            self.moveDependentTasksDueToEndDateUpdate(task_obj._id)

      return

    if e.newPoint.start
      self.moveTaskToNewStartDate task_obj, moment(e.newPoint.start).format("YYYY-MM-DD")

    return

  @dateStringToUTC = (date) ->
    re = /^\d\d\d\d-\d\d-\d\d$/g

    if not re.test date
      return Date.UTC(0)

    split_date = date.split("-")

    return Date.UTC(split_date[0], split_date[1] - 1, split_date[2])

  @dateStringToUTCEndOfDay = (date) ->
    day = 1000 * 60 * 60 * 24
    return day - 1 + self.dateStringToUTC date

  @in_ctrl_key_mode = new ReactiveVar(false)
  @ctrl_key_mode_first_task_id = ""
  @handleCtrlClick = (task_id) ->
    if self.dependencies_module_installed.get == false
      return

    if not self.in_ctrl_key_mode.get()
      self.in_ctrl_key_mode.set true
      self.ctrl_key_mode_first_task_id = task_id

    else
      first_point = self.ctrl_key_mode_first_task_id
      second_point = task_id
      justdo_id = JD.activeJustdo({_id: 1})._id

      if APP.justdo_dependencies.tasksDependentF2S justdo_id, first_point , second_point
        APP.justdo_dependencies.removeFinishToStartDependency justdo_id, first_point, second_point
      else
        APP.justdo_dependencies.addFinishToStartDependency justdo_id, first_point, second_point

      self.in_ctrl_key_mode.set false
      self.ctrl_key_mode_first_task_id = ""

    return

  @stopCtrlClick = ->
    self.in_ctrl_key_mode.set false
    self.ctrl_key_mode_first_task_id = ""
    return

  # here we deal with whole dates, so always round up. 3 hours will become one day. 9 hours will be two days
  @hoursToUsedWorkdays = (hours) ->
    return Math.ceil(hours / self.config.work_hours_per_day)

  @implied_dates = {}
  @calculateImpliedDates = (gc, top_path, options) ->
    self.implied_dates = {} # map of task_id to {end_date:...., start_date:...}

    tasks_with_potential_implied = {}
    # 1. for those tasks with start time and no end time, imply end time
    gc._grid_data.each top_path, options, (section, item_type, item_obj, path) ->
      hours_planned = (item_obj['p:rp:b:work-hours_p'] / 3600) or 8

      if item_obj.start_date and (not item_obj.end_date)
        workdays = self.hoursToUsedWorkdays hours_planned
        implied_end_date = new moment(item_obj.start_date)
        implied_end_date = implied_end_date.add(workdays - 1, 'days')
        Meteor._ensure self.implied_dates, item_obj._id
        self.implied_dates[item_obj._id].end_date = implied_end_date.format "YYYY-MM-DD"


      if (not item_obj.start_date) and item_obj.end_date
        workdays = self.hoursToUsedWorkdays hours_planned
        implied_start_date = new moment(item_obj.end_date)
        implied_start_date = implied_start_date.subtract(workdays - 1, 'days')
        Meteor._ensure self.implied_dates, item_obj._id
        self.implied_dates[item_obj._id].start_date = implied_start_date.format "YYYY-MM-DD"

      # for tasks that have no start time and not end time imply 'today', (later on will mark them with white background)
      if not item_obj.start_date and not item_obj.end_date
        Meteor._ensure self.implied_dates, item_obj._id
        self.implied_dates[item_obj._id].start_date = moment().format("YYYY-MM-DD")
        self.implied_dates[item_obj._id].end_date = moment().format("YYYY-MM-DD")
        self.implied_dates[item_obj._id].implied_for_today_as_a_regular_task = true


      # at the same time, identify tasks that are potential for implied dates, ie. tasks that are dependent F2S on
      # other task
      if (dependencies = APP.justdo_dependencies?.getTaskDependenciesTasksObjs(item_obj))
        if dependencies.length > 0
          tasks_with_potential_implied[item_obj._id] = dependencies

    # 2. next loop on the potential tasks and see if implied dates can be set, repeat until there is no change

    keep_looping = true
    while keep_looping
      keep_looping = false
      for task_id, dependencies of tasks_with_potential_implied
        # check if all dependencies have end_date or implied end_date
        imply_start_date = true
        biggest_end_date = null
        for dependency in dependencies
          end_date = ""
          if dependency.end_date
            end_date = dependency.end_date
          else if (implied_end = self.implied_dates[dependency._id]?.end_date)?
            end_date = implied_end
          else if dependency.due_date
            end_date = dependency.due_date
          if end_date == ""
            imply_start_date = false
            break
          if not biggest_end_date
            biggest_end_date = end_date
          else if end_date > biggest_end_date
              biggest_end_date = end_date
        if imply_start_date
          Meteor._ensure self.implied_dates, task_id
          start_date = moment(biggest_end_date).add(1, 'day').format("YYYY-MM-DD")
          self.implied_dates[task_id].start_date = start_date
          delete tasks_with_potential_implied[task_id]
          # also set the end-date here
          task_obj = JD.collections.Tasks.findOne task_id
          if (task_obj['p:rp:b:work-hours_p'])?
            hours_planned = task_obj['p:rp:b:work-hours_p'] / 3600
          else
            hours_planned = 8
          if (not task_obj.end_date) and (hours_planned > 0)
            workdays = self.hoursToUsedWorkdays hours_planned
            implied_end_date = new moment(start_date)
            implied_end_date = implied_end_date.add(workdays - 1, 'days')
            self.implied_dates[task_obj._id].end_date = implied_end_date.format "YYYY-MM-DD"

          keep_looping = true

    return

  @ganttRawData = (gc, top_path, options) ->
    ###
    collect data and build an array with all the relevant information.
    each item is an object of the following structure:
      obj =
        task_obj: the original task object
        depth: 0 based index of the depth of the task
        is_basket: true if task has child-tasks
        parent_id: parent index based on path (to support multiple parents) if exists
   ###
    top_path_depth = top_path.split("/").length - 2
    index = 0
    lines = []
    depth_to_index = {}
    gc._grid_data.each top_path, options, (section, item_type, item_obj, path) ->
      parents = path.split("/")
      path_depth = parents.length - 3 - top_path_depth
      depth_to_index[path_depth] = index
      object =
        task_obj: item_obj
        depth: path_depth
      if path_depth > 0
        object.parent_index = depth_to_index[path_depth - 1]
      lines.push object

      #if current task is deeper than the previous one, change the previous into a basket
      prev_index = index - 1
      if index > 0 and lines[index].depth > lines[prev_index].depth
        lines[prev_index].is_basket = true

      index += 1
    return lines

  @indexGanttLines = (gantt_lines) ->
    ###
    return a map of task_id to Set of lines indexes
    ###
    map = {}
    index = 0
    _.each gantt_lines, (line) ->
      if not map[line.task_obj._id]?
        map[line.task_obj._id] = new Set()
      map[line.task_obj._id].add index
      index += 1
    return map

  @addDependenciesDataToGanttLines = (gantt_lines, task_id_to_gantt_lines) ->
    ###
    Add dependencies to the gantt lines objects when applicable.
    each is a Set of the line indexes of the dependers
    ###
    _.each gantt_lines, (line) ->
      if (dependencies = APP.justdo_dependencies?.getTaskDependenciesTasksObjs(line.task_obj))
        if dependencies.length > 0
          line.dependencies = new Set()
          _.each dependencies, (dependency) ->
            task_id_to_gantt_lines[dependency._id].forEach (dependency_index) ->
              line.dependencies.add dependency_index
              return
            return
    return

  @initializeSeries = () ->
    series = []
    current_series =
      name: "top series"
      data: []
      dataLabels: [
        enabled: true
        formatter: ->
          if not @point.milestone
            return @point.name
          return ""
        align: 'center'
      ,
        enabled: true
        formatter: ->

          if @point.justdo_data_line?.warnings? and not @point.milestone
            warning = """
              <button class="btn btn-light btn-sm gantt-warning-icon" type="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                <svg class="jd-icon " point_number="#{@point.id}">
                  <use xlink:href="/layout/icons-feather-sprite.svg#alert-triangle"/>
                </svg>
              </button>
              <ul class="dropdown-menu jd-p-075 shadow-lg border-0">
            """
            _.forEach @point.justdo_data_line.warnings, (line_warning) ->
              warning += "<li><a href=\"#\" class=\"dropdown-item px-1\" >#{line_warning.text}</a></li>"
              return
            warning += """
              </ul>
              """

            return warning
          return ""
        align: 'right'
        x: 15
        y: -24
        color: "red"
        useHTML: true
      ,
        enabled: false
        format: '<i class="fa fa-{point.font_symbol_right}"></i>'
        useHTML: true
        align: 'right'
      ,
        enabled: false
        format: '<i class="fa fa-{point.font_symbol_after_right}" title="Implied based on planned time"></i>'
        useHTML: true
        align: 'right'
        x: 8
        y: 18
        color: "#5234eb"
      ,
        enabled: false
        format: '<i class="fa fa-{point.font_symbol_left}"></i>'
        useHTML: true
        align: 'left'
      ,
        enabled: false
        format: '<i class="fa fa-{point.font_symbol_before_left}" title="Implied based on dependencies"></i>'
        useHTML: true
        align: 'left'
        x: -8
        y: 18
        color: "#5234eb"
      ]
    series.push current_series
    return series

  @addDatesToGanttLines = (gantt_lines) ->
    ###
    Add to the gantt lines start end end dates (YYYY-MM-DD), and is_implies when applicable
    ###
    _.each gantt_lines, (line, task_id_to_gantt_lines) ->

      if line.is_basket and self.implied_dates[line.task_obj._id]?.implied_for_today_as_a_regular_task
        return

      if line.task_obj.start_date?
        line.start = line.task_obj.start_date
      else if self.implied_dates[line.task_obj._id]?.start_date
        line.start = self.implied_dates[line.task_obj._id].start_date
        line.implied_start = true

      if line.task_obj.end_date?
        line.end = line.task_obj.end_date
      else if self.implied_dates[line.task_obj._id]?.end_date
        line.end = self.implied_dates[line.task_obj._id].end_date
        line.implied_end = true
      else if line.start and line.task_obj.due_date? and line.start <= line.task_obj.due_date
        line.end = item_obj.due_date
      return
    return

  @addWarningsToGanttLines = (gantt_lines) ->
    depth = {}
    _.each gantt_lines, (line) ->
      depth[line.depth] = line

      # check due-date and end-dates
      if line.task_obj.due_date? and line.task_obj.due_date < line.end
        if not line.warnings?
          line.warnings = []
        line.warnings.push
          text: "[Task due-date violation] - Task: ##{line.task_obj.seqId} due-date is earlier than its end-date"
          task: line.task_obj._id

      # check parents end dates and start dates
      if line.depth > 0
        for i in [0..(line.depth - 1)]
          parent = depth[i]
          if parent.end < line.end
            if not line.warnings?
              line.warnings = []
            line.warnings.push
              text: "[Parent end-time violation] - Task: ##{line.task_obj.seqId} ends after its parent (Task ##{parent.task_obj.seqId})"
              task: line.task_obj._id

          if parent.start > line.start
            if not line.warnings?
              line.warnings = []
            line.warnings.push
              text: "[Parent start-time violation] - Task: ##{line.task_obj.seqId} starts before its parent (Task ##{parent.task_obj.seqId})"
              task: line.task_obj._id

      # check dependencies
      if line.dependencies?
        line.dependencies.forEach (depender_index) ->
          if gantt_lines[depender_index].end >= line.start
            if not line.warnings?
              line.warnings = []
            line.warnings.push
              text: "[F2S violation] - Task: ##{line.task_obj.seqId} starts before task ##{gantt_lines[depender_index].task_obj.seqId} ends."
              task: line.task_obj._id

      return # end of each

    return

  @drawGantt = ->
    if not (gcm = APP.modules.project_page?.grid_control_mux.get())?
      return

    if not (gc = gcm.getMainGridControl(true))?
      return

    top_path = self.gantt_top_path.get()
    top_path_depth = (top_path.split("/").length) - 2

    options =
      expand_only: false
      filtered_tree: false

    self.calculateImpliedDates gc, top_path, options
    gantt_lines = self.ganttRawData gc, top_path, options
    task_id_to_gantt_lines = self.indexGanttLines gantt_lines
    self.addDependenciesDataToGanttLines gantt_lines, task_id_to_gantt_lines
    self.addDatesToGanttLines gantt_lines
    series = self.initializeSeries()
    self.addWarningsToGanttLines gantt_lines

    # now that we have the data, we can draw the chart
    gantt_color_task = "#accefa" # "#3483eb"
    gantt_color_milestone = "#344feb"

    index = 0
    _.each gantt_lines, (line) ->
      # redular tasks:
      data_obj =
        name: JustdoHelpers.taskCommonName(line.task_obj, 40)
        id: "#{index}"
        justdo_data_line: line

      if line.start?
        data_obj.start = self.dateStringToUTC line.start
      if line.end?
        data_obj.end = self.dateStringToUTCEndOfDay line.end

      #set color:
      if line.is_basket
        #start_color = ganttGradientColor(line.depth)
        start_color = gantt_color_milestone
        end_color = gantt_color_task
        if (not line.start) and (not line.end)
          start_color = 'gray'
          end_color = 'white'

        data_obj.color =
          linearGradient:
            x1: 0
            x2: 0
            y1: 0
            y2: 1
          stops: [[0, start_color], [1, end_color]]

      else if line.implied_start and line.implied_end
        data_obj.color = 'white'
      else if line.implied_start and not line.implied_end
        data_obj.color =
          linearGradient:
            x1: 0
            x2: 1
            y1: 0
            y2: 0
          stops: [[0, 'white'], [1, gantt_color_task]]
      else if not line.implied_start and line.implied_end
        data_obj.color =
          linearGradient:
            x1: 0
            x2: 1
            y1: 0
            y2: 0
          stops: [[0, gantt_color_task], [1, 'white']]
      else
         data_obj.color = gantt_color_task

      if line.parent_index?
        data_obj.parent = "#{line.parent_index}"

      if line.dependencies
        data_obj.dependency = []
        line.dependencies.forEach (dependency_index) ->
          data_obj.dependency.push
            to: "#{dependency_index}"
            lineColor: gantt_color_task
            marker:
              color: gantt_color_task
          return

      series[0].data.push data_obj
      # end of regular task

      # present due-dates as milestones
      if line.task_obj.due_date
        milestone_data_obj =
          name: JustdoHelpers.taskCommonName(line.task_obj, 40)
          id: "ms: #{index}"
          color: gantt_color_milestone
          start: self.dateStringToUTCEndOfDay line.task_obj.due_date
          milestone: true
          justdo_data_line: line

        if line.parent_index?
          milestone_data_obj.parent = "#{line.parent_index}"

        series[0].data.push milestone_data_obj

      index += 1
      return # end of _.each

    # we must add an empty series here to present the last series properly when collapsed
    # this entry is also used to create some margins around the actual data
    min_start = null
    max_end = null
    _.each series[0].data, (data_obj) ->
      if not min_start or min_start > data_obj.start
        min_start = data_obj.start
      if data_obj.end and (not max_end or max_end < data_obj.end)
        max_end = data_obj.end
      #this one deals with milestones
      if data_obj.start and (not max_end or max_end < data_obj.start)
        max_end = data_obj.start

    series[0].data.push
      name: ""
      id: "--"
      color: "#ffffff"
      borderColor: 'white'
      start: min_start - 5 * 24 * 3600000
      end: max_end + 5 * 24 * 3600000
      pointWidth: 0

    Highcharts.ganttChart "gantt-chart-container",

      title:
        text: self.gantt_title.get()
        margin: 10

      navigator:
        enabled: true,
        liveRedraw: true,
        height: 10
        series:
          type: "gantt"
          pointPlacement: 0.5
          pointPadding: 0.25
          data: [{
            name: ""
            id: "--"
          }]

        yAxis:
          min: 0
          max: 3
          reversed: true
          categories: []

      scrollbar:
        enabled: true

      rangeSelector:
        enabled: true
        allButtonsEnabled: true
        selected: 0

      xAxis:
        currentDateIndicator: true

      yAxis:
        uniqueNames: true
        labels:
          events:
            dblclick: (e) ->
              self.handleCtrlClick gantt_lines[this.pos].task_obj._id
              return
            click: (e) ->
              if (gcm = APP.modules.project_page.getCurrentGcm())?
                task_id = gantt_lines[this.pos].task_obj._id
                gcm.setPath(["main", task_id], {collection_item_id_mode: true})
              return

      tooltip:
        formatter: (tooltip) ->
          ret = "<b>#{@point.name}</b><br>"
          if @x? and @x2?
            from_date = (new moment(@x)).format("YYYY-MM-DD")
            to_date = (new moment(@x2)).subtract(1, 'day').format("YYYY-MM-DD")
            if to_date < from_date  # this happens when a task ends mid-day (like when the end-time can't be calculated and
              # we add 5 hours to the chart
              ret += "#{from_date}"
            else
              ret += "#{from_date} .. #{to_date}"
          else if @x?
            date = (new moment(@x)).subtract(1, 'day').format("YYYY-MM-DD")
            ret += "#{date}"
          return ret

      plotOptions:
        series:
          animation: false
          allowPointSelect: false

          borderColor: '#303030'

          dragDrop:
            draggableX: true
            draggableY: false
            dragMinY: 0
            dragMaxY: 2
            dragPrecisionX: 1000 * 60 * 60 * 24
            draggableStart: false

          point:
            events:
              dblclick: (e) ->
                self.handleCtrlClick @justdo_data_line.task_obj._id
                return

              click: (e) ->
                if (gcm = APP.modules.project_page.getCurrentGcm())
                  gcm.setPath(["main", @justdo_data_line.task_obj._id], {collection_item_id_mode: true})
                return

              drop: (e)->
                return self.onDrop e

      series: series
    return

Template.justdo_gantt.onRendered ->
  self = @

  APP.justdo_highcharts.requireHighcharts()



  # this autorun triggers gantt charts redraws
  @autorun =>
    if not (gcm = APP.modules.project_page?.grid_control_mux.get())?
      return

    if not (gc = gcm.getMainGridControl(true))?
      return

    # Add reactivity to JustDos changes
    project_id = JD.activeJustdo({_id: 1, title: 1})._id
    # Add reactivity to Tasks changes
    JD.collections.Tasks.find({project_id: project_id}, {fields: {_id: 1, title: 1, start_date: 1, end_date: 1, due_date: 1, state: 1, "#{JustdoDependencies.dependencies_field_id}": 1, "p:rp:b:work-hours_p": 1}}).fetch()

    # Add reactivity to gantt title and top path
    self.gantt_title.get()
    self.gantt_top_path.get()
    # Add reactivity to un/install of the dependencies plugin
    APP.justdo_dependencies?.isPluginInstalledOnProjectDoc()

    Meteor.setTimeout self.drawGantt, 500
    return

  return

Template.justdo_gantt.helpers
  projectsInJustDo: ->
    project = APP.modules.project_page.project.get()
    if project?
      return APP.collections.Tasks.find({
        "p:dp:is_project": true
        project_id: project.id
      }, {sort: {"title": 1}}).fetch()

  notOnSameTask: ->
    if not JD.activePath()
      return false
    return JD.activePath() != Template.instance().gantt_top_path.get()

  hasSelectedTask: ->
    if JD.activeItem()
      return true
    return false

  selectedTaskTitle: ->
    if not JD.activeItem()
      return ""
    ret = "##{JD.activeItem({seqId: 1}).seqId} #{JD.activeItem({title: 1}).title}"
    return JustdoHelpers.ellipsis ret, 30

  selectedTaskId: ->
    return JD.activeItem({_id: 1})._id

  selectedGanttTask: ->
    path =  Template.instance().gantt_top_path.get()
    if path == "/"
      return "ENTIRE JUSTDO"
    task_id = path.split("/").reverse()[1]
    task_obj = JD.collections.Tasks.findOne(task_id)
    ret = JustdoHelpers.ellipsis task_obj.title, 30
    if task_obj.due_date
      ret += " Due: #{task_obj.due_date}"
    return  ret

  displayDependencyHint: ->
    return not Template.instance().in_ctrl_key_mode.get()

Template.justdo_gantt.events
#  "mouseover .gantt-warning-icon": (e) ->
#    debugger
#    return

  "click .gantt_project_selector a": (e) ->
    task_id = $(e.currentTarget).attr "task_id"
    if task_id == "*"
      Template.instance().gantt_top_path.set("/")
    else
      path = APP.modules.project_page.gridData().getCollectionItemIdPath(task_id)
      Template.instance().gantt_top_path.set path
    return

  "click .gantt_dependnecies_conntector_hint .cancel": (e, tpl) ->
    tpl.in_ctrl_key_mode.set false
    return
