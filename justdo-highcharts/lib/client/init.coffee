JustdoHighcharts = ->
  @_load_begun = false
  @_load_completed = false

  @_ready_deferred = new $.Deferred()

  @_highchart_loaded_rv = new ReactiveVar(false)

  return @

_.extend JustdoHighcharts.prototype,
  _load_begun: false
  _load_completed: false

  _ready_deferred: null

  _highchart_loaded_rv: null

  _markAsLoaded: ->
    if @_load_completed
      return # nothing to do

    @_load_completed = true

    @_highchart_loaded_rv.set(true)

    @_ready_deferred.resolve()

    return

  requireHighcharts: (cb) ->
    if _.isFunction cb
      @_ready_deferred.done(cb)

    if @_load_begun
      return

    @_load_begun = true

    scripts_count = 7
    reportSciptLoadCompleted = =>
      scripts_count -= 1

      if scripts_count == 0
        @_markAsLoaded()

      return

    JustdoHelpers.getCachedScript("https://code.highcharts.com/highcharts.js").done ->
      reportSciptLoadCompleted()

      JustdoHelpers.getCachedScript("https://code.highcharts.com/gantt/modules/gantt.js").done ->
        reportSciptLoadCompleted()

        JustdoHelpers.getCachedScript("https://code.highcharts.com/modules/exporting.js").done ->
          reportSciptLoadCompleted()

          JustdoHelpers.getCachedScript("https://code.highcharts.com/modules/export-data.js").done ->
            reportSciptLoadCompleted()

            JustdoHelpers.getCachedScript("https://code.highcharts.com/gantt/modules/draggable-points.js").done ->
              reportSciptLoadCompleted()

              JustdoHelpers.getCachedScript("https://blacklabel.github.io/custom_events/js/customEvents.js").done ->
                reportSciptLoadCompleted()
  
                JustdoHelpers.getCachedScript("https://code.highcharts.com/highcharts-3d.js").done ->
                  reportSciptLoadCompleted()
                  
                  return
                return
              return
            return
          return
        return
      return
    return

  isHighchartLoaded: -> @_highchart_loaded_rv.get()
