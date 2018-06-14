# The common chat messages board expect to have in its data context
# a getChannelObject() method.

Template.common_chat_messages_board.onCreated ->
  @request_authors_details = @data.request_authors_details or false

  @messages_authors_collection = @data.messages_authors_collection or Meteor.users

  @scrollToBottom = =>
    $messages_board_viewport = @$(".messages-board-viewport")

    $messages_board_viewport.scrollTop($messages_board_viewport.get(0).scrollHeight)

    return

  @initial_messages_payload_rendering_completed = false
  @max_time_between_messages_to_be_considered_part_of_initial_payload_chain_ms = 150
  @current_initial_payload_sealing_timeout = null
  @initialPayloadMessageRendered = =>
    @scrollToBottom()

    if @current_initial_payload_sealing_timeout?
      clearTimeout @current_initial_payload_sealing_timeout

    @current_initial_payload_sealing_timeout = setTimeout =>
      # Read comment about @initial_messages_payload_rendering_completed above!
      @initial_messages_payload_rendering_completed = true

      @scrollToBottom()

      return
    , @max_time_between_messages_to_be_considered_part_of_initial_payload_chain_ms

    return

  # If set to a message card, on the next message card rendering, stick the viewport to
  # to the head of that message_card. Used when loading additional tasks to place the viewport
  # on the last message the user saw and avoid perceived "jump" to the beginning of the list
  # of received tasks. See comment for @initial_messages_payload_rendering_completed regarding the way
  # onRendered() works, we rely/affected on/by that behavior for
  # @stick_viewport_to_card_on_next_cards_render as well.
  @stick_viewport_to_card_on_next_cards_render = null

  @autorun =>
    #
    # Whenever new channel is created for this template
    #
    channel = @data.getChannelObject()

    # We run the following within a nonreactive context, so if a subscription is created
    # by it, it won't get destroyed as a result of the computation invalidation/destructino.
    Tracker.nonreactive =>
      channel.requestChannelMessages({request_authors_details: @request_authors_details}) # Request first messages payload

    # When a new message is sent by the user for this channel - scroll to bottom
    channel.on "message-sent", (@message_sent_handler = @scrollToBottom.bind(@))

    # I don't see situation where not removing the event will lead to mem-leak, so we don't
    # remove it on destroy (the channel obj is destroyed/replaced in a way that protects us).

    @initial_messages_payload_rendering_completed = false

    return

  return

Template.common_chat_messages_board.onDestroyed ->
  channel = @data.getChannelObject()

  channel?.removeListener "message-sent", @message_sent_handler

  return

Template.common_chat_messages_board.helpers
  messages: ->
    channel = @getChannelObject()

    if (cursor = channel.getMessagesSubscriptionCursorInNaturalOrder())?
      return cursor.fetch()

    return []

Template.common_chat_messages_board.events
  "scroll .messages-board-viewport": (e, tpl) ->
    channel = @getChannelObject()

    if tpl.$(".messages-board-viewport").scrollTop() == 0
      # channel.requestChannelMessages will request more messages, if there are more
      # messages to request.

      channel.requestChannelMessages
        request_authors_details: @request_authors_details
        onReady: =>
          tpl.stick_viewport_to_card_on_next_cards_render = tpl.$(".message-card:first-child")

          return

    return

Template.common_chat_messages_board_message_card.helpers
  friendlyDateFormat: ->
    return APP.justdo_chat.friendlyDateFormat(@createdAt)

  authorDoc: ->
    tpl = Template.closestInstance("common_chat_messages_board")

    return tpl.messages_authors_collection.findOne(@author)

  body: ->
    body = @body

    body = JustdoHelpers.htmlEntities(body)

    body = JustdoHelpers.nl2br(body)

    body = linkifyStr(body)

    return body

Template.common_chat_messages_board_message_card.onRendered ->
  $message_card = @$(".message-card")

  $messages_board = $message_card.closest(".messages-board")
  $messages_board_viewport = $message_card.closest(".messages-board-viewport")

  common_chat_messages_board_tpl =
    Template.closestInstance("common_chat_messages_board")

  if common_chat_messages_board_tpl.initial_messages_payload_rendering_completed == false
    common_chat_messages_board_tpl.initialPayloadMessageRendered()

    return

  if ($stick_to = common_chat_messages_board_tpl.stick_viewport_to_card_on_next_cards_render)?
    common_chat_messages_board_tpl.stick_viewport_to_card_on_next_cards_render = null

    if $stick_to.closest('body').length != 0
      # If the item is still in the DOM - note, that otherwise, we don't return,
      # the stick_viewport_to_card_on_next_cards_render is cleared few lines
      # above, and we use the same alg as if it wasn't set.
      #
      # https://stackoverflow.com/questions/4040715/check-if-cached-jquery-object-is-still-in-dom
      $messages_board_viewport.scrollTop($stick_to.position().top)

      return

    else
      # I assume, that case where it is == 0 will be very rare (if ever) D.C
      console.warn "Missing message card, ignoring"

      # Note, no return, keep going as if stick_viewport_to_card_on_next_cards_render wasn't set!

  messages_board_height_without_rendered_message_card =
    $messages_board.height() - $message_card.outerHeight(true)

  view_port_scroll_bottom = $messages_board_viewport.scrollTop() + $messages_board_viewport.height()

  # if the viewport is scrolled up to `scroll_to_bottom_threshold` from the bottom (excluding the
  # just rendered card), scroll it to the bottom with the addition of the new card.
  scroll_to_bottom_threshold = 50

  if (messages_board_height_without_rendered_message_card - view_port_scroll_bottom) < scroll_to_bottom_threshold
    common_chat_messages_board_tpl.scrollToBottom()

  return
