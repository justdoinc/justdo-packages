Template.chat_bottom_windows_open.onCreated ->
  @channel_type = @data.channel_type
  @channel_identifier = @data.channel_identifier
  @channelObjectGenerator = @data.channelObjectGenerator
  @channel_obj = @channelObjectGenerator()
  @header_template = @data.header_template

  @titleGenerator = @data.titleGenerator
  @tooltipGenerator = @data.tooltipGenerator
  @titleUrlGenerator = @data.titleUrlGenerator
  @onClickTitle = @data.onClickTitle

  return

Template.chat_bottom_windows_open.onRendered ->
  $window_container = $(this.firstNode).closest(".window-container")

  $(this.firstNode).mousedown =>
    @channel_obj.enterFocusMode()

    return

  $window_container.click =>
    if not $window_container.hasClass "active"
      $(".window-container").removeClass "active"
      $window_container.addClass "active"

    return

  @blurCb = (e) =>
    if $(e.target).closest(".window-container").get(0) != $window_container.get(0)
      @channel_obj.exitFocusMode()

    return

  # We don't want mouseup/down on chat to trigger window activation
  @$(".close-chat")
    .mouseup (e) ->
      e.stopPropagation()

      return

    .mousedown (e) ->
      e.stopPropagation()

      return

  # The best user experience is with mousedown, but we can't trust mousedown to always
  # bubble up, hence, we have to bind to mouseup as well.
  $(document).mousedown @blurCb
  $(document).mouseup @blurCb

  return

Template.chat_bottom_windows_open.onDestroyed ->
  $(document).off("mousedown", @blurCb)
  $(document).off("mouseup", @blurCb)

  @channel_obj.destroy()

  return

Template.chat_bottom_windows_open.helpers
  getChannelObject: ->
    tpl = Template.instance()

    return => tpl.channel_obj # Note! We return a function that returns the object, as required by the common components templates

  getMessagesAuthorsCollection: ->
    return APP.collections.JDChatChannelMessagesAuthorsDetails

  getHeaderTemplate: ->
    tpl = Template.instance()

    return tpl.header_template

  getDataForHeaderTemplate: ->
    tpl = Template.instance()

    return _.extend {}, tpl.data, {channel_obj: tpl.channel_obj}

  getTitleUrl: ->
    tpl = Template.instance()
    return tpl.titleUrlGenerator?() or "#"

  getTooltip: ->
    tpl = Template.instance()
    return tpl.tooltipGenerator?() or ""

  getTitle: ->
    tpl = Template.instance()
    return tpl.titleGenerator() or ""

  getTask: ->
    tpl = Template.instance()

    return tpl.getTaskDoc()

  isFocused: ->
    tpl = Template.instance()

    return tpl.channel_obj.isFocused()

  hasUnreadMessages: ->
    tpl = Template.instance()

    return tpl.channel_obj.getChannelSubscriberDoc(Meteor.userId())?.unread

  taskURL: ->
    return JustdoHelpers.getTaskUrl(@project_id, @task_id)

Template.chat_bottom_windows_open.events
  "click .close-chat": (e, tpl) ->
    if APP.justdo_pwa.isMobileLayout()
      APP.justdo_pwa.clearActiveChatChannel()
    else
      APP.justdo_chat._justdo_chat_bottom_windows_manager.removeWindow tpl.channel_type, tpl.channel_identifier

    return

  "click .minimize-chat": (e, tpl) ->
    if APP.justdo_pwa.isMobileLayout()
      APP.justdo_pwa.clearActiveChatChannel()
    else
      APP.justdo_chat._justdo_chat_bottom_windows_manager.minimizeWindow tpl.channel_type, tpl.channel_identifier

    return

  "click .header-title": (e, tpl) ->
    e.preventDefault()

    tpl.onClickTitle?.call(@, e, tpl)

    return

  "click": (e, tpl) ->
    tpl.channel_obj?.setChannelUnreadState(false)

    return
