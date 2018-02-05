APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.project_toolbar_chat_section.onCreated ->
    task_channel_object = null
    task_chat_object_dependency = new Tracker.Dependency()
    @getTaskChatObject = ->
      task_chat_object_dependency.depend()

      return task_channel_object

    @mode = new ReactiveVar "chat"

    @autorun =>
      if not (grid_control = module.gridControl())?
        # Grid control isn't ready can't init chat
        return

      task_channel_object =
        APP.justdo_chat.generateClientChannelObject "task",
          grid_control: grid_control
          project_object: module.curProj()
          task_id: module.activeItemId()

      task_channel_object.requestChannelMessages()

      task_chat_object_dependency.changed()

      # In any change to the chat channel, reset the mode to the chat mode
      @mode.set("chat")

      return

    return

  Template.project_toolbar_chat_section.helpers
    mode: ->
      tpl = Template.instance()

      return tpl.mode.get()

    hasMessages: ->
      tpl = Template.instance()

      channel = tpl.getTaskChatObject()

      return channel.isMessagesSubscriptionHasDocs()
