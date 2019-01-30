charts = new ReactiveVar(false)

_.extend JustdoGridVisualization.prototype,
  onGoogleChartsLoad: (cb) ->
    Tracker.nonreactive =>
      if not charts.get()
        $.getScript "https://www.gstatic.com/charts/loader.js", () =>
          google.charts.load('current', {'packages':['timeline']})
          google.charts.setOnLoadCallback () =>
            charts.set(google)

        charts.set("loading")

    Tracker.autorun (c) =>
      if _.isObject(charts.get())
        c.stop()
        cb(charts.get())
