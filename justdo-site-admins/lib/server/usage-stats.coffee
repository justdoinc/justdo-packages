_.extend JustdoSiteAdmins.prototype,
  _setupUsageStatsFramework: ->
    if @client_type isnt "web-app"
      @_usage_stats_framework_enabled = false

      return

    @_usage_stats_framework_enabled = true

    @_initServerInfoAndMarkServerAsStarted()
    @getInstallationId()
    @_setupServerVitalsLogInterval()
    @_setupClearServerVitalsLogDbMigration()
    @onDestroy =>
      @_clearServerVitalsLogInterval()
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
  
  _clearServerVitalsLogInterval: -> Meteor.clearInterval @server_vital_log_interval

  _logCpuUsage: ->
    APP.server_info.cpu_usage =
      time: new Date()
      usage: process.cpuUsage()

    return

  getCpuUsagePercent: ->
    if not APP.server_info.cpu_usage?
      @_logCpuUsage()

    now = new Date()
    elapsed = now.getTime() - APP.server_info.cpu_usage.time.getTime()
    if elapsed < 1000
      return null

    usage = process.cpuUsage(APP.server_info.cpu_usage.usage)
    total_usage = usage.user + usage.system
    
    # time * 1000 because process.cpuUsage returns microseconds
    percent = (100 * total_usage) / (elapsed * 1000)

    return percent
  
  getInstallationId: -> 
    if (installation_id = APP.server_info?.installation_id)?
      return installation_id
    
    try
      installation_id = await JustdoHelpers.runInFiberAndGetResult -> APP.justdo_system_records?.getRecord?(JustdoSiteAdmins.installation_id_system_record_key)?.value
    catch err
      return undefined
    
    if not installation_id?
      installation_id = Random.id()
      try
        await JustdoHelpers.runInFiberAndGetResult ->
          APP.justdo_system_records?.setRecord? JustdoSiteAdmins.installation_id_system_record_key, 
            value: installation_id
          return
      catch err
        return undefined

    APP.server_info.installation_id = installation_id
    
    return installation_id

  _initServerInfoAndMarkServerAsStarted: ->
    if not APP.server_info?
      APP.server_info = {}
    
    if not APP.server_info.start_time?
      APP.server_info.start_time = new Date()

    if not APP.server_info.ssid?
      APP.server_info.ssid = "#{APP.server_info.start_time.toISOString()}-#{Math.round(Math.random() * 100)}"
    
    @_logCpuUsage()
    
    return

  getAppUptime: ->
    return new Date().getTime() - APP.server_info.start_time.getTime()
  
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
        
        arch: report.header.arch # Alternative: process.arch
        
        platform: report.header.platform # Alternative: process.platform
        
        release: report.header.osRelease # Alternative: @os.release()
        
        hostname: report.header.host # Alternative: @os.hostname()
        
        uname: report.header.osVersion # Alternative: @os.version()
        
        cpus: report.header.cpus # Alternative: @os.cpus()
        load_avg: @os.loadavg()
        
        uptime_ms: @os.uptime() * 1000 # Alternative: @os.uptime()
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
        installation_id: APP.server_info.installation_id
        ssid: APP.server_info.ssid
        current_time: new Date().toISOString()
        license: @getLicense()
        license_enc: process.env.JUSTDO_LICENSING_LICENSE
        start_time: APP.server_info.start_time.toISOString()
        uptime_ms: @getAppUptime() # in milliseconds
        active_sessions: @getActiveSessionsCount()
        app_keys: _.keys APP
      
      plugins: []

    for plugin_id, fn of APP.getPluginVitalsGenerators()
      payload = await JustdoHelpers.runInFiberAndGetResult -> fn()
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
