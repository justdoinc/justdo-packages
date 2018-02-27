channel_type_to_channels_constructors = share.channel_type_to_channels_constructors

_.extend JustdoChat.prototype,
  _immediateInit: ->
    @_initRecentActivitySupplementaryPseudoCollections()

    return

  _initRecentActivitySupplementaryPseudoCollections: ->
    @recent_activity_supplementary_pseudo_collections = {}

    for channel_type, channel_type_conf of share.channel_types_conf
      if (sup_pseudo_cols = channel_type_conf.recent_activity_supplementary_pseudo_collections)?
        for col_id, col_name of sup_pseudo_cols
          @recent_activity_supplementary_pseudo_collections[col_id] = new Mongo.Collection(col_name)

    return

  _setupHtmlTitlePrefixController: ->
    count_observer_autorun = Tracker.autorun ->
      count = APP.collections.JDChatInfo.findOne("subscribed_unread_channels_count")?.count or 0

      if count > 0
        APP.page_title_manager.setPrefix("(#{count})")
      else
        APP.page_title_manager.setPrefix("")

      return

    @onDestroy ->
      count_observer_autorun.stop()

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  generateClientChannelObject: (channel_type, channel_conf, other_options) ->
    @requireAllowedChannelType(channel_type)
    check channel_conf, Object

    # See both/static-channel-registrar.coffee
    channel_constructor_name = channel_type_to_channels_constructors[channel_type].client

    conf = _.extend {
      justdo_chat: @
      channel_conf: channel_conf
    }, other_options

    return new share[channel_constructor_name](conf)

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    _.each @_on_destroy_procedures, (proc) -> proc()

    @destroyed = true

    @logger.debug "Destroyed"

    return