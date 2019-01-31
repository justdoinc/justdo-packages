getUrlDomain = (url) ->
  return /^(?:https?:\/\/)?(?:[^@\n]+@)?(?:www\.)?([^:\/\n]+)/im.exec(url)[1]

global_prod_landing_app = "https://justdo.today"
global_prod_webapp = "https://app.justdo.today"

global_beta_landing_app = "https://beta.justdo.today"
global_beta_webapp = "https://app-beta.justdo.today"

_.extend JustdoHelpers,
  getProdUrl: (app_type) ->
    # app_type can be either: "web-app" or "landing-app" we will ignore any input error
    if app_type == "web-app"
      app_url = process.env.WEB_APP_ROOT_URL

      global_prod_url = global_prod_webapp
      global_beta_url = global_beta_webapp
    else
      app_url = process.env.LANDING_APP_ROOT_URL

      global_prod_url = global_prod_landing_app
      global_beta_url = global_beta_landing_app


    if not (environment = process.env.ENV)? or environment == "prod"
      # No env seperation here, just return the WEB_APP_ROOT_URL
      return app_url

    # We are on beta and prod is requested.

    if app_url == global_beta_url
      # The global prod is a special case where it comes to domain naming
      # conventions.

      return global_prod_url
    else
      # The global prod is a special case where it comes to domain naming
      # conventions.

      return app_url.replace("-beta.", ".")

  getProdDomain: (app_type) -> @getProdUrl().replace(/https?:\/\//, "")
