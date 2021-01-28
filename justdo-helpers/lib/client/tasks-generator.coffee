# Tasks generator

default_options =
  max_levels: 10
  max_items_to_add: 1000 # If we add max_items_to_add tasks, we will stop adding more tasks immediately
  min_items_per_parent: 1
  max_items_per_parent: 10
  parents: ["0"]
  max_words_in_title: 20 # 0 means no title will be set by us
  max_words_in_status: 20 # 0 means no status will be set by us
  fields: {}

_.extend JustdoHelpers,
  tasksGenerator: (options, cb) ->
    if not JustdoHelpers.isPocPermittedDomains()
      return
    
    default_options = _.extend default_options,
      project_id: APP.modules.project_page?.curProj()?.id
    options = _.extend default_options, options

    Meteor.call "JDHelpersTasksGenerator", options, (err, result) ->
      if err?
        console.error err
      else
        console.log "#{result} tasks added."
      
      JustdoHelpers.callCb cb, err, result

      return
    
    return