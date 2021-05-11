_.extend JustdoHelpers,
  _getUsersDocsByIds: (users_ids, find_options, options) ->
    if (limit = find_options?.limit)?
      find_options = _.extend(find_options)

      find_options.limit = undefined # faster than delete

    break_if_consecutive_missing_ids_count = limit

    return_first = false
    if _.isString(users_ids)
      return_first = true

      if options.ret_type == "object"
        throw new Error "When a single user id is provided for the users_ids args the ret_type can't be 'object'"
      
      users_ids = [users_ids]

    if not options.user_fields_reactivity and find_options?.fields?
      throw new Error "If the options.user_fields_reactivity is set to false the find_options.fields can't be set, we return the entire doc using JustdoHelpers.objectDeepInherit since it is much faster than returning parts of the user object"

    if options.user_fields_reactivity and options?.get_docs_by_reference
      throw new Error "If the options.user_fields_reactivity is set to true the options.get_docs_by_reference can't be set to true"

    if not options.missing_users_ractivity and options.user_fields_reactivity
      throw new Error "If the options.missing_users_ractivity is set to false the options.user_fields_reactivity can't be true"

    if not options.user_fields_reactivity
      [ret, missing_ids] = JustdoHelpers.nonReactiveFullDocFindById(Meteor.users, users_ids, {limit: limit, ret_type: options.ret_type, break_if_consecutive_missing_ids_count: break_if_consecutive_missing_ids_count, get_docs_by_reference: options.get_docs_by_reference})

      if options.missing_users_ractivity and not _.isEmpty(missing_ids)
        APP.projects.addRequiredUsers(missing_ids)

        JustdoHelpers.invalidateOnceIdsBecomeExist(Meteor.users, missing_ids)
    else
      if options.ret_type == "array"
        ret = []
      else if options.ret_type == "object"
        ret = {}
      else
        throw new Error "Unknown ret_type #{ret_type}"

      missing_ids = []

      found_ids = 0
      consecutive_missing_ids_count = 0
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
    # Might be a reactive resource depending on options

    # IMPORTANT: 1. Ids order might not be maintained in returned array
    #            2. If a user isn't known to the client, the returned array won't contain info about this

    # user can be either a single user id provided as string or an array 

    default_options =
      user_fields_reactivity: false # The default is non-reactive! Changing to reactive will harm performance significantly
      missing_users_ractivity: true
      ret_type: "array" # can be "array" or "object"
      get_docs_by_reference: false

    options = _.extend default_options, options

    return @_getUsersDocsByIds(users_ids, find_options, options)[0]

  getUserDocById: (user_id, options) ->
    return JustdoHelpers.getUsersDocsByIds(user_id, {}, options)

  filterUsersIdsArray: (user_ids, niddle, options) ->
    user_docs = @getUsersDocsByIds user_ids,
      fields:
        _id: 1
        profile: 1
        emails: 1

    return @filterUsersDocsArray user_docs, niddle, options
