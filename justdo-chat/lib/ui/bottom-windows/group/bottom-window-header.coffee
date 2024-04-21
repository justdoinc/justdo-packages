Template.group_channel_chat_bottom_windows_header.onCreated ->
  @channel_obj = @data.channel_obj
  return

Template.group_channel_chat_bottom_windows_header.helpers
  avatar: ->
    tpl = Template.instance()
    return tpl.channel_obj.getChannelIcon()

  title: ->
    tpl = Template.instance()
    return tpl.channel_obj.getChannelTitle()

  # As of writing, channels without project_id are special type of channel
  # that are used from our bot to send welcome message to new users.
  # Therefore they shouldn't be editable by users.
  isChannelProjectDocExists: ->
    tpl = Template.instance()
    return tpl.channel_obj.getChannelProjectDoc()?

Template.group_channel_chat_bottom_windows_header.events
  "click .header-title": (e, tpl) ->
    e.preventDefault()
    APP.justdo_chat.upsertGroupChat({group_id: tpl.channel_obj.getChannelIdentifier()._id})
    return