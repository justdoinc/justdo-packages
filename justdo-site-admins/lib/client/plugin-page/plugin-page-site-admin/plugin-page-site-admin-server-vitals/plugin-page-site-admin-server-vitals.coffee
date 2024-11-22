Template.justdo_site_admin_server_vitals.onCreated ->
  @server_vitals_snapshot_rv = new ReactiveVar()
  @getAndSetServerVitalsSnapshot = =>
    APP.justdo_site_admins.getServerVitalsSnapshot (err, res) =>
      if err?
        JustdoSnackbar.show
          text: err.reason
        return

      @server_vitals_snapshot_rv.set res
      return
    return
  @getAndSetServerVitalsSnapshot()
  @refresh_server_vitals_snapshot_interval = Meteor.setInterval @getAndSetServerVitalsSnapshot, JustdoSiteAdmins.site_admins_server_vitals_page_refresh_interval

  return

Template.justdo_site_admin_server_vitals.onDestroyed ->
  Meteor.clearInterval @refresh_server_vitals_snapshot_interval
  return

Template.justdo_site_admin_server_vitals.helpers
  serverVitalSnapshot: -> Template.instance().server_vitals_snapshot_rv.get()

  formatNumber: (num, precision) ->
    if _.isNumber precision
      num = JustdoHelpers.roundNumber num, precision

    # To add the commas between digits
    return num.toLocaleString()

  msToHumanReadable: (ms) ->
    if not ms?
      return "N/A"
    
    return JustdoHelpers.msToHumanReadable ms, {include_seconds_if_gte_minute: false}

  bytesToHumanReadable: (bytes) -> 
    if not bytes?
      return "N/A"
  
    return JustdoHelpers.bytesToHumanReadable bytes, 1024
  
  pluginsData: ->
    plugins = []
    if not _.isEmpty @plugins
      for plugin_name, plugin_data of @plugins
        data = []
        for key, value of plugin_data
          data.push {key, value}
          
        plugins.push {name: plugin_name, data}

    return plugins

Template.justdo_site_admin_server_vitals.events
  "click .refresh-server-vitals": (e, tpl) ->
    tpl.getAndSetServerVitalsSnapshot()
    return