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
    return JustdoHelpers.numberToHumanReadable num, {precision}

  msToHumanReadable: (ms) ->
    if not ms?
      return "N/A"
    
    return JustdoHelpers.msToHumanReadable ms, {include_seconds_if_gte_minute: false}

  bytesToHumanReadable: (bytes) -> 
    if not bytes?
      return "N/A"
  
    return JustdoHelpers.bytesToHumanReadable bytes, 1024

Template.justdo_site_admin_server_vitals.events
  "click .refresh-server-vitals": (e, tpl) ->
    tpl.getAndSetServerVitalsSnapshot()
    return
  
  "click .download-report": (e, tpl) ->
    APP.justdo_site_admins.getServerVitalsShrinkWrapped (err, res) =>
      if err?
        JustdoSnackbar.show
          text: err.reason
        return

      file_name = "justdo-server-vitals-#{new Date().toISOString().replaceAll(":", "_")}.json"
      data_str = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(res, null, 2))
      download_link = document.createElement("a")
      download_link.target = "_blank"
      download_link.href = data_str
      download_link.download = file_name

      document.body.appendChild(download_link)
      download_link.click()
      document.body.removeChild(download_link)

      return

    return