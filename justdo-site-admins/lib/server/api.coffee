_.extend JustdoSiteAdmins.prototype,
  _immediateInit: ->
    @_markServerStarted()
    @_ensureInstallationId()
    @_setupServerVitalsLogInterval()
    @_setupClearServerVitalsLogDbMigration()
    @onDestroy =>
      @_clearServerVitalsLogInverval()
      return
      
    return

  _deferredInit: ->
    if @destroyed
      return

    @_setupMethods()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return
  
  _logCurrentServerVitallToDb: (mark_as_long_term=false) ->
    snapshot = await @getServerVitalsShrinkWrapped()
    if mark_as_long_term
      snapshot.long_term = true
    @server_vitals_collection.insert snapshot
    return

  _setupServerVitalsLogInterval: ->
    # Log once immediately upon seraver startup
    Meteor.startup =>
      @_logCurrentServerVitallToDb true
      return

    count = 0
    @server_vital_log_interval = Meteor.setInterval =>
      mark_as_long_term = count >= JustdoSiteAdmins.long_term_server_vitals_ratio
      if mark_as_long_term
        count = 0
        
      @_logCurrentServerVitallToDb mark_as_long_term
      count += 1
      return
    , JustdoSiteAdmins.log_server_vitals_interval_ms

    return
  
  _clearServerVitalsLogInverval: -> Meteor.clearInterval @server_vital_log_interval

  _logCpuUsage: ->
    @cpu_usage =
      time: new Date()
      usage: process.cpuUsage()

    return

  getCpuUsagePercent: ->
    if not @cpu_usage?
      @_logCpuUsage()

    now = new Date()
    elapsed = now.getTime() - @cpu_usage.time.getTime()
    if elapsed < 1000
      return null

    usage = process.cpuUsage(@cpu_usage.usage)
    total_usage = usage.user + usage.system
    
    # time * 1000 because process.cpuUsage returns microseconds
    percent = (100 * total_usage) / (elapsed * 1000)

    return percent

  _ensureInstallationId: ->
    if not @getInstallationId()
      APP.justdo_system_records.setRecord JustdoSiteAdmins.installation_id_system_record_key, 
        value: Random.id()
    
    return
  
  getInstallationId: -> APP.justdo_system_records.getRecord(JustdoSiteAdmins.installation_id_system_record_key)?.value

  _markServerStarted: ->
    @start_time = new Date()
    @_logCpuUsage()
    @ssid = "#{@start_time.toISOString()}-#{Math.round(Math.random() * 100)}"
    return

  getAppUptime: ->
    return new Date().getTime() - @start_time.getTime()
  
  getActiveSessionsCount: -> Meteor.server?.sessions?.size

  getLicense: -> 
    if not @isLicenseEnabledEnvironment()
      return {state: "none"}
    
    return {state: "active", license: global.LICENSE}

  isLicenseEnabledEnvironment: -> global.LICENSE?

  setUsersAsSiteAdmins: (users_ids, performing_user_id) ->
    # If performing_user_id is null we assume secured source

    if _.isString users_ids
      users_ids = [users_ids]

    check users_ids, [String]

    if performing_user_id?
      @requireUserIsSiteAdmin(performing_user_id)

    if _.isEmpty(users_ids)
      return

    users = Meteor.users.find({_id: {$in: users_ids}}, {fields: {deactivated: 1, is_proxy: 1, emails: 1}}).fetch()
    for user in users
      if user.deactivated
        throw @_error "cannot-promote-deactivated-user-to-site-admin", "Cannot promote deactivated user to site admin"
      if user.is_proxy
        throw @_error "cannot-promote-proxy-user-to-site-admin", "Cannot promote proxy user to site admin"
      if not JustdoHelpers.isUserEmailsVerified user
        throw @_error "not-supported", "Cannot promote user with non-verified email to site admin"

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

  addExcludedUsersClauseToQuery: (query, performing_user_id) ->
    if not APP.accounts.getRegexForExcludedEmailDomains?
      return query

    # If licensing is enabled for the domain, don't send over the excluded users.
    if @isLicenseEnabledEnvironment()
      if performing_user_id?
        # If performing_user_id is provided, prevent excluding excluded user if the user itself is an excluded user
        check performing_user_id, String
        performing_user = Meteor.users.findOne(performing_user_id, {emails: 1})
        if APP.accounts.isUserExcluded? performing_user
          return query

      query["emails.address"] =
        $not: APP.accounts.getRegexForExcludedEmailDomains()

    return query

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

    return Meteor.users.find(query, {fields: fields, sort: sort_criteria}).map (user) =>
      # _publicBasicUserInfoCursorDataOutputTransformer will remove the invited_by field which in the context of SSA
      # we want to keep
      invited_by = user.invited_by

      APP.accounts._publicBasicUserInfoCursorDataOutputTransformer user, performing_user_id

      user.invited_by = invited_by

      return user

  getAllSiteAdminsIds: (performing_user_id) ->
    if not @siteAdminFeatureEnabled("admins-list-public")
      throw @_error "not-supported", "admins-list-public conf isn't enabled in this site"

    query = {"site_admin.is_site_admin": true, "emails.verified": true}

    query = @addExcludedUsersClauseToQuery(query, performing_user_id) or query

    return Meteor.users.find(query, {fields: {_id: 1}}).map (user_doc) -> return user_doc._id

  registerPluginVitalsGenerator: (plugin_id, fn) ->
    if not @plugin_vitals?
      @plugin_vitals = {}
    
    if @plugin_vitals[plugin_id]?
      throw @_error "invalid-argument", "Plugin with id #{plugin_id} is already registered"
    
    @plugin_vitals[plugin_id] = fn

    return 
  
  _getPluginVitalsGenerator: -> @plugin_vitals

  getServerVitalsShrinkWrapped: (user_id) ->


    snapshot = await @getServerVitalsSnapshot user_id
    
    # Convert .plugins to be of the form:
    # {
    #   "plugin-id": {
    #     "data-key": value
    #     "data-key": value
    #     "data-key": value
    #   }
    # }
    plugin_obj = {}
    if not _.isEmpty snapshot.plugins
      for plugin_data in snapshot.plugins
        plugin_obj[plugin_data.plugin_id] = {}
        for data in plugin_data.data
          plugin_obj[plugin_data.plugin_id][data.id] = data.value
    
    snapshot.plugins = plugin_obj

    return snapshot

  getServerVitalsSnapshot: (user_id) ->
    if user_id?
      @requireUserIsSiteAdmin(user_id)

    if not @v8?
      @v8 = Npm.require "v8"
    if not @os?
      @os = Npm.require "os"
    
    report = process.report.getReport()
    mongo_stats = await APP.collections.Tasks.rawDatabase().stats()

    snapshot = 
      system:
        # process.arch
        arch: report.header.arch
        # process.platform
        platform: report.header.platform
        # @os.release()
        release: report.header.osRelease
        # @os.hostname()
        hostname: report.header.host
        # @os.version()
        uname: report.header.osVersion
        # @os.cpus()
        cpus: report.header.cpus
        load_avg: @os.loadavg()
        # @os.uptime()
        uptime_ms: @os.uptime() * 1000
        memory:
          total: @os.totalmem()
          free: @os.freemem()

      mongo: await mongo_stats

      process:
        # process.versions
        versions: report.header.componentVersions
        uptime_ms: process.uptime() * 1000
        memory: process.memoryUsage()
        v8_heap_stats: @v8.getHeapStatistics()
        cpu_usage_percent: @getCpuUsagePercent() # percentages

      app:
        version: JustdoHelpers.getAppVersion false
        installation_id: @getInstallationId()
        ssid: @ssid
        current_time: new Date().toISOString()
        license: @getLicense()
        license_enc: process.env.JUSTDO_LICENSING_LICENSE
        start_time: @start_time.toISOString()
        uptime_ms: @getAppUptime() # in milliseconds
        active_sessions: @getActiveSessionsCount()
        app_keys: _.keys APP
      
      plugins: []

    for plugin_id, fn of @_getPluginVitalsGenerator()
      payload = await fn()
      snapshot.plugins.push
        plugin_id: plugin_id 
        title: payload.title
        data: payload.data
      
    return snapshot