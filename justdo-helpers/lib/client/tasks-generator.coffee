# Tasks generator
_.extend JustdoHelpers,
  tasksGenerator: (options, cb) ->
    if not JustdoHelpers.isPocPermittedDomains()
      return
    
    if not _.isObject(options)
      options = {}

    if (current_project_id = APP.modules.project_page?.curProj()?.id)?
      options.project_id = current_project_id

    Meteor.call "JDHelpersTasksGenerator", options, (err, result) ->
      if err?
        console.error err
      else
        console.log "#{result} tasks added."
      
      JustdoHelpers.callCb cb, err, result

      return
    
    return