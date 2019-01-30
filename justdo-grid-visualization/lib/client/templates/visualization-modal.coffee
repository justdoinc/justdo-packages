# NOTE: Code for generating grid input data moved to grid-visualization.coffee

Template.grid_visualization_modal.onCreated () ->
  @chartAPI = new ReactiveVar()
  APP.justdo_grid_visualization.onGoogleChartsLoad (chart) => @chartAPI.set(chart)
  @canvgAPI = new ReactiveVar()
  APP.justdo_grid_visualization.onCanvgLoad (canvg) => @canvgAPI.set(canvg)

  grid_data = APP.justdo_grid_visualization.computeGridData(@data.path, @data.item, @data.grid)

  if not _.isArray(grid_data)
    @errors = grid_data?.errors or [{ message: "unknown-error" }]
  else
    @chartData = grid_data

Template.grid_visualization_modal.helpers
  title: () ->
    if @path == "/"
      project = APP.collections.Projects.findOne(@project.id)
      return project.title

    item = @item
    if item?
      return item?.title

  errors: () ->
    return Template.instance().errors

  message: () ->

    if @message == "start-end-dates-reversed"
      task_id = @task_id
      task = APP.collections.Tasks.findOne task_id
      seq_id = task?.seqId
      title = task?.title?.slice 0, 80

      parts = []
      if seq_id?
        parts.push "##{seq_id}"
      if title? and title.length > 0
        parts.push title.substr(0, 80)

      prefix = parts.join(" ")
      parts = ["Start date comes after end date."]
      if prefix.length > 0
        parts.unshift prefix

      return parts.join(" - ")

    if @message == "no-date"
      return "In order to display the timeline chart, for the selected tasks, at least one task should have an end date."


    return @message

Template.grid_visualization_modal.onRendered () ->

  @autorun (c) =>
    chartAPI = @chartAPI.get()
    canvgAPI = @canvgAPI.get()

    if chartAPI and canvgAPI
      c.stop()

      if @errors?
        return

      data = new chartAPI.visualization.DataTable()
      data.addColumn('string', 'Task Name')
      data.addColumn('string', 'note')
      data.addColumn('date', 'Start Date')
      data.addColumn('date', 'End Date')


      data.addRows(_.map @chartData, (row) =>
        error = row.error
        if row.error == "start-end-dates-reversed"
          error = "Start date comes after end date and is not shown."

        bar_note = (error or '')
        if row.start_date_implied
          bar_note = '>>'
        return [row.title or "", bar_note, row.start_date, row.end_date]
      )

      header_height = 15 + 18 + 15

      options =
        # We want to show the whole chart, even if that means the modal will overflow the page
        # Rows are 41px, labels at the bottom are 50 px, title at the top will be header_height pixels
        height: 41 * @chartData.length + 50 + header_height
        colors: ["#337ab7"]
        enableInteractivity : false
        timeline:
          groupByRowLabel: false

      chart = new chartAPI.visualization.Timeline(@$(".grid-visualization-drawing")[0])


      title = ((chartData) ->
        if @path == "/"
          project = APP.collections.Projects.findOne(@project.id)

          title = project.title or ""
        else
          item = @item

          title = item?.title or ""

          if (seqId = item?.seqId)?
            title = "##{seqId}: #{title}"

        title = title.substr(0, 80)

        getDateString = ->
          date_format = JustdoHelpers.getUserPreferredDateFormat()

          if not (max_date = chartData.max_date)
            # We shouldn't get here.
            console.warn "Unknown end date"

            return ""

          # End date always come last
          end_date_string = max_date.format(date_format)

          if not (min_date = chartData.min_date)
            return "Ends #{end_date_string}"
          else
            return "#{min_date.format(date_format)} - #{end_date_string}"

        if not _.isEmpty(date_string = getDateString())
          title += " - #{date_string}"

        return title
      ).call(@data, @chartData)

      chart.draw(data, options)

      Meteor.defer () =>
        chart_svg_elem = @$(".grid-visualization-drawing svg")

        width = parseInt(chart_svg_elem.attr("width"))
        height = parseInt(chart_svg_elem.attr("height"))

        chart_svg_elem.find('g').attr("transform", "translate(0,#{header_height})")
        chart_svg_elem.find('g').first().find('text[text-anchor="end"]').attr("text-anchor", "start").attr("x", "15")

        chart_svg_elem.prepend $(
          """
          <rect
            x="0"
            y="0"
            height="#{height}"
            width="#{width}"
            fill="white"
            stroke="none"
            stroke-width="0"
            />
          <text
            text-anchor="middle"
            y="30"
            x="#{width/2}"
            font-family="Arial, sans-serif"
            font-size="18"
            font-weight="bold"
            stroke="none"
            stroke-width="0"
            fill="black"
            >#{
              JustdoHelpers.xssGuard(title)
            }</text>
          """
        )

        parent = chart_svg_elem.parent()
        outerHTML = parent.html()

        # HACK, jquery doesn't handle appending svg elements correctly
        # so we use this trick to refresh the svg element
        parent.html(outerHTML)

        canvgAPI(@$(".grid-visualization-canvas")[0], outerHTML)

        Meteor.defer () =>
          canvas = @$(".grid-visualization-canvas")[0]

          # WORKAROUND for IE
          if canvas.msToBlob?
            blob = canvas.msToBlob()
            url = URL.createObjectURL(blob)

          # Normal using toDataURL
          else
            url = canvas.toDataURL("image/png")

          @$(".grid-visualization-chart").attr("src", url)

          @$(".grid-visualization-drawing").addClass("ready")
          $('.grid-visualization-show-on-ready').addClass("ready")

Template.grid_visualization_modal.events
  "click .grid-visualization-overlay": (e, tmpl) ->
    if e.currentTarget == e.target
      @onClose()

  "click .grid-visualization-error": (e, tmpl) ->
    if @task_id
      # XXX how to select the task by id
      console.warn("Select task:" + @task_id)
