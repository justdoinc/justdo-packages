Template.justdo_resources_availability_project_config.events
  "click #project-resources-availability-config": (e, tpl) ->
    APP.justdo_resources_availability.displayConfigDialog JD.activeJustdo()._id
    return
