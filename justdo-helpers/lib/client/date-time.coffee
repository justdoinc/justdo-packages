currentDateReactiveCrv = null
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

installCurrentDateReactiveCrv = _.once ->
  # We install this crv once per application, when any component need
  # it, for all the components that might need it.
  #
  # Note, we don't remove it once it is not needed anymore.
  currentDateReactiveCrv = JustdoHelpers.newComputedReactiveVar null, ->
    return new Date()
  , recomp_interval: 60 * 1000 # once a minute, check whether a recomp is needed

  return

unicode_date_format = "YYYY-MM-DD"
_.extend JustdoHelpers,
  getRelativeDate: (days_offset=0) ->
    # Relative to today + days_offset

    return moment().add(days_offset, "days").toDate()

  getCurrentDateReactive: ->
    if not currentDateReactiveCrv?
      installCurrentDateReactiveCrv()

    return currentDateReactiveCrv.getSync()

  getRelativeUnicodeDate: (days_offset=0) ->
    # Relative to today + days_offset

    return moment().add(days_offset, "days").format(unicode_date_format)

  getCurrentUnicodeDateReactive: ->
    if not currentUnicodeDateReactiveCrv?
      installCurrentUnicodeDateReactiveCrv()

    return currentUnicodeDateReactiveCrv.getSync()

  getAllowedDateFormatsWithExample: (options) ->
    fallback_date_format = ["YYYY-MM-DD"]

    if not (allowed_date_formats = JustdoHelpers.getCollectionSchemaForField(Meteor.users, "profile.date_format")?.allowedValues)?
      allowed_date_formats = fallback_date_format

    if options?.custom_date_formats?
      allowed_date_formats = allowed_date_formats.concat options.custom_date_formats

    current_year = new Date().getFullYear()
    allowed_date_formats = _.map allowed_date_formats, (format) ->
      if format is "Others"
        return {text: format, value: format}

      demo_date = moment(new Date(current_year, 2, 14)).format(format) # JS months count from 0 to 11, so it's 14th March, (current year)
      return {text: "#{demo_date} (#{format})", value: format}

    return allowed_date_formats
