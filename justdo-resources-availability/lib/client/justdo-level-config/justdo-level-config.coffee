Template.justdo_resources_availability_project_config.onCreated ->
  # JustDo level config or user level config
  @level = @data.level
  @isJustdoLevelConfig = => @level is "justdo"
  @isUserLevelConfig = => @level is "user"
  return

Template.justdo_resources_availability_project_config.helpers
  isJustdoLevelConfig: -> 
    tpl = Template.instance()
    return tpl.isJustdoLevelConfig()
    
  isUserLevelConfig: -> 
    tpl = Template.instance()
    return tpl.isUserLevelConfig()

Template.justdo_resources_availability_project_config.events
  "click #project-resources-availability-config": (e, tpl) ->
    if tpl.isJustdoLevelConfig()
      APP.justdo_resources_availability.displayConfigDialog JD.activeJustdo({_id: 1})._id
    else if tpl.isUserLevelConfig()
      APP.justdo_resources_availability.displayConfigDialog JD.activeJustdo({_id: 1})._id, Meteor.userId()

    return
