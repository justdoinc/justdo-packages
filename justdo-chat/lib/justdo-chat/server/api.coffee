channel_type_to_channels_constructors = share.channel_type_to_channels_constructors

default_subscribed_channels_recent_activity_limit = 10
default_subscribed_unread_channels_limit = 10

default_bottom_windows_limit = 30

# If you change the fields here, consider changing them also for publicBasicUsersInfo publication
# (from which they are derived), look for file named 020-publications.coffee
published_recent_activity_authors_details_fields =
  _id: 1
  emails: 1
  "profile.first_name": 1
  "profile.last_name": 1
  "profile.profile_pic": 1
  "profile.avatar_fg": 1
  "profile.avatar_bg": 1

_.extend JustdoChat.prototype,
  _immediateInit: ->
    for type, conf of share.channel_types_server_specific_conf
      if conf._immediateInit?
        conf._immediateInit.call(@)

    return

  _deferredInit: ->
    if @destroyed
      return

    for type, conf of share.channel_types_server_specific_conf
      if conf._deferredInit?
        conf._deferredInit.call(@)

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  #
  # Channels related
  #
  generateServerChannelObject: (channel_type, channel_identifier, user_id) ->
    check user_id, String

    @requireAllowedChannelType(channel_type)
    check channel_identifier, Object

    @requireUserProvided(user_id) # At the moment we don't support generate by the system, so user_id is necessary

    # See both/static-channel-registrar.coffee
    channel_constructor_name = channel_type_to_channels_constructors[channel_type].server

    conf = {
      justdo_chat: @
      performing_user: user_id
      channel_identifier: channel_identifier
    }

    return new share[channel_constructor_name](conf)

  markAllChannelsAsRead: (user_id) ->
    check user_id, String

    if not user_id? or _.isEmpty user_id
      @logger.warn "Empty user_id provided, it should never happen!"

      return

    #
    # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
    # and to drop obsolete indexes (see USER_UNREAD_MESSAGES_INDEX there)
    #
    query = 
      subscribers:
        $elemMatch:
          user_id: user_id
          unread: true

    update =
      $set:
        "subscribers.$.unread": false
        "subscribers.$.last_read": new Date()

    options =
      multi: true

    @channels_collection.rawCollection().update query, update, options

    return

  #
  # Unread subscribed channels related
  #
  _getSubscribedUnreadChannelsOptionsSchema: new SimpleSchema
    user_id:
      type: String
    fields:
      type: Object
      blackbox: true
    limit:
      type: Number

      defaultValue: default_subscribed_unread_channels_limit

      max: 1000
  _getSubscribedUnreadChannelsCursor: (options) ->
    # Returns a cursor for unread channels subscribed by options.user_id, sorted by last
    # activity (DESC).

    # Note, we intentionally not receiving the user_id as last arg, this method should
    # be used internally, and taking user_id as last argument might encourage someone to expose
    # it. (D.C)

    if not options?
      options = {}

    options_schema = @_getChannelsRecentActivityCursorOptionsSchema._schema
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_getSubscribedUnreadChannelsOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    #
    # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
    # and to drop obsolete indexes (see USER_UNREAD_MESSAGES_INDEX there)
    #

    subscribed_unread_channels_cursor_query =
      subscribers:
        $elemMatch:
          user_id: options.user_id
          unread: true

    subscribed_unread_channels_cursor_options =
      limit: options.limit
      sort:
        last_message_date: -1

    if options.fields?
      subscribed_unread_channels_cursor_options.fields = options.fields

    return @channels_collection.find subscribed_unread_channels_cursor_query, subscribed_unread_channels_cursor_options

  subscribedUnreadChannelsCountPublicationHandler: (publish_this, user_id) ->
    check user_id, String

    #
    # Get the recent activity channels
    #
    subscribed_unread_channels_cursor = @_getSubscribedUnreadChannelsCursor
      limit: 999
      user_id: user_id
      fields:
        _id: 1

    # Get last message
    # Get channel specific augmented info.
    jdc_info_collection_name = JustdoChat.jdc_info_pseudo_collection_name

    count = 0
    initial = true
    subscribed_unread_channels_count_tracker = subscribed_unread_channels_cursor.observeChanges
      added: (id, data) ->
        count += 1

        if not initial
          publish_this.changed jdc_info_collection_name, "subscribed_unread_channels_count", {count: count}

        return

      removed: (id) ->
        count -= 1

        if not initial
          publish_this.changed jdc_info_collection_name, "subscribed_unread_channels_count", {count: count}

        return

    initial = false
    publish_this.added jdc_info_collection_name, "subscribed_unread_channels_count", {count: count}

    #
    # onStop setup + ready()
    #
    publish_this.onStop ->
      subscribed_unread_channels_count_tracker.stop()

      return

    publish_this.ready()

    return

  #
  # Subscribed channels recent activity related
  #
  _getChannelsRecentActivityCursorOptionsSchema: new SimpleSchema
    user_id:
      type: String
    fields:
      type: Object
      blackbox: true
    limit:
      type: Number

      defaultValue: default_subscribed_channels_recent_activity_limit

      max: 1000
  _getSubscribedChannelsRecentActivityCursor: (options) ->
    # Returns a cursor for channels recent activity for options.user_id, sorted by last
    # activity (DESC).

    # Note, we intentionally not receiving the user_id as last arg, this method should
    # be used internally, and taking user_id as last argument might encourage someone to expose
    # it. (D.C)

    if not options?
      options = {}

    options_schema = @_getChannelsRecentActivityCursorOptionsSchema._schema
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_getChannelsRecentActivityCursorOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    #
    # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
    # and to drop obsolete indexes (see USER_UNREAD_MESSAGES_INDEX there)
    #
    # NOTE: the following uses a subset of the USER_UNREAD_MESSAGES_INDEX index.
    channels_recent_activity_cursor_query =
      "subscribers.user_id": options.user_id

    channels_recent_activity_cursor_options =
      limit: options.limit
      sort:
        last_message_date: -1

    if options.fields?
      channels_recent_activity_cursor_options.fields = options.fields

    return @channels_collection.find channels_recent_activity_cursor_query, channels_recent_activity_cursor_options

  _subscribedChannelsRecentActivityPublicationHandlerOptionsSchema: new SimpleSchema
    limit:
      type: Number

      defaultValue: default_subscribed_channels_recent_activity_limit

      max: 1000
  subscribedChannelsRecentActivityPublicationHandler: (publish_this, options, user_id) ->
    # !!! IMPORTANT !!!
    # Documentation for this handler is maintained under publications.coffee (jdcSubscribedChannelsRecentActivity)
    # reading the docs there is essential to understanding this handler and its security model
    # KEEP IT UPDATED if you change behavior below!
    # !!! IMPORTANT !!!

    self = @

    check user_id, String

    if not options?
      options = {}

    options_schema = @_subscribedChannelsRecentActivityPublicationHandlerOptionsSchema._schema
    if (pre_validation_limit = options?.limit)?
      if pre_validation_limit > (max_limit = options_schema.limit.max)
        # Just to provide a more friendly error message for that case (v.s the one simple schema will throw)
        throw @_error "invalid-options", "Can't subscribe to more than #{max_limit} channels recent activity entries"

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_subscribedChannelsRecentActivityPublicationHandlerOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    #
    # Get the recent activity channels
    #

    # If you change published fields, update comment under publications.coffee
    fields_to_fetch =
      _id: 1
      subscribers: 1
      channel_type: 1
      last_message_date: 1 # We don't publish this field, we observe it to keep the published message
                           # for this channel up-to-date.

    for field_id in @getAllTypesIdentifiyingAndAugmentedFields()
      fields_to_fetch[field_id] = 1

    subscribed_channels_recent_activity_cursor = @_getSubscribedChannelsRecentActivityCursor
      limit: options.limit
      user_id: user_id
      fields: fields_to_fetch

    # See comment under publications.coffee for why we use pseudo collection name
    # here. (under jdcSubscribedChannelsRecentActivity)
    recent_activity_channels_collection_name =
      JustdoChat.jdc_recent_activity_channels_collection_name
    recent_activity_messages_collection_name =
      JustdoChat.jdc_recent_activity_messages_collection_name
    recent_activity_authors_details_collection_name =
      JustdoChat.jdc_recent_activity_authors_details_collection_name

    channels_skipped_due_to_failed_auth = {} # hash is used for O(1) search
    supplement_data_sent_by_channel_id = {}
    # supplement_data_sent_by_channel_id structure is as follows:
    # 
    # {
    #   channel_id: {
    #     unread_state: true/false # used to determine whether to send update to the unread property following update to the subscribers sub-document
    #     last_message_id: last_message_id
    #     last_message_author_id: the user id of the author of the last message, used maintain authors_details_sent
    #     type_specific_docs: [[collection_id, doc_id], [collection_id, doc_id], ...]
    #   }
    # }
    channel_objs_by_channel_id = {} # Cache the channel_objs created in the added phase.
    authors_details_sent = {} # holds the authors to which we sent details about, details include, first name, last name, user avatar
                              # structure:
                              # {
                              #   user_id: count of messages in the publication that had him as author
                              # }

    reportAuthorDetailsNotRequired = (author_id) ->
      authors_details_sent[author_id] -= 1 # We assume that if an author is reported to be not required any longer, he was reported before to be required.

      if authors_details_sent[author_id] == 0
        # No one need the details about the previous channel.
        delete authors_details_sent[author_id]

        publish_this.removed recent_activity_authors_details_collection_name, author_id

      return

    reportAuthorDetailsRequired = (author_id) ->
      if not authors_details_sent[author_id]?
        authors_details_sent[author_id] = 1

        publish_this.added recent_activity_authors_details_collection_name, author_id, Meteor.users.findOne(author_id, {fields: published_recent_activity_authors_details_fields})
      else 
        authors_details_sent[author_id] += 1

      return

    recent_activity_channels_tracker = subscribed_channels_recent_activity_cursor.observeChanges
      added: (channel_id, data) ->
        #
        # Begin by creating a channel object based on the channel doc.
        # The process of creating a channel object involves verification that the user has authorization
        # to access the channel. If the user doesn't have access we remove him from the subscribers array
        # for the channel.
        #
        # IMPORTANT Relying on the fact that user is subscribed to a channel is not enough!!!
        #

        channel_type = data.channel_type

        # pick identifying fields
        channel_identifying_fields = _.pick data, self.getTypeIdentifiyingFields(channel_type)

        try
          channel_obj = self.generateServerChannelObject(channel_type, channel_identifying_fields, user_id)
          channel_objs_by_channel_id[channel_id] = channel_obj
        catch e
          self.logger.warn "subscribedChannelsRecentActivityPublicationHandler: channel #{channel_id} skipped for user #{user_id} due to lack of authorization"

          # Remove the user from the channel subscribers list, it is very likely that we got this situation
          # due to mongo non-transactional nature, we fix the mismatch here.
          update =
            $pull:
              subscribers:
                user_id: user_id

          # rawCollection is used since the update is to complex for Simple Schema
          self.channels_collection.rawCollection().update {_id: channel_id}, update

          channels_skipped_due_to_failed_auth[channel_id] = true

          return

        # Find the unread state for the logged-in user, and publish only that info
        # under the unread property.
        #
        # If you change this behavior, or properties names, please update comment under
        # publications.coffee
        subscribers = data.subscribers
        for subscriber in subscribers
          # We assume we will find the user in subscribers list
          if subscriber.user_id == user_id
            if not (unread = subscriber.unread)?
              unread = false

            break

        data.unread = unread
        delete data.subscribers

        publish_this.added recent_activity_channels_collection_name, channel_id, data

        #
        # Get supplement docs
        #
        supplement_data = {
          unread_state: data.unread
          last_message_id: null
          type_specific_docs: []
        }

        if (last_message = self._getChannelLastMessageFromChannelObject(channel_obj, channel_id))?
          publish_this.added recent_activity_messages_collection_name, last_message._id, last_message

          supplement_data.last_message_id = last_message._id

          author_id = last_message.author
          supplement_data.last_message_author_id = author_id

          reportAuthorDetailsRequired(author_id)
        else
          # We shouldn't get here
          self.logger.warn "subscribedChannelsRecentActivityPublicationHandler: couldn't find last message for channel #{channel_id} - this shouldn't happen"

        supplementary_records = channel_obj.getChannelRecentActivitySupplementaryDocs()

        for supplementary_record in supplementary_records
          [collection_id, doc_id, doc] = supplementary_record

          publish_this.added collection_id, doc_id, doc

          supplement_data.type_specific_docs.push [collection_id, doc_id]

        supplement_data_sent_by_channel_id[channel_id] = supplement_data

        return

      changed: (channel_id, data) ->
        if channels_skipped_due_to_failed_auth[channel_id]
          # We skipped this channel publication, no need to react to changes

          return

        channel_obj = channel_objs_by_channel_id[channel_id]

        # Watch for changes in the last_message_date to keep the user up-to-date with
        # the most recent message available for the channel.
        if data.last_message_date?
          # Remove obsolete last_message, publish new last_message
          if (last_message_id = supplement_data_sent_by_channel_id[channel_id].last_message_id)?
            publish_this.removed recent_activity_messages_collection_name, last_message_id

            # We set for null, for the rare case, we won't be able to fetch the new last_message_id
            # nd end up with wrong pointer to doc already not part of publication.
            supplement_data_sent_by_channel_id[channel_id].last_message_id = null

          # Add last_message, and update supplement_data
          if (last_message = self._getChannelLastMessageFromChannelObject(channel_obj, channel_id))?
            publish_this.added recent_activity_messages_collection_name, last_message._id, last_message

            supplement_data_sent_by_channel_id[channel_id].last_message_id = last_message._id
          else
            # We shouldn't get here
            self.logger.warn "subscribedChannelsRecentActivityPublicationHandler: couldn't find last message for channel #{channel_id} - this shouldn't happen"

          new_message_author_id = last_message.author
          previous_message_author_id = supplement_data_sent_by_channel_id[channel_id].last_message_author_id
          supplement_data_sent_by_channel_id[channel_id].last_message_author_id = new_message_author_id
          if new_message_author_id != previous_message_author_id
            # The author of the last message for this channel changed.
            # We need to update the publication with the details about the new author, if
            # we haven't published it already for another channel.
            # In addition we need to remove from the publication the details about the previous
            # author if it isn't needed for any channel any longer.
            reportAuthorDetailsNotRequired(previous_message_author_id)
            reportAuthorDetailsRequired(new_message_author_id)

        #
        # Maintain unread state / Remove subscribers sub-document from updates (we don't publish it)
        #
        if (subscribers = data.subscribers)?
          for subscriber in subscribers
            # We assume we will find the user in subscribers list
            if subscriber.user_id == user_id
              if not (new_unread_state = subscriber.unread)?
                new_unread_state = false

              break

          # console.log "NEW UNREAD STATE", new_unread_state, supplement_data_sent_by_channel_id[channel_id].unread_state

          if new_unread_state != supplement_data_sent_by_channel_id[channel_id].unread_state
            data.unread = new_unread_state

            supplement_data_sent_by_channel_id[channel_id].unread_state = new_unread_state

          delete data.subscribers # We don't publish this field

        if not _.isEmpty data
          publish_this.changed recent_activity_channels_collection_name, channel_id, data

        return

      removed: (channel_id) ->
        if channels_skipped_due_to_failed_auth[channel_id]
          # We skipped this channel publication, no need to publish removed

          delete channels_skipped_due_to_failed_auth[channel_id]

          return

        publish_this.removed recent_activity_channels_collection_name, channel_id

        supplement_data_sent = supplement_data_sent_by_channel_id[channel_id]
        if (last_message_id = supplement_data_sent.last_message_id)?
          publish_this.removed recent_activity_messages_collection_name, last_message_id

        if (last_message_author_id = supplement_data_sent.last_message_author_id)?
          reportAuthorDetailsNotRequired(last_message_author_id)

        for record in supplement_data_sent.type_specific_docs
          [record_col, record_id] = record

          publish_this.removed record_col, record_id

        # Remove all supplement_data_sent_by_channel_id
        delete channel_objs_by_channel_id[channel_id]
        delete supplement_data_sent_by_channel_id[channel_id]

        return

    getChannelsRecentActivityCount = -> subscribed_channels_recent_activity_cursor.count()

    jdc_info_collection_name = JustdoChat.jdc_info_pseudo_collection_name

    last_count_reported = getChannelsRecentActivityCount()
    publish_this.added jdc_info_collection_name, "subscribed_channels_recent_activity_count", {count: last_count_reported}

    subscribed_channels_recent_activity_count_calculator_interval = Meteor.setInterval ->
      new_count = getChannelsRecentActivityCount()

      if last_count_reported != new_count
        publish_this.changed jdc_info_collection_name, "subscribed_channels_recent_activity_count", {count: new_count}

        last_count_reported = new_count

    , 15 * 1000

    #
    # onStop setup + ready()
    #
    publish_this.onStop ->
      recent_activity_channels_tracker.stop()

      Meteor.clearInterval subscribed_channels_recent_activity_count_calculator_interval
      # On stop, Meteor's DDP layer, will take of removing subscribed_channels_recent_activity_count, no need to do it ourself

      return

    publish_this.ready()

    return

  #
  # Bottom windows related
  #
  _getBottomWindowsChannelsCursorOptionsSchema: new SimpleSchema
    user_id:
      type: String
    fields:
      type: Object
      blackbox: true
    limit:
      type: Number

      defaultValue: default_subscribed_channels_recent_activity_limit

      max: 1000
  _getBottomWindowsChannelsCursor: (options) ->
    # Returns a cursor for channels for which user_id has bottom windows for, sorted by their order (ASC)

    # Note, we intentionally not receiving the user_id as last arg, this method should
    # be used internally, and taking user_id as last argument might encourage someone to expose
    # it. (D.C)

    if not options?
      options = {}

    options_schema = @_getBottomWindowsChannelsCursorOptionsSchema._schema
    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_getBottomWindowsChannelsCursorOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    #
    # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
    # and to drop obsolete indexes (see USER_BOTTOM_WINDOWS_INDEX there)
    #
    # NOTE: the following uses a subset of the USER_BOTTOM_WINDOWS_INDEX index.
    bottom_windows_channels_cursor_query =
      "bottom_windows.user_id": options.user_id

    bottom_windows_channels_cursor_options =
      limit: options.limit
      sort:
        "bottom_windows.order": 1

    if options.fields?
      bottom_windows_channels_cursor_options.fields = options.fields

    return @channels_collection.find bottom_windows_channels_cursor_query, bottom_windows_channels_cursor_options


  _bottomWindowsPublicationHandlerOptionsSchema: new SimpleSchema
    limit:
      type: Number

      defaultValue: default_bottom_windows_limit

      max: default_bottom_windows_limit
  bottomWindowsPublicationHandler: (publish_this, options, user_id) ->
    # !!! IMPORTANT !!!
    # Documentation for this handler is maintained under publications.coffee (jdcBottomWindows)
    # reading the docs there is essential to understanding this handler and its security model
    # KEEP IT UPDATED if you change behavior below!
    # !!! IMPORTANT !!!

    self = @

    check user_id, String

    if not options?
      options = {}

    options_schema = @_bottomWindowsPublicationHandlerOptionsSchema._schema
    if (pre_validation_limit = options?.limit)?
      if pre_validation_limit > (max_limit = options_schema.limit.max)
        # Just to provide a more friendly error message for that case (v.s the one simple schema will throw)
        throw @_error "invalid-options", "Can't subscribe to more than #{max_limit} bottom windows entries"

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_bottomWindowsPublicationHandlerOptionsSchema,
        options,
        {self: @, throw_on_error: true}
      )
    options = cleaned_val

    #
    # Get the bottom windows channels
    #

    # If you change published fields, update comment under publications.coffee
    fields_to_fetch =
      _id: 1
      subscribers: 1
      bottom_windows: 1
      channel_type: 1

    for field_id in @getAllTypesIdentifiyingAndAugmentedFields()
      fields_to_fetch[field_id] = 1

    bottom_windows_channels_cursor = @_getBottomWindowsChannelsCursor
      limit: options.limit
      user_id: user_id
      fields: fields_to_fetch

    # See comment under publications.coffee for why we use pseudo collection name
    # here. (under jdcBottomWindows)
    bottom_windows_channels_collection_name =
      JustdoChat.jdc_bottom_windows_channels_collection_name

    channels_skipped_due_to_failed_auth = {} # hash is used for O(1) search
    supplement_data_sent_by_channel_id = {}
    # supplement_data_sent_by_channel_id structure is as follows:
    # 
    # {
    #   channel_id: {
    #     unread_state: true/false # used to determine whether to send update to the unread property following update to the subscribers sub-document
    #     window_state: "open"/"min"
    #     order: Number
    #     type_specific_docs: [[collection_id, doc_id], [collection_id, doc_id], ...]
    #   }
    # }
    channel_objs_by_channel_id = {} # Cache the channel_objs created in the added phase.

    bottom_windows_channels_tracker = bottom_windows_channels_cursor.observeChanges
      added: (channel_id, data) ->
        #
        # Begin by creating a channel object based on the channel doc.
        # The process of creating a channel object involves verification that the user has authorization
        # to access the channel. If the user doesn't have access we remove him from the bottom_windows array
        # for the channel.
        #
        # IMPORTANT Relying on the fact that user has a bottom window for the channel is not enough!!!
        #

        channel_type = data.channel_type

        # pick identifying fields
        channel_identifying_fields = _.pick data, self.getTypeIdentifiyingFields(channel_type)

        try
          channel_obj = self.generateServerChannelObject(channel_type, channel_identifying_fields, user_id)
          channel_objs_by_channel_id[channel_id] = channel_obj
        catch e
          self.logger.warn "bottomWindowsPublicationHandler: channel #{channel_id} skipped for user #{user_id} due to lack of authorization"

          # Remove the user from the bottom_windows array, it is very likely that we got this situation
          # due to mongo non-transactional nature, we fix the mismatch here.
          update =
            $pull:
              bottom_windows:
                user_id: user_id

          # rawCollection is used since the update is to complex for Simple Schema
          self.channels_collection.rawCollection().update {_id: channel_id}, update

          channels_skipped_due_to_failed_auth[channel_id] = true

          return

        # Find the unread state for the logged-in user, and publish only that info
        # under the unread property.
        #
        # If you change this behavior, or properties names, please update comment under
        # publications.coffee
        data.unread = false # Note, unlike, subscribedChannelsRecentActivityPublicationHandler
                            # for the bottomWindowsPublicationHandler, a bottom window doesn't
                            # imply user is subscribed, so we might not find the performing_user
                            # under subscribers, it changes the loop slightly.
        subscribers = data.subscribers
        for subscriber in subscribers
          if subscriber.user_id == user_id
            if not (unread = subscriber.unread)?
              unread = false

            data.unread = unread

            break

        delete data.subscribers # We don't publish the full subscribers list for this publication

        bottom_windows = data.bottom_windows
        for bottom_window in bottom_windows
          # We assume we will find the user in bottom_windows list
          if bottom_window.user_id == user_id
            if not (state = bottom_window.state)?
              state = JustdoChat.schemas.BottomWindowSchema._schema.state.defaultValue

            if not (order = bottom_window.order)?
              order = JustdoChat.schemas.BottomWindowSchema._schema.order.defaultValue

            data.state = state
            data.order = order

            break

        delete data.bottom_windows # We don't publish the full bottom_windows list for this publication

        publish_this.added bottom_windows_channels_collection_name, channel_id, data

        #
        # Get supplement docs
        #
        supplement_data = {
          unread_state: data.unread
          state: data.state
          order: data.order
          type_specific_docs: []
        }

        supplementary_records = channel_obj.getBottomWindowsChannelsSupplementaryDocs()

        for supplementary_record in supplementary_records
          [collection_id, doc_id, doc] = supplementary_record

          publish_this.added collection_id, doc_id, doc

          supplement_data.type_specific_docs.push [collection_id, doc_id]

        supplement_data_sent_by_channel_id[channel_id] = supplement_data

        return

      changed: (channel_id, data) ->
        if channels_skipped_due_to_failed_auth[channel_id]
          # We skipped this channel publication, no need to react to changes

          return

        channel_obj = channel_objs_by_channel_id[channel_id]

        #
        # Maintain unread state / Remove subscribers sub-document from updates (we don't publish it)
        #
        new_unread_state = false
        if (subscribers = data.subscribers)?
          for subscriber in subscribers
            # We don't assume we will find the user in subscribers list
            if subscriber.user_id == user_id
              if not (new_unread_state = subscriber.unread)?
                new_unread_state = false

              break

          # console.log "NEW UNREAD STATE", new_unread_state, supplement_data_sent_by_channel_id[channel_id].unread_state

          if new_unread_state != supplement_data_sent_by_channel_id[channel_id].unread_state
            data.unread = new_unread_state

            supplement_data_sent_by_channel_id[channel_id].unread_state = new_unread_state

          delete data.subscribers # We don't publish this field


        #
        # Maintain order/staete , Remove bottom_windows sub-document from updates (we don't publish it)
        #
        new_state = JustdoChat.schemas.BottomWindowSchema._schema.state.defaultValue
        new_order = JustdoChat.schemas.BottomWindowSchema._schema.order.defaultValue
        if (bottom_windows = data.bottom_windows)?
          for bottom_window in bottom_windows
            # We assume we will find the user in the bottom_windows list
            if bottom_window.user_id == user_id
              if bottom_window.state?
                new_state = bottom_window.state

              if bottom_window.order?
                new_order = bottom_window.order

              break

          if new_state != supplement_data_sent_by_channel_id[channel_id].state
            data.state = new_state

            supplement_data_sent_by_channel_id[channel_id].state = new_state

          if new_order != supplement_data_sent_by_channel_id[channel_id].order
            data.order = new_order

            supplement_data_sent_by_channel_id[channel_id].order = new_order

          delete data.bottom_windows # We don't publish this field

        if not _.isEmpty data
          publish_this.changed bottom_windows_channels_collection_name, channel_id, data

        return

      removed: (channel_id) ->
        if channels_skipped_due_to_failed_auth[channel_id]
          # We skipped this channel publication, no need to publish removed

          delete channels_skipped_due_to_failed_auth[channel_id]

          return

        publish_this.removed bottom_windows_channels_collection_name, channel_id

        supplement_data_sent = supplement_data_sent_by_channel_id[channel_id]

        for record in supplement_data_sent.type_specific_docs
          [record_col, record_id] = record

          publish_this.removed record_col, record_id

        # Remove all supplement_data_sent_by_channel_id
        delete channel_objs_by_channel_id[channel_id]
        delete supplement_data_sent_by_channel_id[channel_id]

        return

    #
    # onStop setup + ready()
    #
    publish_this.onStop ->
      bottom_windows_channels_tracker.stop()

      return

    publish_this.ready()

    return

  # The result shouldn't change during the instance lifetime, so we can cache it
  _getAllTypesIdentifiyingAndAugmentedFields_cached_result: null
  getAllTypesIdentifiyingAndAugmentedFields: ->
    if @_allTypesIdentifiyingAndAugmentedFields_cached_result?
      return @_allTypesIdentifiyingAndAugmentedFields_cached_result

    result = []
    for channel_type, channel_type_conf of share.channel_types_conf
      result = result.concat channel_type_conf.channel_identifier_fields_simple_schema._schemaKeys
      result = result.concat channel_type_conf.channel_augemented_fields_simple_schema._schemaKeys

    @_allTypesIdentifiyingAndAugmentedFields_cached_result = result

    return @_allTypesIdentifiyingAndAugmentedFields_cached_result

  # The result shouldn't change during the instance lifetime, so we can cache it
  _getAllTypesIdentifiyingAndAugmentedFields_cached_result: null
  getAllTypesIdentifiyingAndAugmentedFields: ->
    if @_allTypesIdentifiyingAndAugmentedFields_cached_result?
      return @_allTypesIdentifiyingAndAugmentedFields_cached_result

    result = []
    for channel_type, channel_type_conf of share.channel_types_conf
      result = result.concat @getTypeIdentifiyingFields(channel_type)
      result = result.concat channel_type_conf.channel_augemented_fields_simple_schema._schemaKeys

    @_allTypesIdentifiyingAndAugmentedFields_cached_result = result

    return @_allTypesIdentifiyingAndAugmentedFields_cached_result

  _getChannelLastMessageFromChannelObject: (channel_obj, channel_id) ->
    last_message_cursor = channel_obj._getChannelMessagesCursor
      channel_id: channel_id
      limit: 1
      fields:
        channel_id: 1
        body: 1
        author: 1
        createdAt: 1

    return last_message_cursor.fetch()?[0]

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    _.each @_on_destroy_procedures, (proc) -> proc()

    @destroyed = true

    @logger.debug "Destroyed"

    return