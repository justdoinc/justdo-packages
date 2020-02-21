Template.justdo_gantt.onCreated ->
  self = @

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
        JD.collections.Tasks.update
          _id:e.newPointId
        ,
          $set:
            end_date: self.timeToDateString e.newPoint.end

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
            "#{field}": self.timeToDateString e.newPoint.start
    return

  @timeToDateString = (time) ->
    return moment(time).format("YYYY-MM-DD")

  @dateStringToUTC = (date) ->
    re = /^\d\d\d\d-\d\d-\d\d$/g

    if not re.test date
      return Date.UTC(0)

    split_date = date.split("-")

    return Date.UTC(split_date[0], split_date[1] - 1, split_date[2])

  @in_ctrl_key_mode = new ReactiveVar(false)
  @ctrl_key_mode_first_task_id = ""
  @handleCtrlClick = (e) ->
    if self.dependencies_module_installed.get == false
      return

    if not self.in_ctrl_key_mode.get()
      self.in_ctrl_key_mode.set true
      self.ctrl_key_mode_first_task_id = e.point.id


    else
      first_point = self.ctrl_key_mode_first_task_id
      second_point = e.point.id
      justdo_id = JD.activeJustdo({_id: 1})._id

      if APP.justdo_dependencies.tasksDependentF2S justdo_id, first_point , second_point
        APP.justdo_dependencies.removeFinishToStartDependency justdo_id, first_point, second_point
      else
        APP.justdo_dependencies.addFinishToStartDependency justdo_id, first_point, second_point


      self.in_ctrl_key_mode.set false
      self.ctrl_key_mode_first_task_id = ""

    return

  @stopCtrlClick = (e) ->
    self.in_ctrl_key_mode.set false
    self.ctrl_key_mode_first_task_id = ""

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

    gc._grid_data.each top_path,
      expand_only: false
      filtered_tree: false
    , (section, item_type, item_obj, path) ->

      path_depth = (path.split("/").length) - 2
      item_label = JustdoHelpers.taskCommonName(item_obj, 40)

      if path_depth == top_path_depth + 1
        current_series =
          name: item_label
          data: []
        series.push current_series

      data_obj =
        name: item_label
        id: item_obj._id
        color: self.gantt_colors[path_depth - top_path_depth - 1]

      if path_depth > top_path_depth + 1
        data_obj.parent = path.split("/")[path_depth-1]

      if item_obj.start_date
        data_obj.start = self.dateStringToUTC item_obj.start_date
        # deal with situation when we have start w/o end
        if not item_obj.end_date
          data_obj.end = five_hours + self.dateStringToUTC item_obj.start_date

        # set the lowest point on the chart
        if not from_date or from_date > data_obj.start
          from_date = data_obj.start

      if item_obj.end_date
        data_obj.end = day - 1 + self.dateStringToUTC item_obj.end_date # the "day - 1 +.." marks the time to the end of the day
        # deal with situations when we have end w/o start
        if not item_obj.start_date
          data_obj.start = data_obj.end - five_hours

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
              click: (e) ->
                if e.ctrlKey
                  return self.handleCtrlClick e
                else
                  self.stopCtrlClick e

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
    JD.collections.Tasks.find({project_id: project_id}, {fields: {_id: 1, title: 1, start_date: 1, end_date: 1, due_date: 1, state: 1, "#{JustdoDependencies.dependencies_field_id}": 1}}).fetch()

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
    title = JD.collections.Tasks.findOne(task_id).title
    return JustdoHelpers.ellipsis title, 30

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




