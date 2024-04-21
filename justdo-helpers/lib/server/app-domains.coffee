getUrlDomain = (url) ->
  return /^(?:https?:\/\/)?(?:[^@\n]+@)?(?:www\.)?([^:\/\n]+)/im.exec(url)[1]

global_prod_landing_app = "https://justdo.com"
global_prod_webapp = "https://app.justdo.com"

global_beta_landing_app = "https://beta.justdo.com"
global_beta_webapp = "https://app-beta.justdo.com"

_.extend JustdoHelpers,
  getProdUrl: (app_type) ->
    # In the past, we had a beta environment for every JustDo's deployment.
    #
    # Now, only the global deployment (app./justdo.com) has a beta environment (app-beta/beta.justdo.com).
    #
    # This method will return for the app-type the prod url if we are in a global
    # beta site:
    #
    #   * global_beta_webapp -> global_prod_webapp
    #   * global_beta_landing_app -> global_prod_landing_app
    #
    # For all the rest of the deployments it'll do nothing.

    # app_type can be either: "web-app" or "landing-app" we will ignore any input error
    if app_type == "web-app"
      app_url = process.env.WEB_APP_ROOT_URL

      global_prod_url = global_prod_webapp
      global_beta_url = global_beta_webapp
    else
      app_url = process.env.LANDING_APP_ROOT_URL

      global_prod_url = global_prod_landing_app
      global_beta_url = global_beta_landing_app

    if app_url == global_beta_url
      return global_prod_url

    return app_url

  getProdDomain: (app_type) -> @getProdUrl().replace(/https?:\/\//, "")
