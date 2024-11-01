_.extend JustdoSiteAdmins.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    @_setupMethods()

    return

  setUsersAsSiteAdmins: (users_ids, performing_user_id) ->
    # If performing_user_id is null we assume secured source

    if _.isString users_ids
      users_ids = [users_ids]

    check users_ids, [String]

    if performing_user_id?
      @requireUserIsSiteAdmin(performing_user_id)

    if _.isEmpty(users_ids)
      return

    users = Meteor.users.find({_id: {$in: users_ids}}, {fields: {deactivated: 1, is_proxy: 1}}).fetch()
    for user in users
      if user.deactivated
        throw @_error "cannot-promote-deactivated-user-to-site-admin", "Cannot promote deactivated user to site admin"
      if user.is_proxy
        throw @_error "cannot-promote-proxy-user-to-site-admin", "Cannot promote proxy user to site admin"

    if (Meteor.users.find({_id: {$in: users_ids}, deactivated: true}, {fields: {_id: 1}}).count() > 0)
      throw @_error "cannot-promote-deactivated-user-to-site-admin", "Cannot promote deactivated user to site admin"

    added_by = if not performing_user_id? then "secure-source" else performing_user_id

    query =
      _id: $in: users_ids
      "site_admin.is_site_admin": $ne: true

    update =
      $set:
        site_admin:
          is_site_admin: true
          added_by: added_by
          added_at: new Date()

    Meteor.users.update(query, update, {multi: true})

    @emit "site-admins-added"

    return

  unsetUsersAsSiteAdmins: (users_ids, performing_user_id) ->
    # If performing_user_id is null we assume secured source

    if _.isString users_ids
      users_ids = [users_ids]

    check users_ids, [String]

    if performing_user_id?
      @requireUserIsSiteAdmin(performing_user_id)

    if _.isEmpty(users_ids)
      return

    if (hard_coded_users_ids = @getHardCodedAdminsUsersIds?())?
      for user_id in users_ids
        if user_id in hard_coded_users_ids
          throw @_error "cant-remove-hardcoded-site-admin"

    query =
      _id: $in: users_ids

    update =
      $unset: "site_admin": ""

    Meteor.users.update(query, update, {multi: true})

    return

  deactivateUsers: (users_ids, performing_user_id) ->
    # If performing_user_id is null we assume secured source

    if _.isString users_ids
      users_ids = [users_ids]

    check users_ids, [String]

    if performing_user_id?
      @requireUserIsSiteAdmin(performing_user_id)

    if _.isEmpty(users_ids)
      return

    users = Meteor.users.find({_id: {$in: users_ids}}, {fields: {is_proxy: 1, "site_admin.is_site_admin": 1}}).fetch()
    for user in users
      if user.is_proxy
        throw @_error "cannot-deactivate-proxy-user", "Cannot deactivate a proxy user"
      if @isUserSiteAdmin user
        throw @_error "cannot-deactivate-site-admin", "Cannot deactivate a site admin"

    for user_id in users_ids
      APP.collections.Projects.find({"members.user_id": user_id}, {fields: _id: 1}).forEach (doc) ->
        try
          APP.projects.removeMember doc._id, user_id, user_id # The 3rd argument is the performing user id ; A user can always remove himself from project even if not admin - the site admin, might not be an admin of all the projects the user is member of , therefore, by passing the user himself as the performing user, we ensure removability
        catch e
          # Examples for cases in which a removal of the member might fail:
          #
          # 1. If the removal of the user will cause the JustDo to remain without an admin
          #
          # In those cases, we'll simply skip the removal.
          null

        return

    APP.accounts.deactivateUsers users_ids

    return

  reactivateUsers: (users_ids, performing_user_id) ->
    # If performing_user_id is null we assume secured source

    if _.isString users_ids
      users_ids = [users_ids]

    check users_ids, [String]

    if performing_user_id?
      @requireUserIsSiteAdmin(performing_user_id)

    if _.isEmpty(users_ids)
      return

    APP.accounts.reactivateUsers users_ids

    return

  addExcludedUsersClauseToQuery: (query, performing_user_id) -> query

  getAllUsers: (performing_user_id) ->
    check performing_user_id, String

    @requireUserIsSiteAdmin(performing_user_id)

    query = {}

    query = @addExcludedUsersClauseToQuery(query, performing_user_id) or query

    fields = _.extend {}, JustdoHelpers.avatar_required_fields, {"site_admin.is_site_admin": 1, "deactivated": 1, "createdAt": 1}
    if @isUserSuperSiteAdmin performing_user_id
      _.extend fields, 
        "promoters": 1
        "invited_by": 1
        "profile.timezone": 1

    sort_criteria =
      "site_admin.is_site_admin": -1
      "deactivated": -1
      "profile.first_name": 1
      "profile.last_name": 1

    return Meteor.users.find(query, {fields: fields, sort: sort_criteria}).map (user) ->
      # _publicBasicUserInfoCursorDataOutputTransformer will remove the invited_by field which in the context of SSA
      # we want to keep
      invited_by = user.invited_by

      APP.accounts._publicBasicUserInfoCursorDataOutputTransformer user, performing_user_id

      user.invited_by = invited_by

      return user

  getAllSiteAdminsIds: (performing_user_id) ->
    if not @siteAdminFeatureEnabled("admins-list-public")
      throw @_error "not-supported", "admins-list-public conf isn't enabled in this site"

    query = {"site_admin.is_site_admin": true}

    query = @addExcludedUsersClauseToQuery(query, performing_user_id) or query

    return _.map(Meteor.users.find(query, {fields: {_id: 1}}).fetch(), (user_doc) -> return user_doc._id)
