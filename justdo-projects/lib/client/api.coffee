_.extend Projects.prototype,
  userRequirePostRegistrationInit: ->
    if (user = Meteor.user({fields: {"justdo_projects.post_reg_init": 1}}))? and (post_reg_init = user.justdo_projects?.post_reg_init)? and post_reg_init == false
      return true

    return false

  getProjectDoc: (project_id, options) ->
    @projects_collection.findOne(project_id, options)

  getProjectMembersIds: (project_id, options) ->
    if not options?
      options = {}

    options = _.extend {
      include_removed_members: false
      if_justdo_guest_include_ancestors_members_of_items: [] # If is a JustDo Guest, and an array of items is
                                                             # provided here, we will include these items' tasks' users,
                                                             # and the users of all of these tasks ancestors in
                                                             # the response.
                                                             #
                                                             # We do allow it to be a String, in which case we'll convert
                                                             # to an array.
    }, options

    if not (members = @getProjectDoc(project_id, {fields: {members: 1}})?.members)?
      #
      # The user is a guest of this JustDo, the following happens only for guests
      #
      members_ids = new Set()

      members_ids.add(Meteor.userId())

      if _.isString(options.if_justdo_guest_include_ancestors_members_of_items)
        options.if_justdo_guest_include_ancestors_members_of_items = [options.if_justdo_guest_include_ancestors_members_of_items]

      check options.if_justdo_guest_include_ancestors_members_of_items, [String]

      # If we can't determine a grid_control - there's not much we can do.
      if (grid_control = APP.modules.project_page.gridControl())?
        grid_data = grid_control._grid_data

        
        for item_id in options.if_justdo_guest_include_ancestors_members_of_items
          if (paths = grid_data.getAllCollectionItemIdPaths(item_id))?
            for path in paths
              for path_item_id in GridData.helpers.getPathArray(path)
                if (path_item = APP.collections.TasksAugmentedFields.findOne(path_item_id, {fields: {_id: 1, users: 1}}))?
                  for user_id in path_item.users
                    members_ids.add user_id

        members = []
        members_ids.forEach (user_id) ->
          members.push {user_id: user_id, is_admin: false, is_guest: true}

    members_ids = @getMembersIdsFromProjectDoc({members})

    if options.include_removed_members
      members_ids = members_ids.concat(@getRemovedMembersIdsFromProjectDoc(@getProjectDoc(project_id, {fields: {removed_members: 1}})))

    return members_ids

  initEncounteredUsersIdsTracker: ->
    self = @

    @_encountered_users = new Set()
    @_encountered_users_dep = new Tracker.Dependency()

    Meteor.users.before.findOne (userId, selector, options) -> self.addEncounteredUsersIdsFromSelector(selector)
    Meteor.users.before.find (userId, selector, options) -> self.addEncounteredUsersIdsFromSelector(selector)

    return

  addEncounteredUsersIdsFromSelector: (selector) ->
    if not selector?
      return

    pre_size = @_encountered_users.size

    if (user_id = selector._id)?
      if _.isString(user_id)
        @_encountered_users.add(user_id)

      if _.isObject(user_id)
        if (users_ids = user_id.$in)?
          for user_id in users_ids
            @_encountered_users.add(user_id)

    if pre_size < @_encountered_users.size
      @_encountered_users_dep.changed()

    return

  addRequiredUsers: (users_array) ->
    if _.isString(users_array)
      users_array = [users_array]

    @addEncounteredUsersIdsFromSelector({_id: {$in: users_array}})

    return 

  initEncounteredUsersIdsPublicBasicUsersInfoFetcher: ->
    if @_encountered_users_fetcher_comp?
      return

    @_encountered_users_fetcher_comp = Tracker.autorun (c) =>
      Meteor.subscribe "publicBasicUsersInfo", Array.from(@_encountered_users)

      @_encountered_users_dep.depend()

      return 
    
    return

  ensureUsersPublicBasicUsersInfoLoaded: (users_array, cb) ->
    # cb is called only once attempt to retreive users_array information is completed
    
    if _.isString(users_array)
      users_array = [users_array]

    @addRequiredUsers(users_array)

    temporary_public_basic_user_info_subscription = Meteor.subscribe "publicBasicUsersInfo", Array.from(@_encountered_users)
    # temporary because the _encountered_users_fetcher_comp will take care of maintaing users_array
    # users in the publicBasicUsersInfo publication merge box following unsubscription

    JustdoHelpers.awaitValueFromReactiveResource
      reactiveResource: => temporary_public_basic_user_info_subscription.ready()

      evaluator: (val) -> val is true

      cb: ->
        temporary_public_basic_user_info_subscription.stop()

        JustdoHelpers.callCb(cb)

        return

    return

  sortCustomFields: (sort_criteria) ->
    check sort_criteria, String
    if _.isEmpty sort_criteria
      throw @_error "invalid-argument", "Sort criteria cannot be empty"

    current_custom_fields = JD.activeJustdo({custom_fields: 1})?.custom_fields

    sorted_custom_fields = JustdoHelpers.localeAwareSortCaseInsensitive current_custom_fields, (val) -> val[sort_criteria]
    @projects_collection.update JD.activeJustdoId(), {$set: {custom_fields: sorted_custom_fields}}

    return
  
  createNewJustdoWithSameSettings: ->
    APP.justdo_grid_views.subscribeGridViews({type: "justdo", justdo_id: JD.activeJustdoId()}, (err) ->
      if err?
        console.error(err)
        return
      
      grid_views = APP.collections.GridViews.find
        "hierarchy.justdo_id": JD.activeJustdoId()
      ,
        fields:
          view: 1
          title: 1
          shared: 1
      .fetch()
      
      cur_proj = APP.modules.project_page.curProj()
      APP.projects.createNewProject({
        conf: cur_proj.getProjectConfiguration()
        custom_fields: cur_proj.getProjectCustomFields()
        grid_views: grid_views
      }, (err, project_id) ->
        if err?
          JustdoSnackbar.show
            text: err.reason
          return
        Router.go "project", {_id: project_id})
    )
    return
