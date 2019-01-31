currentUnicodeDateReactiveCrv = null
installCurrentUnicodeDateReactiveCrv = _.once ->
  # We install this crv once per application, when any component need
  # it, for all the components that might need it.
  #
  # Note, we don't remove it once it is not needed anymore.
  currentUnicodeDateReactiveCrv = JustdoHelpers.newComputedReactiveVar null, ->
    return JustdoHelpers.getRelativeUnicodeDate(0)
  , recomp_interval: 60 * 1000 # once a minute, check whether a recomp is needed

  return

unicode_date_format = "YYYY-MM-DD"
_.extend JustdoHelpers,
  getRelativeUnicodeDate: (days_offset=0) ->
    # Relative to today + days_offset

    return moment().add(days_offset, "days").format(unicode_date_format)

  getCurrentUnicodeDateReactive: ->
    if not currentUnicodeDateReactiveCrv?
      installCurrentUnicodeDateReactiveCrv()

    return currentUnicodeDateReactiveCrv.getSync()
