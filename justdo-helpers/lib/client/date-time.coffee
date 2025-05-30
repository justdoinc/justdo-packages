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
        return {text: TAPi18n.__("others"), value: format}

      demo_date = moment(new Date(current_year, 2, 14)).format(format) # JS months count from 0 to 11, so it's 14th March, (current year)
      return {text: "#{demo_date} (#{format})", value: format}

    return allowed_date_formats
  
  moFromNow: (...args) ->
    # Taken from https://github.com/lb-/moment-helpers/blob/master/client.js
    
    locale = APP.justdo_i18n.getLang() # For the reactivity

    kw = args.pop()
    date = args[0] or kw.hash.d
    withoutSuffix = args[1] or kw.hash.withoutSuffix
    # if the withoutSuffix is truthy convert it to true, or falsy = false
    if withoutSuffix
      withoutSuffix = true
    else
      withoutSuffix = false
    # work with what is given to get a moment object
    moDate = moment date
    # if we did end up with a valid object above, send the result
    if moDate
      return moDate.fromNow withoutSuffix
    # fail silently if the dates were not processed to a moment
    return

if (templating = Package.templating)?
  {Template} = templating
  Template.registerHelper "moFromNow", (...args) -> JustdoHelpers.moFromNow ...args
