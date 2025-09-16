# The common chat messages board expect to have in its data context
# a getChannelObject() method.

Template.common_chat_messages_board.onCreated ->
  @request_authors_details = @data.request_authors_details or false

  @messages_authors_collection = @data.messages_authors_collection or Meteor.users

  @scrollToBottom = =>
    $messages_board_viewport = @$(".messages-board-viewport")

    if (messages_board_viewport_el = $messages_board_viewport.get(0))?
      $messages_board_viewport.scrollTop(messages_board_viewport_el.scrollHeight)

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
      channel.requestChannelMessages({request_authors_details: @request_authors_details, request_files_subscription: true}) # Request first messages payload

    # When a new message is sent by the user for this channel - scroll to bottom
    channel.on "message-sent", (@message_sent_handler = @scrollToBottom.bind(@))

    # I don't see situation where not removing the event will lead to mem-leak, so we don't
    # remove it on destroy (the channel obj is destroyed/replaced in a way that protects us).

    clearTimeout @current_initial_payload_sealing_timeout
    @initial_messages_payload_rendering_completed = false

    return

  # To display date seperators between messages.
  @prev_msg_date = null
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
  
  showMsgSeperatorWithDate: (index) ->
    tpl = Template.instance()

    # If this is the first message, always show the date seperator
    if index is 0
      tpl.prev_msg_date = moment(@createdAt)
      return true

    cur_msg_date = moment(@createdAt)
    should_show_date = not tpl.prev_msg_date.isSame(cur_msg_date, "day")

    tpl.prev_msg_date = cur_msg_date

    return should_show_date
    
  isBotLogMessage: ->
    return @author is "bot:log"

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

Template.chat_message_date_seperator.helpers
  formatMsgDate: (date) ->
    moment_date = moment(date)
    # sameElse formats all the dates less/more than a week from today. Default format is "DD/MM/YYYY"
    # In those cases we use user preferred date format instead.
    date_string = moment_date.calendar(null, {sameElse: JustdoHelpers.getUserPreferredDateFormat()})
    if APP.justdo_i18n.getLang() is JustdoI18n.default_lang
      # Vi and Zh-TW's day of week is already without time.
      # For En (default_lang), date_string could be something like "Last Friday at 12:00 AM", "Today at 12:00 AM", etc
      # This is to remove the "Last " prefix and the time, leaving only the day of week. 
      date_string = date_string.replace(/\sat.+$/, "").replace("Last ", "")
    
    # If date_string is day of week (Monday, Friday, etc.), add the date after it in user prefrred format.
    today = moment()
    yesterday = today.clone().subtract(1, "days")
    user_preferred_date = moment_date.format(JustdoHelpers.getUserPreferredDateFormat())
    if (date_string isnt user_preferred_date) and (not moment_date.isSame(today, "day")) and (not moment_date.isSame(yesterday, "day"))
      date_string = "#{date_string} #{user_preferred_date}"

    return date_string

Template.bot_log_chat_messages_board_message_card.helpers
  body: ->
    return APP.justdo_chat.renderDataMessage(@data, @author)

