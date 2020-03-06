Template.justdo_gantt.onCreated ->
  self = @

  @config =
    work_hours_per_day: 8

  @chart_warnings = new ReactiveVar [] # structure: [{text: , task: }]
  @display_warnings = new ReactiveVar false

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

  @onDrop = (e) ->
    if (task_obj = JD.collections.Tasks.findOne e.target.task_id)?
      if e.target.milestone
        m = new moment(e.newPoint.start)
        m.subtract 1, 'day'
        JD.collections.Tasks.update
          _id:e.target.task_id
        ,
          $set:
            due_date: m.format("YYYY-MM-DD")
      else
        if e.newPoint.end
          m = new moment(e.newPoint.end)
          m.subtract 1, 'day'
          JD.collections.Tasks.update
            _id:e.target.task_id
          ,
            $set:
              end_date: m.format("YYYY-MM-DD")

        if e.newPoint.start
          JD.collections.Tasks.update
            _id:e.target.task_id
          ,
            $set:
              start_date: moment(e.newPoint.start).format("YYYY-MM-DD")
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
      hours_planned = item_obj['p:rp:b:work-hours_p'] / 3600
      if item_obj.start_date and (not item_obj.end_date) and (hours_planned > 0)
        workdays = self.hoursToUsedWorkdays hours_planned
        implied_end_date = new moment(item_obj.start_date)
        implied_end_date = implied_end_date.add(workdays - 1, 'days')
        Meteor._ensure self.implied_dates, item_obj._id
        self.implied_dates[item_obj._id].end_date = implied_end_date.format "YYYY-MM-DD"

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
          hours_planned = task_obj['p:rp:b:work-hours_p'] / 3600
          if (not task_obj.end_date) and (hours_planned > 0)
            workdays = self.hoursToUsedWorkdays hours_planned
            implied_end_date = new moment(start_date)
            implied_end_date = implied_end_date.add(workdays - 1, 'days')
            self.implied_dates[task_obj._id].end_date = implied_end_date.format "YYYY-MM-DD"

          keep_looping = true

    return

  @drawGantt = ->
    day = 1000 * 60 * 60 * 24
    five_hours = 1000 * 60 * 60 * 5

    if not (gcm = APP.modules.project_page?.grid_control_mux.get())?
      return

    if not (gc = gcm.getMainGridControl(true))?
      return

    # Note: I was considering here if to make the notes textual or structural. Although structural is the right thing
    # to do, I'm going now with textual, in order to reduce coding time.
    chart_warnings = []

    top_path = self.gantt_top_path.get()
    top_path_depth = (top_path.split("/").length) - 2
    series = []
    current_series = {}

    no_data = true
    object_count = 0
    from_date = null
    to_date = null

    options =
      expand_only: false
      filtered_tree: false

    self.calculateImpliedDates gc, top_path, options

    # the following is a map of depth to data object. It is used to calculate if child tasks exceed any of the parent
    # end or due dates.
    parents_data_objects = {}

    current_series =
      name: "top series"
      data: []
      dataLabels: [
        enabled: true
        format: '<i class="fa fa-{point.font_symbol_right}"></i>'
        useHTML: true
        align: 'right'
      ,
        enabled: true
        format: '<i class="fa fa-{point.font_symbol_after_right}" title="Implied based on planned time"></i>'
        useHTML: true
        align: 'right'
        x: 8
        y: 18
        color: "#5234eb"
      ,
        enabled: true
        format: '<i class="fa fa-{point.font_symbol_left}"></i>'
        useHTML: true
        align: 'left'
      ,
        enabled: true
        format: '<i class="fa fa-{point.font_symbol_before_left}" title="Implied based on dependencies"></i>'
        useHTML: true
        align: 'left'
        x: -8
        y: 18
        color: "#5234eb"
      ]
    series.push current_series


    gc._grid_data.each top_path, options, (section, item_type, item_obj, path) ->

      path_depth = (path.split("/").length) - 2
      item_label = JustdoHelpers.taskCommonName(item_obj, 40)

      data_obj =
        name: item_label
        id: item_obj._id
        color: self.gantt_colors[path_depth - top_path_depth - 1]
        seqId: item_obj.seqId
        task_id: "#{item_obj._id}"

      parents_data_objects[path_depth] = data_obj
      #remove 'deeper' levels if exist
      level = path_depth + 1
      while parents_data_objects[level]
        delete parents_data_objects[level]
        level += 1

      if path_depth > top_path_depth + 1
        data_obj.parent = path.split("/")[path_depth-1]

      start = null
      implied_start = false

      if item_obj.start_date
        start = item_obj.start_date
      else if self.implied_dates[item_obj._id]?.start_date
        start = self.implied_dates[item_obj._id].start_date
        implied_start = true

      end = null
      implied_end = false

      if item_obj.end_date
        end = item_obj.end_date
      else if self.implied_dates[item_obj._id]?.end_date
        end = self.implied_dates[item_obj._id].end_date
        implied_end = true
      else if start and item_obj.due_date and self.dateStringToUTC(start) < self.dateStringToUTCEndOfDay(item_obj.due_date)
        end = item_obj.due_date

      if start
        data_obj.start = self.dateStringToUTC start
        # deal with situation when we have start w/o end
        if not end
          data_obj.end = five_hours + self.dateStringToUTC start
          data_obj.font_symbol_left = 'arrow-right'
        if implied_start
          data_obj.font_symbol_before_left = 'chain'

        # set the lowest point on the chart
        if not from_date or from_date > data_obj.start
          from_date = data_obj.start

      if end
        data_obj.end = self.dateStringToUTCEndOfDay end
        # deal with situations when we have end w/o start
        if not start
          data_obj.start = data_obj.end - five_hours
          data_obj.font_symbol_right = 'step-forward'
        if implied_end
          data_obj.font_symbol_after_right = 'chain'

        #set the highest point on the chart
        if not to_date or to_date < data_obj.end
          to_date = data_obj.end

      if item_obj.state == "done"
        data_obj.completed =
          amount: 1



      if APP.justdo_dependencies?.isPluginInstalledOnProjectDoc()
        data_obj.dependency = []
        for dependency_obj in APP.justdo_dependencies.getTaskDependenciesTasksObjs(item_obj)
          data_obj.dependency.push dependency_obj._id

          # checking if the dependency triggers a warning
          dependency_end_date = null
          if dependency_obj.end_date
            dependency_end_date = dependency_obj.end_date
          else if self.implied_dates[dependency_obj._id]?.end_date
            dependency_end_date = self.implied_dates[dependency_obj._id]?.end_date
          if dependency_end_date and  (self.dateStringToUTCEndOfDay(dependency_end_date) > data_obj.start)
            chart_warnings.push
              text: "[F2S violation] - Task: ##{data_obj.seqId} starts before task ##{dependency_obj.seqId} ends."
              task: data_obj.id



      # present due-dates as milestones
      if item_obj.due_date

        milestone_data_obj =
          name: item_label
          color: self.gantt_colors[path_depth - top_path_depth - 1]
          seqId: item_obj.seqId
          start: self.dateStringToUTCEndOfDay item_obj.due_date
          milestone: true
          task_id: "#{item_obj._id}"

        if data_obj.end? or data_obj.start?
          milestone_data_obj.id = "ms: #{item_obj._id}"
        else
          milestone_data_obj.id = "#{item_obj._id}"
          data_obj.id = "empty_task: #{data_obj.id}"

        if data_obj.end? and milestone_data_obj.start < data_obj.end
          milestone_data_obj.color = 'red'

        if path_depth > top_path_depth + 1
          milestone_data_obj.parent = path.split("/")[path_depth-1]

        if not to_date or to_date < milestone_data_obj.start
          to_date = milestone_data_obj.start
        if not from_date or from_date > milestone_data_obj.start
          from_date = milestone_data_obj.start

        current_series.data.push milestone_data_obj

      current_series.data.push data_obj
      object_count += 1
      no_data = false

      # check if data_obj violates any of its parents end-times or due dates
      if data_obj.end and (path_depth > top_path_depth + 1)
        for i in [(top_path_depth + 1)..(path_depth - 1)]
          parent = parents_data_objects[i]
          if parent.end and data_obj.end > parent.end
            chart_warnings.push
              text: "[Parent end-time violation] - Task: ##{data_obj.seqId} ends after its parent (##{parent.seqId})"
              task: data_obj.id

          if parent.milestone and data_obj.end > parent.start
            chart_warnings.push
              text: "[Parent due-date violation] - Task: ##{data_obj.seqId} ends after its parent (##{parent.seqId}) due date"
              task: data_obj.id

      return # end of _grid_data.each

    self.chart_warnings.set chart_warnings
    if no_data
      current_series.data = [
        name: ""
        id: "-"
      ]

    if _.isEmpty(series)
      $("#gantt-chart-container").html("""<h2 class="mt-5 text-center text-secondary">No information to build gantt chart</h2>""")
      return

    # we must add an empty series here to present the last series properly when collapsed
    # this entry is also used to create some margins around the actual data
    if from_date and not to_date
      to_date = from_date
    if to_date and not from_date
      from_date = to_date

    current_series.data.push
        name: ""
        id: "--"
        color: "#ffffff"
        start: from_date - 5 * 24 * 3600000
        end: to_date + 5 * 24 * 3600000

    object_count += 1

    viewport_scroll_top = $(".justdo-project-pane-tab-container").scrollTop()



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
        selected: 0

      xAxis:
        currentDateIndicator: true

      yAxis:
        uniqueNames: true
        labels:
          events:
            dblclick: (e) ->
              seq_id = parseInt(this.value.substr(1))
              if (task_id = JD.collections.Tasks.findOne({seqId: seq_id})._id)
                self.handleCtrlClick task_id
              return
            click: (e) ->
              if (gcm = APP.modules.project_page.getCurrentGcm())?
                seq_id = parseInt(this.value.substr(1))
                if (task_id = JD.collections.Tasks.findOne({seqId: seq_id})._id)
                  gcm.setPath(["main", task_id], {collection_item_id_mode: true})
              return

