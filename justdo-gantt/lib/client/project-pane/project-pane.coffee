Template.justdo_gantt.onCreated ->
  self = @

  @config =
    work_hours_per_day: 8

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
    if (task_obj = JD.collections.Tasks.findOne e.newPointId)
      if e.newPoint.end
        m = new moment(e.newPoint.end)
        m.subtract 1, 'day'
        JD.collections.Tasks.update
          _id:e.newPointId
        ,
          $set:
            end_date: m.format("YYYY-MM-DD")

      if e.newPoint.start
        # here we can have either start_date or due_date. The current implementation doesn't allow both, and gives
        # preference to due date
        field = "start_date"
        if JD.collections.Tasks.findOne(e.newPointId).due_date
          field = "due_date"
        JD.collections.Tasks.update
          _id:e.newPointId
        ,
          $set:
            "#{field}": moment(e.newPoint.start).format("YYYY-MM-DD")
    return

  @dateStringToUTC = (date) ->
    re = /^\d\d\d\d-\d\d-\d\d$/g

    if not re.test date
      return Date.UTC(0)

    split_date = date.split("-")

    return Date.UTC(split_date[0], split_date[1] - 1, split_date[2])

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

    gc._grid_data.each top_path, options, (section, item_type, item_obj, path) ->

      path_depth = (path.split("/").length) - 2
      item_label = JustdoHelpers.taskCommonName(item_obj, 40)

      if path_depth == top_path_depth + 1
        current_series =
          name: item_label
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

      data_obj =
        name: item_label
        id: item_obj._id
        color: self.gantt_colors[path_depth - top_path_depth - 1]

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
        data_obj.end = day - 1 + self.dateStringToUTC end # the "day - 1 +.." marks the time to the end of the day
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

      # in regards to due dates - highcharts define that in milestones only the start option is handled, while end is ignored.
      # so therefore, we will add it a second time
      if item_obj.due_date
        data_obj.start = self.dateStringToUTC item_obj.due_date
        delete data_obj.end
        data_obj.milestone = true

      if APP.justdo_dependencies?.isPluginInstalledOnProjectDoc()
        data_obj.dependency = []
        for dependency_obj in APP.justdo_dependencies.getTaskDependenciesTasksObjs(item_obj)
          data_obj.dependency.push dependency_obj._id

      current_series.data.push data_obj
      object_count += 1
      no_data = false

      return # end of _grid_data.each

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
    series.push
      name: "-"
      data: [{
        name: ""
        id: "--"
        color: "#ffffff"
        start: from_date - 5 * 24 * 3600000
        end: to_date + 5 * 24 * 3600000
      }]
    object_count += 1

    viewport_scroll_top = $(".justdo-project-pane-tab-container").scrollTop()



    Highcharts.ganttChart "gantt-chart-container",

      # chart:
      #  height: 1 #Without first/default value height function doesn't work

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
        labels:
          events:
            dblclick: (e) ->
              seq_id = parseInt(this.value.substr(1))
              if (task_id = JD.collections.Tasks.findOne({seqId: seq_id})._id)
                self.handleCtrlClick task_id
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
                self.handleCtrlClick @id
                return

              click: (e) ->
                gcm = APP.modules.project_page.getCurrentGcm()
                gcm.setPath(["main", @id], {collection_item_id_mode: true})
                return

              drop: (e)->
                return self.onDrop e


      series: series
    ### the following is not working due to bug on filestack side. waiting for their reply
        https://github.com/highcharts/highcharts/issues/12012
    ###
    # ,
    #  (chart) ->
    #    # 40 is a pixel value for one cell
    #     chartHeight = 40 * object_count;
    #    chart.update({
    #      chart: {
    #        height: chartHeight
    #      }
    #    })

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

  selectedTaskTitle: ->
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