Template.common_chat_messages_board_message_card.helpers
  authorDoc: ->
    tpl = Template.closestInstance("common_chat_messages_board")

    if APP.justdo_chat.isBotUserId @author
      return APP.collections.JDChatBotsInfo.findOne(@author)

    return tpl.messages_authors_collection.findOne(@author)

  body: ->
    if @data?
      body = APP.justdo_chat.renderDataMessage(@data, @author)
    else
      body = @body

    if _.isEmpty(body)
      return ""

    body = linkifyStr(body, {nl2br: true}) # linkify already escapes html entities, so don't worry about xss here.

    body = APP.justdo_chat.linkTaskId(body)

    return JustdoHelpers.xssGuard body, {allow_html_parsing: true, enclosing_char: ""}

  isFilesEnabled: ->
    tpl = Template.instance()
    if not (channel_obj = tpl.getChannelObject?())?
      return false
    channel_type = channel_obj.channel_type
    return channel_obj.justdo_chat.isFilesEnabled(channel_type)

  fileExistsInMessage: ->
    return @files

  files: ->
    tpl = Template.instance()
    channel_obj = tpl.getChannelObject?()
    existing_files = []

    for file in @files
      file_fs_id = file.jd_file_id_obj.fs_id
      # Wrap the subscription in `Tracker.nonreactive` to avoid unsub caused by invalidation
      Tracker.nonreactive -> channel_obj.ensureFilesSubscriptionExists file_fs_id

      if (found_file = APP.justdo_file_interface.getBucketFolderFiles(file.jd_file_id_obj, file.jd_file_id_obj.file_id)[0])?
        existing_file = {jd_file_id_obj: file.jd_file_id_obj, additional_details: found_file}
        existing_files.push existing_file

    existing_file_ids = _.map existing_files, (file) -> file.jd_file_id_obj.file_id
    missing_files = _.filter @files, (file) -> file.jd_file_id_obj.file_id not in existing_file_ids

    existing_image_files = _.filter existing_files, (file) ->
      APP.justdo_files.isFileTypeImage(file.additional_details.type)

    existing_not_image_files = _.filter existing_files, (file) ->
      not APP.justdo_files.isFileTypeImage(file.additional_details.type)

    ret = {
      existing_image_files,
      existing_not_image_files,
      missing_files
    }

    return ret

  existingMaxVisibleImageFiles: (existing_image_files) ->
    return existing_image_files.slice(0, (Template.instance().max_visible_images_count - 1))

  lastVisibleImageFile: ->
    return @existing_image_files[Template.instance().max_visible_images_count - 1]

  hiddenImageCount: ->
    if @existing_image_files.length <= Template.instance().max_visible_images_count
      return false

    return @existing_image_files.length - Template.instance().max_visible_images_count + 1

  shouldUseGridLayout: ->
    return @existing_image_files.length >= Template.instance().max_visible_images_count

  size: ->
    return JustdoHelpers.bytesToHumanReadable @additional_details.size
  
  myMessage: ->
    return @author is Meteor.userId()

  shouldShowAvatar: ->
    tpl = Template.instance()
    channel_obj = tpl.getChannelObject?()

    is_msg_from_current_user = @author is Meteor.userId()
    is_msg_from_dm_channel = channel_obj?.channel_type is "user"
    return (not is_msg_from_current_user) and (not is_msg_from_dm_channel)

  shouldShowAuthorName: ->
    tpl = Template.instance()
    channel_obj = tpl.getChannelObject?()

    is_msg_from_performing_user = @author is Meteor.userId()
    is_msg_from_dm_channel = channel_obj?.channel_type is "user"
    return (not is_msg_from_performing_user) and (not is_msg_from_dm_channel)
    
  typeClass: -> Template.instance().getTypeCssClass(@additional_details.type)

Template.common_chat_messages_board_message_card.onCreated ->
  @getChannelObject = @closestInstance("common_chat_messages_board")?.data?.getChannelObject
  @max_visible_images_count = 4

  @getTypeCssClass = (file_type) ->
    [p1, p2] = file_type.split('/')
    if not p2?
      return p1
    else
      return p2.replace(/\./, "_")

    return

  return

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

Template.common_chat_messages_board_message_card.events
  "click .task-link": (e, tmpl) ->
    e.preventDefault()

    seq_id = parseInt($(e.target).closest(".task-link").text().trim().substr(1), 10)

    active_project_id = JD.activeJustdo({_id: 1})?._id

    if not (project_id = APP.collections.JDChatChannels.findOne(@channel_id, {fields: {project_id: 1}})?.project_id)?
      return

    task_id = APP.collections.Tasks.findOne({project_id: project_id, seqId: seq_id}, {fields: {_id: 1}})?._id

    if project_id == active_project_id
      APP.modules.project_page.getCurrentGcm()?.activateCollectionItemIdInCurrentPathOrFallbackToMainTab(task_id)
    else
      APP.modules.project_page.activateTaskInProject(project_id, task_id)

    return

  "click .show-preview-or-start-download": (e, tmpl) ->
    e.preventDefault()

    file = @
    # This handler assumes all the files in the same message have the same fs_id
    # If such behaviour is not guaranteed, we need to change this handler to iterate over the files and get the fs_id for each file.
    message_file_ids = _.map tmpl.data.files, (file) -> file.jd_file_id_obj.file_id

    APP.justdo_file_interface.showFilePreviewOrStartDownload file.jd_file_id_obj, message_file_ids

    return


Template.common_chat_messages_board_file_container.helpers
  isPreviewable: ->
    return APP.justdo_file_interface.getFileCategory(@type)?

  size: ->
    return JustdoHelpers.bytesToHumanReadable @additional_details.size

  isPdf: (type) ->
    return JustdoHelpers.mimeTypeToPreviewCategory(type) is "pdf"

  isImage: (type) ->
    return JustdoHelpers.mimeTypeToPreviewCategory(type) is "image"

  isVideo: (type) ->
    return JustdoHelpers.mimeTypeToPreviewCategory(type) is "video"

  getFilePreviewLink: ->
    tpl = Template.instance()
    channel_obj = tpl.getChannelObject?()
    task_id = channel_obj?.getChannelIdentifier().task_id
    return APP.justdo_file_interface.getFilePreviewLinkAsync(@jd_file_id_obj)

  typeClass: -> Template.instance().getTypeCssClass(@type)