#      time:
#        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
#        useUTC: false

      plotOptions:
        series:
          animation: false
          allowPointSelect: true

          dragDrop:
            draggableX: true
            draggableY: false
            dragMinY: 0
            dragMaxY: 2
            dragPrecisionX: day

          point:
            events:
              dblclick: (e) ->
                self.handleCtrlClick @task_id
                return

              click: (e) ->
                gcm = APP.modules.project_page.getCurrentGcm()
                gcm.setPath(["main", @task_id], {collection_item_id_mode: true})
                return

              drop: (e)->
                return self.onDrop e


      series: series

    $(".justdo-project-pane-tab-container").scrollTop(viewport_scroll_top)
    return # end of drawGantt
  return

Template.justdo_gantt.onRendered ->
  self = @

  APP.justdo_highcharts.requireHighcharts()

  # the following are the color codes for different 'depth' of the gantt baskets.
  # if 'deeper' depth is presented, highcharts will provide default colors
  @gantt_colors = ["#5234eb", "#345feb", "#3483eb", "#349ceb", "#34baeb", "#34d3eb", "#34e2eb"]



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

  warnings: ->
    return Template.instance().chart_warnings.get()

  hasWarnings: ->
    if Template.instance().chart_warnings.get().length > 0
      return true
    return false

  displayWarnings: ->
    return Template.instance().display_warnings.get()

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

  "click .gantt-display_warnings": (e, tpl) ->
    tpl.display_warnings.set(not tpl.display_warnings.get())
    return

  "click .gantt-warnnings-list-container .close-button": (e, tpl) ->
    tpl.display_warnings.set false
    return


  "click .gantt-warnnings-list-container .warning-line": (e,tpl) ->
    task_id = e.target.id
    if (gcm = APP.modules.project_page.getCurrentGcm())?
      gcm.setPath(["main", task_id], {collection_item_id_mode: true})
    return

