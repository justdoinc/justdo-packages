raw_data_moment_format = "YYYY-MM-DD"

_.extend JustdoHelpers,
  display_name_required_fields:
    "_id": 1
    "profile.first_name": 1
    "profile.last_name": 1

  avatar_required_fields:
    "_id": 1
    "emails": 1
    "profile.avatar_bg": 1
    "profile.avatar_fg": 1
    "profile.first_name": 1
    "profile.last_name": 1
    "profile.profile_pic": 1
    "is_proxy": 1

  displayName: (user) ->
    # user:
    #
    # If string: assume user_id and use it to fetch user info that we assume is published
    # If object: assume user_doc
    # otherwise assume @ is user context
    #
    # Will return empty string if can't provide display name.
    #
    # assume that user docs stores first_name and last_name under profile

    if _.isString user
      user_id = user
      user = Meteor.users.findOne user_id, {fields: JustdoHelpers.display_name_required_fields}

      if not user?
        return ""

    if not _.isObject user
      # If by this point we don't have a user object, try to set @ as the user object
      user = @

    first_name = user.profile?.first_name or ""
    last_name = user.profile?.last_name or ""

    name = ""

    if not _.isEmpty first_name
      name += first_name + " "

    if not _.isEmpty last_name
      name += last_name

    name = name.trim()

    if _.isEmpty name
      if user.emails?
        name = user.emails[0].address

    return name

  currentUserMainEmail: ->
    return JustdoHelpers.getUserMainEmail(Meteor.user({fields: {emails: 1}}))

  getUserMainEmail: (user_obj) ->
    return user_obj?.emails?[0]?.address

  getUserPreferredDateFormat: (fallback_format) ->
    # If you provide a fallback_format, it will be used if the user has no preferred date format
    # If fallback_format is undefined/null, we will use the default_date_format from the schema

    # Reactive resource!
    if (preferred_date_format = Meteor.user({fields: {'profile.date_format': 1}})?.profile?.date_format)?
      return preferred_date_format

    if fallback_format?
      if Meteor.isClient and APP.justdo_i18n?
        APP.justdo_i18n.getLang() # For reactivity (following a change of a languge, justdo-i18n updates moment according to the new language, so for the following line to be reactive, we need to call APP.justdo_i18n.getLang())
      
      return fallback_format

    if (default_date_format = JustdoHelpers.getCollectionSchemaForField(Meteor.users, "profile.date_format").defaultValue)?
      return default_date_format

    # Fallback to the raw_data_moment_format
    return raw_data_moment_format

  getUserPreferredDateFormatNonReactive: JustdoHelpers.generateSameTickCachedProcedure("getUserPreferredDateFormatNonReactive", (args...) -> JustdoHelpers.getUserPreferredDateFormat(...args))

  getUserPreferredUseAmPm: ->
    # Reactive resource!
    if (preferred_use_am_pm = Meteor.user({fields: {"profile.use_am_pm": 1}})?.profile?.use_am_pm)?
      return preferred_use_am_pm

    if (default_use_am_pm = JustdoHelpers.getCollectionSchemaForField(Meteor.users, "profile.use_am_pm").defaultValue)?
      return default_use_am_pm

    # Fallback to null <=> system locale
    return null

  getUserPreferredDataFormatInJqueryUiFormat: ->
    preferred_format = JustdoHelpers.getUserPreferredDateFormat()

    jquery_ui_format = preferred_format
      .replace("MMM", "M")
      .replace("MM", "mm")
      .replace("YYYY", "yy")
      .replace("DD", "dd")

    return jquery_ui_format

  normalizeUnicodeDateStringAndFormatToUserPreference: (unicode_date_string, user_preferred_date_format) ->
    if not unicode_date_string? or unicode_date_string == ""
      return ""

    # We allow passing the user_preferred_date_format so for the slick grid formatter,
    # that we need to be highly optimized, we will be able to cache it
    # in the column level
    if not user_preferred_date_format?
      user_preferred_date_format = JustdoHelpers.getUserPreferredDateFormat()

    return moment(unicode_date_string, raw_data_moment_format).format(user_preferred_date_format)
  
  # This function is a locale aware version of normalizeUnicodeDateStringAndFormatToUserPreference.
  # e.g. when unicode_date_string is "٢٠٢٤-٠٨-٠١" (Arabic representation of "2024-08-01"),
  # normalizeUnicodeDateStringAndFormatToUserPreference returns "٢٠٢٤-٠٨-٠١"
  # but normalizeLocalizedUnicodeDateStringAndFormatToUserPreference returns "2024-08-01"
  # As a general rule of thumb, normalizeUnicodeDateStringAndFormatToUserPreference should be used for display purpose,
  # while normalizeLocalizedUnicodeDateStringAndFormatToUserPreference should be used for input processing purpose (e.g. search, set date in grid date editor, etc).
  normalizeLocalizedUnicodeDateStringAndFormatToUserPreference: (unicode_date_string, user_preferred_date_format) ->
    if not unicode_date_string? or unicode_date_string == ""
      return ""

    # We allow passing the user_preferred_date_format so for the slick grid formatter,
    # that we need to be highly optimized, we will be able to cache it
    # in the column level
    if not user_preferred_date_format?
      user_preferred_date_format = JustdoHelpers.getUserPreferredDateFormat()

    return moment(unicode_date_string, raw_data_moment_format).locale(JustdoI18n.default_lang).format(user_preferred_date_format)


  getTimeStringInUserPreferenceFormat: (show_seconds=true) ->
    # Reactive resource!
    if not (user_preferred_use_am_pm_format = JustdoHelpers.getUserPreferredUseAmPm.call(@))?
      user_preferred_use_am_pm_format = false # Use 24 hours clock by default

    if user_preferred_use_am_pm_format is true
      if show_seconds
        return "h:mm:ss A"
      else
        return "h:mm A"

    if user_preferred_use_am_pm_format is false
      if show_seconds
        return "H:mm:ss"
      else
        return "H:mm"

    # Fallback to system default if null/undefined or any other value
    if show_seconds
      return "LTS"
    else
      return "LT"

  getTimeStringInUserPreferenceFormatNonReactive: JustdoHelpers.generateSameTickCachedProcedure("getTimeStringInUserPreferenceFormatNonReactive", (args...) -> JustdoHelpers.getTimeStringInUserPreferenceFormat(...args))

  getDateTimeStringInUserPreferenceFormat: (date, show_seconds, non_reactive=false) ->
    if non_reactive
      user_preferred_date_format = JustdoHelpers.getUserPreferredDateFormatNonReactive.call(@)
      time_string_in_user_preference_format = JustdoHelpers.getTimeStringInUserPreferenceFormatNonReactive.call(@, show_seconds)
    else
      user_preferred_date_format = JustdoHelpers.getUserPreferredDateFormat.call(@)
      time_string_in_user_preference_format = JustdoHelpers.getTimeStringInUserPreferenceFormat.call(@, show_seconds)

    if not date? or date == ""
      return ""

    format = "#{user_preferred_date_format} #{time_string_in_user_preference_format}"

    formatter_fn_same_tick_cache_key = "getDateTimeStringInUserPreferenceFormat:#{show_seconds}"
    if not (dateFormatterFn = JustdoHelpers.sameTickCacheGet(formatter_fn_same_tick_cache_key))?
      dateFormatterFn = JustdoHelpers.sameTickCacheSet(formatter_fn_same_tick_cache_key, JustdoDateFns.getFormatFn(format))

    return dateFormatterFn(date)

  filterUsersDocsArray: (users_docs, niddle, options) ->
    options = _.extend {sort: false}, options
    if niddle?
      # The "(^|\\W|_)" part of the following regex is used to replace "\b" (word boundry), 
      # since we found that "\b" it doesn't work well with unicode characters.
      # (^|\\W|_) is used to match the start of the string, a non-word character, or an underscore (since non-word character excludes undercore),
      # which is the closest we can get to a word boundry.
      filter_regexp = new RegExp("(^|\\W|_)#{JustdoHelpers.escapeRegExp(niddle)}", "i")

      exist_users = {}
      users_docs = _.filter users_docs, (doc) ->
        key = if _.isString(doc) then doc else doc._id
        if exist_users[key]
          return false

        exist_users[key] = true

        display_name = JustdoHelpers.displayName(doc)

        email = JustdoHelpers.getUserMainEmail(doc)

        if filter_regexp.test(display_name) or filter_regexp.test(email)
          return true

        return false

    if options.sort
      users_docs = @sortUsersDocsArray users_docs

    return users_docs

  sortUsersDocsArray: (users_docs, comp) ->
    if not comp?
      comp = (user_doc) -> JustdoHelpers.displayName(user_doc).toLowerCase()

    return _.sortBy users_docs, comp

  friendlyDateFormat: (date) ->
    moment_date = moment(date)

    time_string_in_user_preference_format =
      JustdoHelpers.getTimeStringInUserPreferenceFormat(false)

    if moment_date.isSame(Date.now(), "day")
      # Show hour only
      return moment_date.format(time_string_in_user_preference_format)
    else if moment().diff(date, 'days') <= 5 # Last 5 days
      # Show day name and hour
      return moment_date.format("dddd #{time_string_in_user_preference_format}")
    else if moment_date.isSame(Date.now(), "year")
      # Show date without year + hour
      return moment_date.format("MMMM Do, #{time_string_in_user_preference_format}")
    else
      # Show date with year + hour
      return moment_date.format("MMMM Do YYYY, #{time_string_in_user_preference_format}")

    return
  
  friendlyTimeFormat: (date, show_seconds=true) ->
    moment_date = moment(date)

    time_string_in_user_preference_format =
      JustdoHelpers.getTimeStringInUserPreferenceFormat(show_seconds)
    
    return moment_date.format(time_string_in_user_preference_format)

  sortUsersDocsArrayByDisplayName: (users_docs, options) ->
    if options?.logged_in_user_first is true
      user_id = Tracker.nonreactive -> Meteor.userId()

      return _.sortBy users_docs, (user_doc) ->
        if user_id is user_doc._id
          return "" # "" to ensure it is smaller than all the rest

        display_name = JustdoHelpers.displayName(user_doc).toLowerCase()

        if display_name == ""
          # To ensure no conflict with the "" we returned for the logged in user.
          return " "

        return display_name
    else
      return _.sortBy users_docs, (user_doc) -> JustdoHelpers.displayName(user_doc).toLowerCase()

  userHasProfilePic: (user_doc) ->
    # This function will return false for users that has the initials avatar

    # If profile pic beings with this string, we assume the user has a profile pic
    #   "http": Regular url
    #   "/": The path to profile pic uploaded to justdo-files
    identifying_prefixes = ["http", "/"]

    if not (profile_pic = user_doc.profile?.profile_pic)?
      return false

    for identifying_prefix in identifying_prefixes
      if profile_pic.substr(0, identifying_prefix.length) == identifying_prefix
        return true

    return false

  isUserEmailsVerified: (user) ->
    # user:
    #
    # If string: assume user_id and use it to fetch user info that we assume is published
    # If object: assume user_doc
    # otherwise assume @ is user context
    #
    # Will return false string if can't tell whether user is verified.
    #
    # assume that user docs stores the 'all_emails_verified' property

    if Meteor.isServer
      if _.isString user
        user_doc = APP.accounts.findOnePublicBasicUserInfo user
      else
        user_doc = APP.accounts._publicBasicUserInfoCursorDataOutputTransformer user
    else
      if _.isString user
        user_doc = Meteor.users.findOne(user, {fields: {all_emails_verified: 1, is_proxy: 1}})
      else if _.isObject user
        user_doc = user
      else
        user_doc = @

    # Don't show email unverified warning for proxy users
    if user_doc.is_proxy
      return true

    return user_doc.all_emails_verified or false

  getUserByEmail: (email, options) ->
    if (Meteor.isServer)
      return Accounts.findUserByEmail(email, options)
    else
      email_addr_regex = new RegExp("^#{JustdoHelpers.escapeRegExp(email)}$", "i")
      return Meteor.users.findOne({
        "emails.address": email_addr_regex
      }, options)
