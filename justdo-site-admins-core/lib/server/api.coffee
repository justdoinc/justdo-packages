_.extend JustdoSiteAdmins.prototype,
  _coreImmediateInit: ->
    return

  _coreDeferredInit: ->
    if @destroyed
      return

    @_setupCoreMethods()

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

    hard_coded_users_ids = @getHardCodedAdminsUsersIds()
    for user_id in users_ids
      if user_id in hard_coded_users_ids
        throw @_error "cant-remove-hardcoded-site-admin"

    query =
      _id: $in: users_ids

    update =
      $unset: "site_admin": ""

    Meteor.users.update(query, update, {multi: true})

    return

  getAllUsers: (performing_user_id) ->
    check performing_user_id, String

    @requireUserIsSiteAdmin(performing_user_id)

    query = {}

    query = @addExcludedUsersClauseToQuery(query, performing_user_id)

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

    query = @addExcludedUsersClauseToQuery(query, performing_user_id)

    return _.map(Meteor.users.find(query, {fields: {_id: 1}}).fetch(), (user_doc) -> return user_doc._id)
