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
          tasks_collection: grid_control.collection
          task_id: module.activeItemId()

      module.curProj() # XXX To trigger invalidation on project change, not sure if this is
                       # necessary, it used to be part of the options provided to
                       # generateClientChannelObject(), didn't have time to test effect of
                       # removing it, Daniel C.

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

    isProposedSubscribersEmulationMode: ->
      tpl = Template.instance()

      channel = tpl.getTaskChatObject()

      return channel.isProposedSubscribersEmulationMode()

  Template.project_toolbar_chat_section.events
    "keyup .message-editor": (e, tpl) ->
      # When the user begin typing, if we are under non-initilized channel,
      # turn on proposed subscribers emulation mode, turn off, if text clear

      channel = tpl.getTaskChatObject()

      if channel.getChannelMessagesSubscriptionState() == "no-channel-doc"
        if _.isEmpty $(e.target).val()
          channel.stopProposedSubscribersEmulationMode()
        else
          if not channel.isProposedSubscribersEmulationMode()
            channel.setProposedSubscribersEmulationMode()

      # Note, since for initialized channels the proposed subscribers mode has no effect,
      # we don't care much about turning it off.

      return
