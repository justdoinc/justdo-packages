_.extend PACK.modules,
  due_lists:
    initBoth: -> return

    _isValidUnicodeDate: (str) ->
      return moment(str, "YYYY-MM-DD").isValid()

    _getDueListsStates: ->
      if not @_getDueListsStates_cache?
        if not (grid_values_defs = @items_collection?.simpleSchema?()?._schema?.state.grid_values?())?
          throw _.error("cant-find-states-definitions-in-schema")

        @_getDueListsStates_cache = _.compact(_.map(grid_values_defs, (state_def, key) ->
          if (state_def.due_list_state == true) 
            return key
        ))

      return @_getDueListsStates_cache

    #
    # Common
    #
    default_common_conf: {projects: null, owners: null}
    _validateCleanAndStandardizeCommonConf: (conf, requesting_user_id=null) ->
      # These are the configurations validations, cleanups and
      # standatization common to all due lists queries generators.

      # Read README for full deatils about common configurations

      # Clean, validate and prepare conf
      if not conf?
        conf = {}

      conf = _.extend {}, @default_common_conf, conf

      # Make sure we have a requesting_user_id
      if Meteor.isClient and not requesting_user_id?
        # On the client side, safe to take user_id from
        # Meteor.userId() by default
        requesting_user_id = Meteor.userId()
      # For security, on the server we require requesting_user_id
      # to exist
      check requesting_user_id, String

      {projects, owners} = conf

      # projects
      #
      # Projects can be: undefined/null, string, array of strings 
      check projects, Match.Maybe(Match.OneOf(String, [String]))
      if _.isString projects
        projects = [projects]
      if _.isEmpty projects
        # Will make: null/undefined/[] -> null
        # in all these cases we want to return all projects.
        projects = null

      # owners
      #
      # Owners can be: string, array of strings 
      check owners, Match.Maybe(Match.OneOf(String, [String]))
      if not owners?
        owners = [requesting_user_id]
      else if _.isString owners
        owners = [owners]

      return {projects, owners, requesting_user_id}

    _getCommonQuery: (conf) ->
      # Returns the query common to both the prioritized and
      # the due lists queries.
      #
      # IMPORTANT! Assumes conf had been validated and cleaned by:
      # @_validateCleanAndStandardizeCommonConf()

      {projects, owners, requesting_user_id} = conf

      query =
        state:
          $in: @_getDueListsStates()

      if owners[0] != "*"
        _.extend query,
          # If first owners item is "*", it is a special case in
          # which we don't restrict owners_ids at all
          owner_id:
            $in: owners

      if Meteor.isServer
        # On the server, we must limit the query to tasks user has
        # access to.
        # On client, redundant, as tasks with no access won't exist.
        _.extend query,
          users: requesting_user_id

      if projects?
        # If exists must be array, if not exists, no need to
        # add any constraint
        _.extend query,
          project_id:
            $in: projects
      else if Meteor.isClient
        if (project_id = APP.modules?.project_page?.curProj()?.id)?
          query.project_id = project_id

      return query

    _validateCleanAndStandardizeCommonDateConf: (conf, requesting_user_id=null) ->
      # These are the configurations validations, cleanups and
      # standatization common to all due lists queries generators
      # that in addition to the common configurations has a "dates"
      # configuration.

      # drop all unrecognized confs
      conf =
        _.pick conf, "projects", "owners", "dates"

      # validate dates
      {dates} = conf

      # dates can be: string, array of strings/null/undefineds
      check dates, Match.OneOf(String, [Match.Maybe(String)])
      if not _.isArray(dates)
        # Due to the check above, dates must be a string in that case
        if not @_isValidUnicodeDate(dates)
          throw @_error "invalid-argument", "conf.dates: provided date is invalid"
      else
        dates = dates.slice() # copy to avoid changing input

        if not (dates.length in [2, 3])
          throw @_error "invalid-argument", "conf.dates: array must have only 2 or 3 dates in unicode-date format"

        for date, i in dates
          if date?
            if not @_isValidUnicodeDate(date)
              throw @_error "invalid-argument", "conf.dates: provided dates in dates range are invalid"
          else
            dates[i] = null # normalize undefined/null -> null

        if dates[0]? and dates[1]?
          # If both exist, check valid range
          if dates[0] > dates[1]
            throw @_error "invalid-argument", "conf.dates: first date in dates range can't be bigger than second"

      return _.extend @_validateCleanAndStandardizeCommonConf(conf, requesting_user_id), {dates: dates}

    #
    # Due Lists
    #
    _validateCleanAndStandardizeDueListsConf: (conf, requesting_user_id) ->
      # drop all unrecognized confs
      conf =
        _.pick conf, "projects", "owners", "dates", "include_start_date", "include_my_private_follow_ups"

      # validate include_start_date
      {include_start_date} = conf
      if not _.isBoolean(include_start_date)
        include_start_date = false

      # validate include_my_private_follow_ups
      {include_my_private_follow_ups} = conf
      if not _.isBoolean(include_my_private_follow_ups)
        include_my_private_follow_ups = false

      return _.extend @_validateCleanAndStandardizeCommonDateConf(conf, requesting_user_id), {include_start_date: include_start_date, include_my_private_follow_ups: include_my_private_follow_ups}

    getDueListQuery: (conf, requesting_user_id) ->
      # Returns a mongo query for the given due list configuration
      conf =
        @_validateCleanAndStandardizeDueListsConf(conf, requesting_user_id)

      query = @_getCommonQuery(conf)

      # the conf cleanup ensure dates exist and are either
      # string - specific date
      # Array - range
      {dates, include_start_date} = conf
      if _.isString dates
        date = dates # improve readability

        # for specific date, we don't ignore due_date
        # if follow_up exists, task belongs here if
        # its due_date or follow_up date are in date

        _.extend query,
          $or: [
            {follow_up: date}
            {due_date: date}
          ]

        if conf.include_my_private_follow_ups
          query = {
            $or: [
              query,
              {
                project_id:
                  $ne: null # To avoid cases where we get docs that received only their private fields,
                            # but not yet their normal fields
                "priv:follow_up": date
              }
            ]
          }
      else
        [begin_date, end_date, excluded_due_date] = dates

        if excluded_due_date?
          _.extend query,
            due_date:
              $ne: excluded_due_date

        if not begin_date? and not end_date?
          # At least one of follow_up/due_date has to exist
          _.extend query,
            $or: [
              {
                follow_up:
                  $ne: null
              }
              {
                due_date:
                  $ne: null
              }
            ]

          if include_start_date
            query.$or.push {
                start_date:
                  $ne: null
              }

          # Note we aren't having special consideration for conf.include_my_private_follow_ups
          # for that state.
        else
          range_selector = {}
          if begin_date?
            range_selector.$gte = begin_date

          if end_date?
            range_selector.$lte = end_date

          if not _.isEmpty range_selector
            _.extend query,
              $or: [
                {
                  # option 1, follow_up exists, ignore due date
                  follow_up: range_selector
                } 
                {
                  # option 2, follow_up doesn't exist, check due date
                  follow_up: null
                  due_date: range_selector
                }
              ]

            if include_start_date
              query.$or.push {
                  start_date: range_selector
                }

            if conf.include_my_private_follow_ups
              query = {
                $or: [
                  query,
                  {
                    project_id:
                      $ne: null # To avoid cases where we get docs that received only their private fields,
                                # but not yet their normal fields
                    "priv:follow_up": range_selector
                  }
                ]
              }

      query_options = {}

      return {cleaned_conf: conf, query: query, query_options: query_options}

    #
    # Prioritized Items
    #
    _validateCleanAndStandardizePrioritizedItemsConf: (conf, requesting_user_id) ->
      # drop all unrecognized confs
      conf =
        _.pick conf, "projects", "owners", "limit", "ignore_my_private_follow_ups"

      # validate limit
      {limit} = conf
      if not limit?
        # default
        limit = 50
      check limit, Number
      if limit <= 0 or limit > 1000
        throw @_error "invalid-argument", "conf.limit: should be between 1 - 1000"

      # validate ignore_my_private_follow_ups
      {ignore_my_private_follow_ups} = conf
      if not _.isBoolean(ignore_my_private_follow_ups)
        ignore_my_private_follow_ups = false

      return _.extend @_validateCleanAndStandardizeCommonConf(conf, requesting_user_id), {limit: limit, ignore_my_private_follow_ups: ignore_my_private_follow_ups}

    getPrioritizedItemsQuery: (conf, requesting_user_id) ->
      # Returns a mongo query for the given prioritized items configuration
      conf =
        @_validateCleanAndStandardizePrioritizedItemsConf(conf, requesting_user_id)

      query = @_getCommonQuery(conf)

      _.extend query,
        project_id:
          $ne: null # To avoid cases where we get docs that received only their private fields,
                    # but not yet their normal fields
        follow_up: null
        due_date: null

      if conf.ignore_my_private_follow_ups
        query["priv:follow_up"] = null

      query_options =
        sort: {priority: -1}
        limit: conf.limit

      return {cleaned_conf: conf, query: query, query_options: query_options}

    #
    # All In-Progress Items
    #
    getAllInProgressItemsQuery: (conf, requesting_user_id) ->
      # Returns a mongo query for all the in-progress items for the given configuration
      conf =
        @_validateCleanAndStandardizePrioritizedItemsConf(conf, requesting_user_id)

      query = @_getCommonQuery(conf)

      query.state = "in-progress"

      query_options =
        sort: {priority: -1}

      return {cleaned_conf: conf, query: query, query_options: query_options}

    #
    # Start Date Query
    #
    getStartDateQuery: (conf, requesting_user_id) ->
      # Returns a mongo query for all the in-progress items for the given configuration
      conf =
        @_validateCleanAndStandardizeCommonDateConf(conf, requesting_user_id)

      query = @_getCommonQuery(conf)

      {dates} = conf # thanks to _validateCleanAndStandardizeCommonDateConf we have strong knowledge about dates possible structures

      start_date_query = null
      if _.isString dates
        start_date_query = dates
      else if _.isArray dates
        [begin_date, end_date] = dates

        if not begin_date? and not end_date?
          # If both are null, we just query for tasks that has start_date
          start_date_query = {
            $ne: null
          }
        else
          start_date_query = {}

          if begin_date?
            start_date_query.$gte = begin_date

          if end_date?
            start_date_query.$lte = end_date

      query.start_date = start_date_query

      query_options =
        sort: {
          start_date: -1,
          priority: -1
        }

      return {cleaned_conf: conf, query: query, query_options: query_options}
