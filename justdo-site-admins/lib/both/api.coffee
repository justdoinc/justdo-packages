_.extend JustdoSiteAdmins.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    @setupRouter()

    @initModules("Immediate")

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    @initModules("Deferred")

    return

  siteAdminFeatureEnabled: (feature_id) ->
    return feature_id in @site_admins_conf

  requireUserIsSiteAdmin: (user_id) ->
    if not @isUserSiteAdmin(user_id)
      throw @_error("site-admin-required")

    return

  # IMPORTANT: If you update this method, you must also the update 410-is-user-site-admin.coffee
  isUserSiteAdmin: (user) ->
    if not user?
      return false

    # If user is already an object, assume a user object, and avoid request to minimongo
    if _.isString user
      user = Meteor.users.findOne({_id: user, "site_admin.is_site_admin": true}, {fields: {_id: 1, site_admin: 1, emails: 1, all_emails_verified: 1, is_proxy: 1}})

    return (user?.site_admin?.is_site_admin is true) and JustdoHelpers.isUserEmailsVerified user
  # END IMPORTANT

  isUserSuperSiteAdmin: -> false

  requireUserIsSuperSiteAdmin: -> throw @_error("site-admin-required")

  isCurrentUserSiteAdmin: ->
    return @isUserSiteAdmin(Meteor.user())

  initModules: (type) ->
    @modules = {}

    for module_id, module_conf of JustdoSiteAdmins.modules
      if @siteAdminFeatureEnabled(module_id)
        @initModule(type, module_id, module_conf)

    return

  _registerModule_conf_schema: new SimpleSchema
    bothImmediateInit:
      type: Function
      optional: true

    clientImmediateInit:
      type: Function
      optional: true

    serverImmediateInit:
      type: Function
      optional: true

    bothDeferredInit:
      type: Function
      optional: true

    clientDeferredInit:
      type: Function
      optional: true

    serverDeferredInit:
      type: Function
      optional: true

    pre_set_as_admin_warnings:
      type: [String]
      optional: true

    pre_unset_as_admin_warnings:
      type: [String]
      optional: true

  initModule: (type, module_id, conf) ->
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerModule_conf_schema,
        conf or {},
        {self: @, throw_on_error: true}
      )
    conf = cleaned_val

    conf.id = module_id

    @modules[module_id] = conf

    @modules[module_id]["both#{type}Init"]?.call(@)

    if Meteor.isServer
      @modules[module_id]["server#{type}Init"]?.call(@)
    if Meteor.isClient
      @modules[module_id]["client#{type}Init"]?.call(@)

    return

  getQualifiedUsersCountInList: (all_users, pre_computed_hard_licensed_users, is_caller_excluded_user=false) ->
    return all_users.filter (user) =>
      if not (is_user_licensed = @isUserLicensed?(user, pre_computed_hard_licensed_users)?.licensed)
        return false
        
      # If current user is excluded, include also excluded users in the count, but without proxy users.
      if is_caller_excluded_user
        is_user_proxy = APP.accounts.isProxyUser user
        return is_user_licensed and not is_user_proxy

      # Note: Proxy users and also considered as excluded users. We want to exclude both in the count.
      is_user_excluded = APP.accounts.isUserExcluded?(user)?
      return is_user_licensed and not is_user_excluded
    .length
  
  getFreeProxyUsersCountInList: (all_users) ->
    # In non-sdk environments - proxies are paid users - hence, no point in showing them separately from Qualified Users (that should already include them in the count (!))
    unless @getLicense()?.license?.is_sdk is true
      return 0

    proxy_user_count = all_users
      .filter (user) -> APP.accounts.isProxyUser user
      .length
    
    return proxy_user_count or 0