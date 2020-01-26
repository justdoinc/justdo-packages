APP.justdo_highcharts.requireHighcharts()


Template.justdo_gantt.onCreated ->
  self = @

  # the following are the color codes for different 'depth' of the gantt baskets.
  # if 'deeper' depth is presented, highcharts will provide default colors
  @gantt_colors = ["#146eff","#87a8de", "#d5e2f7", "#dbf8ff", "#dbfff3"]


  @dateStringToUTC = (date) ->
    re = /^\d\d\d\d-\d\d-\d\d$/g
    if not re.test date
      return Date.UTC(0)
    split_date = date.split("-")
    return Date.UTC(split_date[0], split_date[1] - 1, split_date[2])

  @is_grid_data_ready = new ReactiveVar false
  @gantt_top_path = new ReactiveVar "/"
  @gantt_title = new ReactiveVar ""
  @following_active_task = new ReactiveVar false

  # this autorun makes the gantt following the selected task
  @autorun =>
    if self.following_active_task.get()
      if (current_path = JD.activePath())
        self.gantt_top_path.set current_path
        self.gantt_title.set JD.activeItem().title
        return
    self.gantt_top_path.set "/"
    return

  # this autorun deals with the gantt title
  @autorun =>
    top_path  = self.gantt_top_path.get()
    if top_path == "/"
      self.gantt_title.set JD.activeJustdo().title
      return

    return

  #this autorun draws the gantt chart
  @autorun =>
    if not (gc = APP.modules.project_page?.mainGridControl())
      return

    #trigger reactivity when grid data will be ready
    self.is_grid_data_ready.get()
    checkGridData = ->
      if gc._grid_data
        self.is_grid_data_ready.set true
      else
        setTimeout checkGridData, 500

    if not gc._grid_data
      setTimeout checkGridData, 500
      return

    top_path = self.gantt_top_path.get()
    top_path_depth = (top_path.split("/").length) - 2
    series = []
    current_series = {}

    no_data = true

    gc._grid_data.each top_path
    ,
      expand_only: false
      filtered_tree: false
    , (section, item_type, item_obj, path) ->
      path_depth = (path.split("/").length) - 2
      if path_depth == top_path_depth + 1
        current_series =
          name: item_obj.title
          data: []
        series.push current_series

      data_obj =
        name: item_obj.title
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


      # dealing with dependencies:
      if APP.justdo_dependencies
        if (dependencies = item_obj[APP.justdo_dependencies.pseudoFiledId()])
          data_obj.dependency = []
          dependencies.split(/\s*,\s*/).map(Number).forEach (dependant) ->
            if (dependent_task_obj = JD.collections.Tasks.findOne({seqId: dependant}))
              data_obj.dependency.push dependent_task_obj._id

      current_series.data.push data_obj
      no_data = false

      return # end of _grid_data.each

    if no_data
      current_series.data = [
        name: ""
        id: "-"
      ]


    # we must add an empty series here to present the last series properly when collapsed
    series.push
      name: "-"
      data: [{
        name: ""
        id: "--"
      }]


    Highcharts.ganttChart "gantt_chart_container"
    ,
      title:
        text: self.gantt_title.get()
        margin: 15

      navigator:
        enabled: true,
        liveRedraw: true,
        height: 10
        series:
          type: 'gantt'
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

          point:
            events:
              click: ->
                gcm = APP.modules.project_page.getCurrentGcm()
                gcm.setPath(["main", @id], {collection_item_id_mode: true})
                return

      series: series

    return # end of autorun

  return # end of onCreated

Template.justdo_gantt.events
  "change #jd_gantt_follow_active_item_id": (e, tpl) ->
    tpl.following_active_task.set $("#jd_gantt_follow_active_item_id").prop("checked")
    return

