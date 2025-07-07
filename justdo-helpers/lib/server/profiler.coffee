inspector = Npm.require "inspector"

# Global profiling state
active_profiling_session = null

requireUserIsSiteAdmin = (user_id) ->
  if not APP.justdo_site_admins?
    throw new Meteor.Error "site-admin-required"
  
  APP.justdo_site_admins.requireUserIsSiteAdmin(user_id)
  return

_.extend JustdoHelpers,
  startV8Profiling: ->
    if not APP.justdo_site_admins?.isCurrentUserSiteAdmin()
      throw new Meteor.Error "site-admin-required"
    promise = new Promise (resolve, reject) ->
      if active_profiling_session?
        return reject new Meteor.Error "not-supported", "V8 profiling session already active"

      active_profiling_session = new inspector.Session()
      active_profiling_session.connect()
      
      # Enable the profiler
      active_profiling_session.post 'Profiler.enable', (err) =>
        if err
          console.error "Failed to enable V8 profiler:", err
          return reject err
        
        # Start profiling
        active_profiling_session.post 'Profiler.start', (err) =>
          if err
            console.error "Failed to start V8 profiler:", err
            return reject err
          
          console.log "V8 profiling started"
          resolve()
        
    return promise
  
  stopV8Profiling: ->
    promise = new Promise (resolve, reject) ->
      if not active_profiling_session?
        return reject new Meteor.Error "not-supported", "No active V8 profiling session found"
    
      # Stop profiling and get the profile
      active_profiling_session.post 'Profiler.stop', (err, {profile}) =>
        if err
          console.error "Failed to stop V8 profiler:", err
          reject err
        else
          resolve profile
        
        # Disable profiler and disconnect
        active_profiling_session.post 'Profiler.disable', =>
          active_profiling_session.disconnect()
          
        active_profiling_session = null

      return
        
    return promise
  
Meteor.methods 
  "JDHelpersProfilerStartV8Profiling": ->
    requireUserIsSiteAdmin @userId
    return JustdoHelpers.startV8Profiling()
  
  "JDHelpersProfilerStopV8Profiling": ->
    requireUserIsSiteAdmin @userId
    return JustdoHelpers.stopV8Profiling()
  