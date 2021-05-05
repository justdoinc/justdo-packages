raw_data_moment_format = "YYYY-MM-DD"

_.extend JustdoHelpers,
  display_name_required_fields:
    "profile.first_name": 1
    "profile.last_name": 1

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

    return name

  currentUserMainEmail: ->
    return JustdoHelpers.getUserMainEmail(Meteor.user({fields: {emails: 1}}))

  getUserMainEmail: (user_obj) ->
    return user_obj?.emails?[0]?.address

  _getUsersDocsByIds: (users_ids, find_options, options) ->
      if (limit = find_options?.limit)?
        find_options = _.extend(find_options)

        find_options.limit = undefined # faster than delete

      return_first = false
      if not _.isArray(users_ids)
        return_first = true

        if options.ret_type == "object"
          throw new Error "When a single user id is provided for the users_ids args the ret_type can't be 'object'"
        
        users_ids = [users_ids]

      if options.ret_type == "array"
        ret = []
      else if options.ret_type == "object"
        ret = {}
      else
        throw new Error "Unknown ret_type #{ret_type}"

      missing_ids = []

      found_ids = 0
      consecutive_missing_ids_count = 0
      break_if_consecutive_missing_ids_count = limit
      # A missing id can mean two things:
      #
      # 1) DDP didn't provide the user doc yet
      # 2) Unknown id.
      #
      # by findOne()ing the users ids requested we creating a demand for them.
      #
      # See: initEncounteredUsersIdsTracker/initEncounteredUsersIdsPublicBasicUsersInfoFetcher
      #
      # That demand will request those ids from the server.
      #
      # In early stages, we might know only the Meteor.userId().
      #
      # Hence if a 10k users_ids array will receive, that will translate to 10k
      # users requests.
      # 
      # If we need only a very few users (e.g. if there's a limit) we don't want
      # to request the server for 10k users, but only for few.
      #
      # Since an unkown user_id should be a quite rare case, we assume that
      # when looping over the users_ids if a row of consecutive missing ids encountered
      # it is likely that these uesrs were never requested from the server before. Hence
      # we break the loop to begin the wait to the ddp to retreive them.

      for user_id in users_ids
        if (user_doc = Meteor.users.findOne(user_id, find_options))?
          consecutive_missing_ids_count = 0
          found_ids += 1
          
          if options.ret_type == "array"
            ret.push user_doc
          else
            ret[user_id] = user_doc
        else
          consecutive_missing_ids_count += 1
          missing_ids.push user_id

          if break_if_consecutive_missing_ids_count?
            if consecutive_missing_ids_count >= break_if_consecutive_missing_ids_count
              break

        if found_ids == limit
          break

      if return_first
        ret = ret[0]

      return [ret, missing_ids]

  getUsersDocsByIds: (users_ids, find_options, options) ->
    # Reactive resource

    # IMPORTANT: 1. Ids order won't be maintained in returned array
    #            2. If a user isn't known to the client, the returned array won't contain info about this

    # user can be either a single user id provided as string or an array 

    default_options =
      user_fields_reactivity: false # The default is non-reactive !!!
      missing_users_ractivity: true
      ret_type: "array" # can be "array" or "object"

    options = _.extend default_options, options

    if options.user_fields_reactivity
      return @_getUsersDocsByIds(users_ids, find_options, options)[0]
    else
      [ret, missing_ids] = Tracker.nonreactive =>
        return @_getUsersDocsByIds(users_ids, find_options, options)

      # Setup reactivity for case the missing_ids will show up
      if missing_ids.length > 0 and options.missing_users_ractivity
        @_getUsersDocsByIds(missing_ids, find_options, options)

      return ret

  getUserPreferredDateFormat: ->
    # Reactive resource!
    if (preferred_date_format = Meteor.users.findOne(Meteor.userId(), {fields: {'profile.date_format': 1}})?.profile?.date_format)?
      return preferred_date_format

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
      filter_regexp = new RegExp("\\b#{JustdoHelpers.escapeRegExp(niddle)}", "i")

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
  
  filterUsersIdsArray: (user_ids, niddle, options) ->
    user_docs = @getUsersDocsByIds user_ids,
      fields:
        _id: 1
        profile: 1
        emails: 1

    return @filterUsersDocsArray user_docs, niddle, options

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

  sortUsersDocsArrayByDisplayName: (users_docs) ->
    return _.sortBy users_docs, (user_doc) -> JustdoHelpers.displayName(user_doc).toLowerCase()

  userHasProfilePic: (user_doc) ->
    identifying_prefix = "http" # If profile pic beings with this string, we assume the user has a profile pic

    if not (profile_pic = user_doc.profile?.profile_pic)?
      return false

    return profile_pic.substr(0, identifying_prefix.length) == identifying_prefix

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
      console.error "This method isn't supported in the server environment yet."

      # If you want to add support, base the user fetch on APP.accounts.findOnePublicBasicUserInfo

      return false

    if _.isString user
      user_doc = Meteor.users.findOne(user, {fields: {all_emails_verified: 1}})
    else if _.isObject user
      user_doc = user
    else
      user_doc = @

    return user_doc.all_emails_verified or false
