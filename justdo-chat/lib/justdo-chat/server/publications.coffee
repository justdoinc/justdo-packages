_.extend JustdoChat.prototype,
  _setupPublications: ->
    self = @

    #
    # Channels related
    #

    Meteor.publish "jdcChannelMessages", (channel_type, channel_identifier, options) -> # Note the use of -> not =>, we need @userId
      # Publishes the channel document, if one exists, for the requested channel, and the messages
      # of this channel, according to the provided options.

      # Security note:
      #
      # channel_type is checked thoroughly by @generateServerChannelObject
      # channel_identifier is checked thoroughly by the channel object constructor on init.
      # options structures is thoroughly checked by channel_obj.getChannelMessagesCursor()
      # if @userId is not allowed to access the channel, exception will be thrown in the attempt
      # to generate channel_obj.
      self.requireAllowedChannelType(channel_type)
      check channel_identifier, Object
      check options, Match.Maybe(Object)

      channel_obj = self.generateServerChannelObject(channel_type, channel_identifier, @userId)

      return channel_obj.channelMessagesPublicationHandler(@, options)

    #
    # Subscribed channels recent activity related
    #

    Meteor.publish "jdcSubscribedUnreadChannelsCount", ->
      # Publishes the count of the unread subscribed channels to the *pseudo*
      # JDChatInfo collection under the doc _id: "subscribed_unread_channels_count".
      #
      # Note: on the web client JDChatInfo collection object is accessible from
      # APP.collections.JDChatInfo . See: client/pseudo-collections.coffee

      if not @userId?
        # Nothing to return for logged-out users
        @ready()

        return

      return self.subscribedUnreadChannelsCountPublicationHandler(@, @userId)

    Meteor.publish "jdcSubscribedChannelsRecentActivity", (options) ->
      # Publishes information about subscribed channels recent activity.

      # ## Published information:
      #
      # The information is published to the following pseudo collections:
      #
      # * JustdoChat.jdc_recent_activity_channels_collection_name
      #     * Docs will include:
      #        * channel_type
      #        * last_message_date
      #        * all types indenifying and augmented fields
      #        * a field named: `unread` that we derive from the subscribers sub-document
      #          will be true if the logged-in user has unread messages in the channel.
      # * JustdoChat.jdc_recent_activity_messages_collection_name
      # * Type specific pseudo collections for supplementary docs.
      # (see both/static-settings.coffee for actual names)
      # * JustdoChat.jdc_info_pseudo_collection_name
      #   * A document will be published under the id 'subscribed_channels_recent_activity_count' with
      #     a field 'count' that will hold the total count of subscribed channels recent activity
      #     to allow correct implementation of incremental loading of recent messages.
      #     The count isn't fully reactive, see setInterval under subscribedChannelsRecentActivityPublicationHandler
      #     for exact interval in which it updates.
      # * JustdoChat.jdc_recent_activity_authors_details_collection_name
      #   * Will get user documents similar to the one published by the publicBasicUsersInfo publication
      #     for all the authors of the messages under JustdoChat.jdc_recent_activity_messages_collection_name
      #     (to allow proper presentation of their details).
      #
      # We publish the information to pseudo collections to avoid data collisions with
      # other publications that publish documents from the collections involved in this publication
      # as is. We manipulate the original documents stored in the mongodb as we publish them in
      # this publication, to reduce the amount of updates required from the publication
      # (removing redundant data that we don't want to maintain up-to-data), and introduce
      # pseudo fields.
      #
      # ### Type specific pseudo collections
      #
      # Specific channel types can define more pseudo collections to publish additional
      # supplementary docs to.
      #
      # THESE DOCS AREN'T REACTIVE - They won't change during the course of the publication!
      # That's why they *must* be published to pseudo collections, to avoid collisions with
      # publications that does maintain them up-to-date.
      #
      # ## Reactivity nature of jdcSubscribedChannelsRecentActivity
      #
      # * The channels docs are fully reactive for the fields they have. Core devs, implemented with observer on Channels doc.
      # * The messages docs are fully reactive for the fields they have. Core devs, note: reactivity
      #   *isn't* acheived using observers on the messages collection. We do it for efficiency, we don't
      #   want O(N) (N recent channels activity count) observers to be set. Reactivity is based on changes
      #   observed on the channels last_message_date field.
      #
      # ## Security model:
      #
      # * We are basing the initial fetch of channels recent activity on the existence of the performing
      #   user in the subscribers sub-document of channels. This is a *WEAK* indication for access authorization.
      #   We therefore, create a channel object for every channel found in the fetch, to strongly verify
      #   access authorization.
      #   Resources usage wise, this in most cases will involve extra mongo requests, but that is fine,
      #   since these reqeuests, are very likely required anyway to provide the supplementary docs
      #   of the channel in a secured way, and it's unlikely to re-fetch the channel itself, since the
      #   provided channel identifier should be enough to answer whether or not access is permitted,
      #   without requesting the channel doc itself again.
      #   As with other parts of the JustdoChat, here again, if the authorization status of the user to
      #   a published channel will change, during the life of the publication - the user *won't* lose
      #   access to it, or to its supplementary data (!) .
      #
      # ## Other security consideration:
      #
      # * Options structures is thoroughly checked by self.subscribedChannelsRecentActivityPublicationHandler()
      
      check options, Match.Maybe(Object)

      if not @userId?
        # Nothing to return for logged-out users
        @ready()

        return

      return self.subscribedChannelsRecentActivityPublicationHandler(@, options, @userId)

    Meteor.publish "jdcBottomWindows", (options) ->
      # Publishes information about the user's bottom windows.

      # ## Published information:
      #
      # The information is published to the following pseudo collections:
      #
      # * JustdoChat.jdc_bottom_windows_channels_collection_name
      #     * Docs will include:
      #        * channel_type
      #        * all types indenifying and augmented fields
      #        * state - the window state
      #        * order - the window order
      #        * a field named: `unread` that we derive from the subscribers sub-document
      #          will be true if the logged-in user *is subscribed* and has unread messages
      #          in the channel.
      # * Type specific pseudo collections for supplementary docs.
      # (see both/static-settings.coffee for actual names)
      #
      # We publish the information to pseudo collections to avoid data collisions with
      # other publications that publish documents from the collections involved in this publication
      # as is. We manipulate the original documents stored in the mongodb as we publish them in
      # this publication, to reduce the amount of updates required from the publication
      # (removing redundant data that we don't want to maintain up-to-data), and introduce
      # pseudo fields.
      #
      # ### Type specific pseudo collections
      #
      # Specific channel types can define more pseudo collections to publish additional
      # supplementary docs to.
      #
      # THESE DOCS AREN'T REACTIVE - They won't change during the course of the publication!
      # That's why they *must* be published to pseudo collections, to avoid collisions with
      # publications that does maintain them up-to-date.
      #
      # ## Reactivity nature of jdcBottomWindows
      #
      # * The channels docs are fully reactive for the fields they have. Core devs, implemented with observer on Channels doc.
      #
      # ## Security model:
      #
      # * We are basing the initial fetch of channels recent activity on the existence of the performing
      #   user in the subscribers sub-document of channels. This is a *WEAK* indication for access authorization.
      #   We therefore, create a channel object for every channel found in the fetch, to strongly verify
      #   access authorization.
      #   Resources usage wise, this in most cases will involve extra mongo requests, but that is fine,
      #   since these reqeuests, are very likely required anyway to provide the supplementary docs
      #   of the channel in a secured way, and it's unlikely to re-fetch the channel itself, since the
      #   provided channel identifier should be enough to answer whether or not access is permitted,
      #   without requesting the channel doc itself again.
      #   As with other parts of the JustdoChat, here again, if the authorization status of the user to
      #   a published channel will change, during the life of the publication - the user *won't* lose
      #   access to it, or to its supplementary data (!) .
      #
      # ## Other security consideration:
      #
      # * Options structures is thoroughly checked by self.bottomWindowsPublicationHandler()
      
      check options, Match.Maybe(Object)

      if not @userId?
        # Nothing to return for logged-out users
        @ready()

        return

      return self.bottomWindowsPublicationHandler(@, options, @userId)

    Meteor.publish "jdcBotsInfo", ->
      col_name = JustdoChat.jdc_bots_info_collection_name

      for bot_id, bot_def of self.getBotsPublicInfo()
        @added col_name, bot_id,
          all_emails_verified: true
          profile: bot_def.profile
          msgs_types: bot_def.msgs_types

      @ready()

      return