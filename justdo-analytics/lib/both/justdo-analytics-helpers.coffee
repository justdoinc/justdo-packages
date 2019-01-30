JustdoAnalytics.setupConstructorJA = (constructor_object, logs_category) ->
  constructor_object.JA = (log, cb) ->
    if not log.cat?
      log.cat = logs_category

    APP.justdo_analytics.JA(log, cb)

    return