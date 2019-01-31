init_app_login_target = (env) ->
  permitted_root_urls = null

  web_app_root_url = env.WEB_APP_ROOT_URL
  landing_app_root_url = env.LANDING_APP_ROOT_URL

  if root_url? or web_app_root_url? or landing_app_root_url?
    permitted_root_urls = []

    if web_app_root_url?
      permitted_root_urls.push web_app_root_url

    if landing_app_root_url?
      permitted_root_urls.push landing_app_root_url

  APP.login_target = new JustdoLoginTarget
    permitted_root_urls: permitted_root_urls

if Meteor.isClient
  APP.once "env-vars-ready", ->
    init_app_login_target(env)
else if Meteor.isServer
  init_app_login_target(process.env)