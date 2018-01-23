APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.project_toolbar_chat_section.onCreated ->
    task_channel_object = null
    task_chat_object_dependency = new Tracker.Dependency()
    @getTaskChatObject = ->
      task_chat_object_dependency.depend()

      return task_channel_object

    @autorun =>
      if not (grid_control = module.gridControl())?
        # Grid control isn't ready can't init chat
        return

      task_channel_object =
        APP.justdo_chat.generateClientChannelObject "task",
          grid_control: grid_control
          project_object: module.curProj()
          task_id: module.activeItemId()

      task_channel_object.subscribeChannelMessagesPublication()

      task_chat_object_dependency.changed()

    return

  Template.project_toolbar_chat_section_container.helpers
    showSection: ->
      module_id = "justdo-chat"

      cur_project = module.curProj()
      if not cur_project?
        return

      return cur_project.isCustomFeatureEnabled(module_id)

  Template.project_toolbar_chat_section.helpers
    getTaskChatObject: ->
      tpl = Template.instance()

      return tpl.getTaskChatObject

    hasMessages: ->
      tpl = Template.instance()

      channel = tpl.getTaskChatObject()

      return channel.isSubscriptionMessagesHasDocs()
