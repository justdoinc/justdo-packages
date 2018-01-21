# The common chat messages board expect to have in its data context
# a getChannelObject() method.

Template.common_chat_messages_board.helpers
  messages: ->
    channel = @getChannelObject()

    if (cursor = channel.getSubscriptionMessagesCursorInNaturalOrder())?
      return cursor.fetch()

    return []

Template.common_chat_messages_board_message_card.helpers
  friendlyDateFormat: ->
    return APP.justdo_chat.friendlyDateFormat(@createdAt)

  authorDoc: -> return Meteor.users.findOne(@author)

Template.common_chat_messages_board_message_card.onRendered ->
  # Scroll to bottom
  $board = @$(".message-card").closest(".messages-board")
  $board.scrollTop($board.get(0).scrollHeight)

  return
