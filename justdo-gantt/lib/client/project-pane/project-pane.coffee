Template.justdo_gantt.onCreated ->
  self = @

  @following_active_task = new ReactiveVar false

  @gantt_top_path = new ReactiveVar "/"
  @gantt_title = new ReactiveVar ""

  @dateStringToUTC = (date) ->
    re = /^\d\d\d\d-\d\d-\d\d$/g

    if not re.test date
      return Date.UTC(0)

    split_date = date.split("-")

    return Date.UTC(split_date[0], split_date[1] - 1, split_date[2])

  @drawGantt = ->
    if not (gcm = APP.modules.project_page?.grid_control_mux.get())?
      return

    if not (gc = gcm.getMainGridControl(true))?
      return

    top_path = self.gantt_top_path.get()
    top_path_depth = (top_path.split("/").length) - 2
    series = []
    current_series = {}

    no_data = true

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
      if item_obj.end_date
        data_obj.end = self.dateStringToUTC item_obj.end_date

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
    series.push
      name: "-"
      data: [{
        name: ""
        id: "--"
      }]

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

      plotOptions:
        series:
          animation: false

          point:
            events:
              click: ->
                gcm = APP.modules.project_page.getCurrentGcm()
                gcm.setPath(["main", @id], {collection_item_id_mode: true})
                return

      series: series

    $(".justdo-project-pane-tab-container").scrollTop(viewport_scroll_top)
    return # end of drawGantt

  return

Template.justdo_gantt.onRendered ->
  self = @

  APP.justdo_highcharts.requireHighcharts()

  # the following are the color codes for different 'depth' of the gantt baskets.
  # if 'deeper' depth is presented, highcharts will provide default colors
  @gantt_colors = ["#146eff", "#87a8de", "#d5e2f7", "#dbf8ff", "#dbfff3"]


  # this autorun makes the gantt following the selected task
  @autorun =>
    if self.following_active_task.get()
      if (current_path = JD.activePath())?
        self.gantt_top_path.set current_path
        self.gantt_title.set JustdoHelpers.taskCommonName(JD.activeItem({seqId: 1, title: 1}), 80)

        return

    self.gantt_top_path.set "/"
    self.gantt_title.set JD.activeJustdo().title

    return

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

    Tracker.nonreactive ->
      Meteor.defer ->
        # Defer is here to let the grid process the updates before we call the .each() iteration
        self.drawGantt()

        return

    return

  return

Template.justdo_gantt.helpers
  isFollowingActiveTask: ->
    tpl = Template.instance()

    return tpl.following_active_task.get()

Template.justdo_gantt.events
  "click .follow-active-task-toggle": (e, tpl) ->
    tpl.following_active_task.set(not tpl.following_active_task.get())
    
    return
