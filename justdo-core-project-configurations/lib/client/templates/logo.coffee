get_current_proj = ->
  APP.modules.project_page.curProj()

#
# current_logo
#
Template.core_conf_logo_settings.helpers
  current_logo: ->
    if not (current_project = get_current_proj())?
      APP.logger.error "Couldn't find current project"

      return null

    return current_project.getProjectConfigurationSetting("project_logo")

  # current_logo_width: 

Template.core_conf_logo_settings.events
  "click .core-conf-logo-url-btn": ->
    if not (current_project = get_current_proj())?
      APP.logger.error "Couldn't find current project"

      return

    current_project.configureProject {project_logo: $(".core-conf-logo-url-input").val()}, (err) ->
      if err?
        # XXX need to display properly to the user
        APP.logger.error "Failed to set logo url: #{err.reason}"

    return

#
# current_logo_width
#

# Note the following could be easily DRYied with current_logo code, I didn't do it on purpose
# to ease readability as this file will be used as an example for adding
# items to the project conf menu -Daniel

Template.core_conf_logo_settings.helpers
  current_logo_width: ->
    if not (current_project = get_current_proj())?
      APP.logger.error "Couldn't find current project"

      return null

    return current_project.getProjectConfigurationSetting("project_logo_width")

Template.core_conf_logo_settings.events
  "click .core-conf-logo-width-btn": ->
    if not (current_project = get_current_proj())?
      APP.logger.error "Couldn't find current project"

      return

    current_project.configureProject {project_logo_width: parseFloat($(".core-conf-logo-width-input").val())}, (err) ->
      if err?
        # XXX need to display properly to the user
        APP.logger.error "Failed to set logo width: #{err.reason}"

    return