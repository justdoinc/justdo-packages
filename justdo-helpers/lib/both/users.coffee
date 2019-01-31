raw_data_moment_format = "YYYY-MM-DD"

_.extend JustdoHelpers,
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
      user = Meteor.users.findOne user_id

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
    return JustdoHelpers.getUserMainEmail(Meteor.user())

  getUserMainEmail: (user_obj) ->
    return user_obj?.emails?[0]?.address

  getUsersDocsByIds: (users_ids, find_options) ->
    # Reactive resource

    # IMPORTANT: 1. Ids order won't be maintained in returned array
    #            2. If a user isn't known to the client, the returned array won't contain info about this

    # user can be either a single user id provided as string or an array 

    if not _.isArray(users_ids)
      return Meteor.users.findOne(users_ids)

    if _.isEmpty users_ids
      return []

    return Meteor.users.find({_id: {$in: users_ids}}, find_options).fetch()

  getUserPreferredDateFormat: ->
    # Reactive resource!
    if (preferred_date_format = Meteor.user()?.profile?.date_format)?
      return preferred_date_format

    if (default_date_format = JustdoHelpers.getCollectionSchemaForField(Meteor.users, "profile.date_format").defaultValue)?
      return default_date_format

    # Fallback to the raw_data_moment_format
    return raw_data_moment_format

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

  getDateTimeStringInUserPreferenceFormat: (date) ->
    user_preferred_date_format = Tracker.nonreactive => JustdoHelpers.getUserPreferredDateFormat.call(@)

    if not date? or date == ""
      return ""

    return moment(date).format("#{user_preferred_date_format} LTS")

  filterUsersDocsArray: (users_docs, niddle) ->
    if not niddle?
      return users_docs

    filter_regexp = new RegExp("#{JustdoHelpers.escapeRegExp(niddle)}", "i")

    results = _.filter users_docs, (doc) ->
      display_name = JustdoHelpers.displayName(doc)

      email = JustdoHelpers.getUserMainEmail(doc)

      if filter_regexp.test(display_name) or filter_regexp.test(email)
        return true

      return false

    return results

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
      user_doc = Meteor.users.findOne(user)
    else if _.isObject user
      user_doc = user
    else
      user_doc = @

    return user_doc.all_emails_verified or false
