requireCurrentUserIsSiteAdmin = ->
  if not APP.justdo_site_admins?
    throw new Meteor.Error "site-admin-required"
  
  APP.justdo_site_admins.requireUserIsSiteAdmin Meteor.userId()
  return

_.extend JustdoHelpers,
  _downloadJsonFile: (json_obj, filename) ->
    try
      # Convert the result to a formatted JSON string
      json_string = JSON.stringify(json_obj, null, 2)
      
      # Create a blob with the JSON content
      blob = new Blob([json_string], {type: "application/json"})
      
      # Create a download link
      url = URL.createObjectURL(blob)
      
      # Create a temporary anchor element to trigger download
      link = document.createElement("a")
      link.href = url
      link.download = filename
      
      # Trigger the download
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      
      # Clean up the URL object
      URL.revokeObjectURL(url)
      
      console.log "JSON downloaded successfully"
    catch err
      JustdoSnackbar.show
        text: "Error downloading JSON: #{err.message or err}"

  startV8Profiling: ->
    requireCurrentUserIsSiteAdmin()

    Meteor.call "JDHelpersProfilerStartV8Profiling", ->
      if err?
        JustdoSnackbar.show
          text: "Error starting V8 profiling: #{err.message or err}"
      return
    return
  
  stopV8Profiling: ->
    requireCurrentUserIsSiteAdmin()

    Meteor.call "JDHelpersProfilerStopV8Profiling", (err, res) =>
      if err?
        JustdoSnackbar.show
          text: "Error stopping V8 profiling: #{err.message or err}"
      else
        # Automatically download the profiling result as JSON
        filename = "#{new URL(env.ROOT_URL).host}-v8-profile-#{new Date().toISOString().replace(/[:.]/g, '-')}.cpuprofile"
        @_downloadJsonFile res, filename
      return
    return
  