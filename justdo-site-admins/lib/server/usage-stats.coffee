_.extend JustdoSiteAdmins.prototype,
  _setupUsageStatsFramework: ->
    if @client_type isnt "web-app"
      @_usage_stats_framework_enabled = false

      return

    @_usage_stats_framework_enabled = true

    @_markServerStarted()
    @_ensureInstallationId()
    @_setupServerVitalsLogInterval()
    @_setupClearServerVitalsLogDbMigration()
    @onDestroy =>
      @_clearServerVitalsLogInverval()
      return

    return

  isUsageStatsFrameworkEnabled: -> @_usage_stats_framework_enabled

  _logCurrentServerVitallToDb: (mark_as_long_term=false) ->
    snapshot = await @getServerVitalsShrinkWrappedSecuredSource()
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

  produceServerVitalsShrinkWrappedFromSnapshot: (snapshot) ->
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

  getServerVitalsShrinkWrappedSecuredSource: ->
    snapshot = await @getServerVitalsSnapshotSecureSource()

    return @produceServerVitalsShrinkWrappedFromSnapshot(snapshot)

  getServerVitalsShrinkWrapped: (user_id) ->
    snapshot = await @getServerVitalsSnapshot(user_id)
    
    return @produceServerVitalsShrinkWrappedFromSnapshot(snapshot)

  getServerVitalsSnapshot: (user_id) ->
    @requireUserIsSiteAdmin(user_id)

    return await @getServerVitalsSnapshotSecureSource()

  getServerVitalsSnapshotSecureSource: ->
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

    for plugin_id, fn of APP.getPluginVitalsGenerators()
      payload = await fn()
      snapshot.plugins.push
        plugin_id: plugin_id 
        title: payload.title
        data: payload.data
      
    return snapshot

_.extend APP,
  _plugin_vitals_generators: {}

  registerPluginVitalsGenerator: (plugin_id, fn) ->
    if @_plugin_vitals_generators[plugin_id]?
      throw @_error "invalid-argument", "Plugin with id #{plugin_id} is already registered"
    
    @_plugin_vitals_generators[plugin_id] = fn

    return 
  
  getPluginVitalsGenerators: -> @_plugin_vitals_generators
