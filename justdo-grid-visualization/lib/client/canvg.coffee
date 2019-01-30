canvg = new ReactiveVar()

_.extend JustdoGridVisualization.prototype,
  onCanvgLoad: (cb) ->
    Tracker.nonreactive =>
      if not canvg.get()
        canvg.set([])

        $.getScript "/packages/justdoinc_justdo-grid-visualization/lib/assets/canvg.min.js", () =>
          done = canvg.get()
          done.push("all-files-minified")
          canvg.set(done)

    Tracker.autorun (c) =>
      if canvg.get().length == 1
        c.stop()
        cb(window.canvg)
