Template.user_channel_chat_bottom_windows_header.onCreated ->
  @receiving_user_id = @data.receiving_user_id
  return

Template.user_channel_chat_bottom_windows_header.helpers
  receivingUserDoc: ->
    tpl = Template.instance()
    if not (user_doc = APP.collections.JDChatChannelMessagesAuthorsDetails.findOne(tpl.receiving_user_id))?
      user_doc = Meteor.users.findOne(tpl.receiving_user_id)
    return  user_doc