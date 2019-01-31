_.extend JustdoHelpers,
  timeProfile: (op) ->
    # returns the time op() took to complete (ms)

    begin_time = new Date()

    op()

    return (new Date()) - begin_time

  timeProfileAverage: (times, op) ->
    aggr = 0

    for i in [0..times]
      aggr += @timeProfile(op)

    return aggr / times

  timeProfileAsync: (asyncOp, completedCb) ->
    # Usage:
    #
    # In order to time the run of asyncFunction
    # do:
    #
    # JustdoHelpers.timeProfileAsync (doneCb) ->
    #   asyncFunction(p1, p2, p3, doneCb)
    # , (run_time_ms) -> console.log(run_time_ms)

    begin_time = new Date()

    doneCb = ->
      completedCb((new Date()) - begin_time)

    asyncOp(doneCb)

  timeProfileAsyncAverage: (options, asyncOp, completedCb) ->
    # Usage:
    #
    # In order to time the average run of asyncFunction
    # 1000 times, do:
    #
    # JustdoHelpers.timeProfileAverage {times: 1000, limit: 1}, (doneCb) ->
    #   asyncFunction(p1, p2, p3, doneCb)
    # , (avg_run_time_ms) -> console.log(avg_run_time_ms)

    default_options =
      times: 1000 # Times to run
      limit: 1 # The maximum number of async operations at a time.

    options = _.extend {}, default_options, options

    aggr = 0
    async.timesLimit options.times, options.limit, (n, next) ->
      console.log n
      JustdoHelpers.timeProfileAsync (doneCb) ->
        asyncOp(doneCb)
      , (run_time) ->
        aggr += run_time
        next()
    , (err) ->
      if err?
        console.error("timeProfileAverage run failed", err)
      completedCb(aggr / options.times)