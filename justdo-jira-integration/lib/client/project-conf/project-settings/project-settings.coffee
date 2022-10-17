Template.justdo_jira_integration_project_setting.onCreated ->
  # @OAuth1_login_link_rv = new ReactiveVar ""
  # APP.justdo_jira_integration.getOAuth1LoginLink JD.activeJustdoId(), (err, link) =>
  #   if err?
  #     console.error err.response
  #     return
  #   @OAuth1_login_link_rv.set link
  #   return

  @OAuth2_login_link_rv = new ReactiveVar ""
  APP.justdo_jira_integration.getOAuth2LoginLink JD.activeJustdoId(), (err, link) =>
    if err?
      console.error err.response
      return
    @OAuth2_login_link_rv.set link
    return

Template.justdo_jira_integration_project_setting.helpers
  # OAuth1LoginLink: ->Template.instance().OAuth1_login_link_rv.get()

  OAuth2LoginLink: -> Template.instance().OAuth2_login_link_rv.get()

  serverInfo: ->
    return APP.justdo_jira_integration.getJiraServerInfoFromJustdoId JD.activeJustdoId()

Template.justdo_jira_integration_project_setting.events
  "click .jira-login-link": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()

    target_link = $(e.target).closest(".jira-login-link").attr "href"
    window.open target_link, "_blank"
    return
