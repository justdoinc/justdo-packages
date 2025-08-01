APP.getEnv (env) ->
  # If an env variable affect this package load, check its value here
  # remember env vars are Strings

  if env.JUSTDO_AI_ENABLED isnt "true"
    return
  
  APP.emit "pre-justdo-ai-kit-init", env
  
  justdo_ai_conf = env.JUSTDO_AI_CONF or "{}"
  justdo_ai_conf = EJSON.parse(justdo_ai_conf.replace(/'/g, '"'))

  options =
    app_type: JustdoHelpers.getClientType env
    projects_collection: APP.collections.Projects
    tasks_collection: APP.collections.Tasks
    conf: justdo_ai_conf
  
  if Meteor.isServer
    justdo_ai_secret_conf = env.JUSTDO_AI_SECRET_CONF or "{}"
    justdo_ai_secret_conf = EJSON.parse(justdo_ai_secret_conf.replace(/'/g, '"'))

    APP.collections.AIQuery = new Mongo.Collection "ai_query"
    _.extend options,
      secret_conf: justdo_ai_secret_conf
      query_collection: APP.collections.AIQuery

  if Meteor.isClient
    APP.collections.AIResponse = new Mongo.Collection "ai_response"
    _.extend options,
      response_collection: APP.collections.AIResponse

  APP.justdo_ai_kit = new JustdoAiKit(options)

  return