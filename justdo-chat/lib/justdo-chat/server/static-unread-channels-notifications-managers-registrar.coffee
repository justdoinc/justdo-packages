# Reading README-notification-system.md is essential to understand this file

regeneratorRuntime = require("babel-runtime/regenerator")

share.unread_channels_notifications_conf = {}

_.extend JustdoChat,
  #
  # Involuntarily unread channels notifications related
  #
  _registerUnreadChannelsNotificationsManagerConfSchema: new SimpleSchema
    notification_type:
      # should be dash-separated unique id for this notification type
      # e.g. 'email', 'android-pn'.
      type: String

    processed_notifications_indicator_field_name:
      # The name of the 'Unread Notification Type Indicator Field' field in the subscriber object
      # Read more about its function in README-notification-system.md
      #
      # You must define that field in the JustdoChat.schemas.SubscribedUserSchema see both/schams.coffee
      # as an optional Date (an exception will be thrown otherwise).
      #
      # If not define we will assume the default: "unread_#{notification_type}_processed"

      type: String

      autoValue: ->
        return "unread_#{JustdoHelpers.dashSepTo("_", @field("notification_type").value)}_processed"

      optional: true

    # JustDo jobs processor related
    justdo_jobs_processor_job_id:
      # The job-id that will be given to the JustDo job processor that we will set to take charge of
      # processing this notification.
      #
      # If not set we will use: "justdo-chat-#{notification_type}-notifications"

      type: String

      autoValue: ->
        return "justdo-chat-#{@field("notification_type").value}-notifications"

      optional: true

    polling_interval_ms:
      # How long in miliseconds to wait between the time one polling completes processing till
      # we query the db again for the Handling Criteria (see README-notification-system.md)
      #
      # Note, one polling will never start before the previous one completed processing, so no need to
      # worry about duplicate processing in the same instance.
      type: Number
    min_unread_period_ms:
      # The time in ms a channel needs to be in an involuntary unread state for a subscriber to be
      # candidate for unread notification processing by this unread notifications manager.
      type: Number
    # min_time_before_notifying_additional_unread_message_ms:
    #   # The time in miliseconds we will wait before notifying the user about additional
    #   # message that received for a channel we already sent an unread notification for.
    #   #
    #   # null means we will never notify again for the same channel, until the user read it.
    #   # 0 means we don't wait at all, notifications will be sent immediately as polling the
    #   # db (that happens every polling_interval_ms) shows we need to send them.
    #   type: Number

    #   optional: true

    #   defaultValue: null

    is_user_configurable_notification:
      # Set to true if the user can disable/enable this notification type notifications
      type: Boolean

      defaultValue: false
    user_configuration_field:
      # Relevant only if is_user_configurable_notification is true.
      #
      # The name of the field in the user doc in which we specify whether or not
      # this notification type is enabled for the user. If stored in a sub-document use the
      # dot notation: e.g, "conf.x"
      #
      # If not set we will use: "justdo_chat.#{notification_type}_notifications"
      type: String

      autoValue: ->
        return "justdo_chat.#{JustdoHelpers.dashSepTo("_", @field("notification_type").value)}_notifications"

      optional: true
    user_configuration_field_type:
      # Relevant only if user field isn't defined already when we register the notification type,
      # in such a case we define the field in the registration process setting it to the
      # specified type
      type: "skip-type-check"

      defaultValue: Boolean
    user_configuration_field_allowedValues:
      # Relevant only if user field isn't defined already when we register the notification type,
      # in such a case we define the field in the registration process setting it with the specified
      # allowedValues
      type: ["skip-type-check"]

      optional: true
    user_configuration_field_defaultValue:
      # If a user doesn't have the field set in its doc, we will use the defaultValue as the value for
      # the user.
      #
      # If user field isn't defined already when we register the notification type we will define it
      # with the defined defaultValue
      type: "skip-type-check"

      defaultValue: true
    user_configuration_field_enabled_value:
      # The value of user_configuration_field for which we regard the user as enabled for this notification
      # type.
      type: "skip-type-check"

      defaultValue: true

    new_subscribers_notifications:
      # Set to true if new subscribers should get an unread notification when added to a channel.
      # Notifications will be sent in accordance to the new_subscribers_notifications_threshold_ms
      # and option below.
      type: Boolean

      defaultValue: false

    new_subscribers_notifications_threshold_ms:
      # A notification will be sent to the subscriber only if the channel has messages that been sent
      # in the last previous X miliseconds before the channel became unread involuntarily.
      type: Number

      defaultValue: 1000 * 60 * 10 # 10 minutes

    new_subscribers_notifications_max_messages:
      # How many messages to include in the notification to newly added subscribers?

      defaultValue: 10

      type: Number

    sendNotificationCb:
      # XXX TBD Receives a channel to process
      type: Function
  registerUnreadChannelsNotificationsManager: (conf) ->
    # Notification type 

    # defaults =
    #   processed_notifications_indicator_field_name: "unread_#{notification_type}_processed"
    #   justdo_jobs_processor_job_id: "justdo-chat-#{notification_type}-notifications"
    #   user_configuration_field: "justdo_chat.#{notification_type}_notifications"

    if not conf?
      conf = {}

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_registerUnreadChannelsNotificationsManagerConfSchema,
        conf,
        {self: @, throw_on_error: true}
      )
    conf = cleaned_val

    #
    # Ensure required field in the subscriber schema is defined
    #
    subscribers_schema_def =
      JustdoHelpers.getSimpleSchemaObjDefinition(JustdoChat.schemas.SubscribedUserSchema)

    if not subscribers_schema_def[conf.processed_notifications_indicator_field_name]?
      throw new Meteor.Error "missing-schema-field", "JustdoChat.registerUnreadChannelsNotificationsManager: a field is missing from the subscribers schema. Please define '#{conf.processed_notifications_indicator_field_name}' as an optional Boolean"

    #
    # Check whether users fields are required and defined in the users collection, define them
    # if they are needed and aren't defined yet.
    #
    if conf.is_user_configurable_notification
      user_configuration_field_is_defined = 
        JustdoHelpers.getCollectionSchemaForField(Meteor.users, conf.user_configuration_field)?

      if not user_configuration_field_is_defined
        user_conf_field_schema = {}

        user_conf_field_schema[conf.user_configuration_field] =
          type: conf.user_configuration_field_type

          defaultValue: conf.user_configuration_field_defaultValue

          optional: true

        if (allowedValues = conf.user_configuration_field_allowedValues)?
          user_conf_field_schema[conf.user_configuration_field].allowedValues = allowedValues

        user_conf_field_schema = new SimpleSchema user_conf_field_schema

        Meteor.users.attachSchema user_conf_field_schema

    # Define the job we will register on @_setupUnreadChannelsNotificationsJobs() see jobs-definitions.coffee
    conf.job = ->
      # Assume @ is the justdo_chat object, actual registration is happening under jobs-definitions.coffee

      justdo_chat = @

      proc = =>
        proc_date = new Date()

        min_iv_unread = JustdoHelpers.getDateMsOffset(-1 * conf.min_unread_period_ms, proc_date)

        # justdo_chat.logger.info "Unread channels notifications - #{conf.notification_type} - min_iv_unread: #{min_iv_unread} - BEGIN"

        subscriber_element_matching_criteria =
          iv_unread:
            $lte: min_iv_unread
          "#{conf.processed_notifications_indicator_field_name}": null

        fields_to_fetch =
          _id: 1
          channel_type: 1
          subscribers: 1

        for field_id in justdo_chat.getAllTypesIdentifiyingAndAugmentedFields()
          fields_to_fetch[field_id] = 1

        #
        # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
        # and to drop obsolete indexes (see INVOLUNTARY_UNREAD_NOTIFICATIONS_HANDLING_CRITERIA there)
        #
        channels_with_subscribers_need_processing_cursor = justdo_chat.channels_collection.find
            subscribers:
              $elemMatch: subscriber_element_matching_criteria
          ,
            fields: fields_to_fetch

        isSubscriberCandidateForProcessing = (subscriber_doc) ->
          # Returns true if the subscriber is candidate for processing
          # in this cycle.

          if subscriber_doc[conf.processed_notifications_indicator_field_name]?
            return false

          if not (iv_unread = subscriber_doc.iv_unread)?
            return false

          if iv_unread > min_iv_unread
            return false

          return true

        # We cache the fetched users obj in the job level, so each user will be fetched up to one
        # time per job.
        _users_docs_cache = {}
        getUsersDocs = (users_array) ->
          # We fetch users docs for various reasons in the job, e.g.:
          #
          # * Check whether a user is subscribed for the notification type
          # * Check subscribed user email to send notification to - for the email notification
          # * Print details about messages authors next to the messages included in the email
          #
          # etc.
          #
          # We fetch here, for the users_array, all the potential fields that we might need in this job
          # and cache the result. So for the lifetime of a job, for all the purposes we need a user's
          # details from the db, we will fetch all in one call.

          need_fetch_from_db = []

          for user_id in users_array
            if user_id of _users_docs_cache
              yield _users_docs_cache[user_id]
            else
              need_fetch_from_db.push user_id

          if not _.isEmpty need_fetch_from_db
            for user_doc in APP.accounts.fetchPublicBasicUsersInfo(need_fetch_from_db, {additional_fields: {"#{conf.user_configuration_field}": 1}})
              _users_docs_cache[user_doc._id] = user_doc

              yield user_doc

          return

        getUserDoc = (user_id) ->
          if user_id of _users_docs_cache
            return _users_docs_cache[user_id]

          user_doc = APP.accounts.findOnePublicBasicUserInfo(user_id, {additional_fields: {"#{conf.user_configuration_field}": 1}})

          _users_docs_cache[user_id] = user_doc

          return user_doc

        # We cache the enabled subscribers in the job level (we check whether notifications are enabled for a user
        # only once per job run)
        _subscribers_enabled_state_cache = {}
        getSubscribersWithEnabledNotification = (subscribers_ids) ->
          if not conf.is_user_configurable_notification
            # Users can't opt-out of this notifications, return all subscribers
            return subscribers_ids

          enabled_subscribers = []
          subscribers_need_check_with_mongo = []
          for subscriber_id in subscribers_ids
            if not (is_enabled = _subscribers_enabled_state_cache[subscriber_id])?
              subscribers_need_check_with_mongo.push subscriber_id

              continue

            if is_enabled
              enabled_subscribers.push subscriber_id

          if subscribers_need_check_with_mongo.length > 0
            # Returns only the subscribers for which this notification type is enabled.
            user_configuration_field_path_array = conf.user_configuration_field.split(".")

            for user_doc from getUsersDocs(subscribers_need_check_with_mongo)
              val_returned_by_mongo = user_doc
              for node in user_configuration_field_path_array
                if not (val_returned_by_mongo = val_returned_by_mongo[node])?
                  break

              if val_returned_by_mongo?
                enabled_value = val_returned_by_mongo
              else
                enabled_value = conf.user_configuration_field_defaultValue

              _subscribers_enabled_state_cache[user_doc._id] =
                conf.user_configuration_field_enabled_value == enabled_value

              if _subscribers_enabled_state_cache[user_doc._id]
                enabled_subscribers.push user_doc._id

          return enabled_subscribers

        job_storage = {} # A storage shared among all the calls to conf.sendNotificationCb for this job
                         # run.
                         #
                         # It should be used by sendNotificationCb to avoid redundant calls to the db.

        processed_channels = 0
        notifications_sent = 0
        channel_access_rejected = 0
        channels_with_subscribers_need_processing_cursor.forEach (channel_doc) ->
          processed_channels += 1

          subscribers_need_processing_user_ids = []
          subscribers_need_processing_subscriber_objs = []

          #
          # Find the channel's subscribers that are candidates for processing (those for which the Handling Criteria is true)
          #
          for subscriber in channel_doc.subscribers
            if not isSubscriberCandidateForProcessing(subscriber)
              continue

            subscribers_need_processing_user_ids.push subscriber.user_id
            subscribers_need_processing_subscriber_objs.push subscriber

          subscribers_ids_to_send_notifications_to =
            getSubscribersWithEnabledNotification(subscribers_need_processing_user_ids)

          if subscribers_ids_to_send_notifications_to.length > 0
            # There are subscribers that meets the handling criteria and got the notifications enabled
            # for this notification type

            {channel_type} = channel_doc
            channel_identifier = _.pick channel_doc, justdo_chat.getTypeIdentifiyingFields(channel_type)

            cached_channel_obj = null
            getChannelObjectIfUserPermittedToAccessChannel = (user_id) ->
              # Returns the channel's channel object with the user_id as its @performing_user
              # Returns undefined if any issue occured, including, no access permission.
              #
              # Checking access right for a channel, and later on, retreiving related documents from other
              # collections, involves querying the db. We don't want to query these documents multiple times,
              # but only one per notifications submission loop, here we take care of that.
              #
              # The user ids received here are called from the loop below for subscribers.
              #
              # It is important to remember that subscription doesn't imply access permission.

              try
                if cached_channel_obj?
                  cached_channel_obj.replacePerformingUser(user_id)
                else
                  cached_channel_obj = justdo_chat.generateServerChannelObject(channel_type, channel_identifier, user_id)
              catch e
                console.info "static-unread-channels-notifications-managers-registrar.coffee: getChannelObjectIfUserPermittedToAccessChannel(), user #{user_id} seems to have no access to a channel he's subscribed to: #{channel_doc._id}"

                return undefined

              return cached_channel_obj

            channel_subscribers_loop_storage = {} # A storage shared among all the calls to 
                                                  # conf.sendNotificationCb for the subscribers
                                                  # in the loop below.
                                                  #
                                                  # It should be used by sendNotificationCb to
                                                  # avoid redundant calls to the db.
            for subscriber_obj in subscribers_need_processing_subscriber_objs
              user_id = subscriber_obj.user_id

              if user_id in subscribers_ids_to_send_notifications_to
                # ENSURE ACCESS RIGHT TO CHANNEL FOR EACH SUBSCRIBER
                if not (channel_obj = getChannelObjectIfUserPermittedToAccessChannel(user_id))?
                  channel_access_rejected += 1

                  continue

                # XXX build messages_to_include_in_notification
                # To be implemented in phase 2, fetch in advance x recent messages for all the subscribers
                # in the loop, take a subset of them according to the iv_unread_type and the notification type.

                # Loop to find the message with the earliest iv_unread + check it iv_unread_type
                # use it as the breakpoint for messages fetch.

                # Query augmented docs, according to channel type

                notification_obj =
                  channel_type: channel_type
                  user: getUserDoc(user_id)
                  justdo_chat: justdo_chat
                  channel_obj: channel_obj
                  messages_to_include_in_notification: [] # See XXX above.
                  channel_subscribers_loop_storage: channel_subscribers_loop_storage
                  job_storage: job_storage

                conf.sendNotificationCb notification_obj

          #
          # Mark the job as completed - write the Indicator Field on the processed members
          #

          # Fetch again the channel doc, to get its most recent subscribers field state, to update
          # the processed subscribers with the indicator field flag.
          #
          # We hope that this will be enough to perform the update of the unread fields
          # without losing data written to the subscribers array between the point we received
          # the doc to the point we perform the update.
          #
          # If it was possible, the best thing we could do, would have been to update all the
          # channel subscribers in one call like:
          #
          # { subscribers: { '$elemMatch': { iv_unread: {$lte: min_iv_unread}, unread_email_processed: null } } }
          #
          # For which there is no risk of data loss.
          #
          # But $elemMatch combined with the .$. notation only updates the first item matched and not all
          # of them.
          #
          # Taking the approach of multiple write requests to Mongo, though keeping us safe from data
          # loss, is out of the question as we find it too demanding in terms of resources.
          #
          # Mongo v3.6 , has features that will allow us to do the update in one call without risking
          # data loss.
          #
          # IMPROVEMENT_PENDING_MONGO_MIGRATION

          up_to_date_channel_subscribers_doc = justdo_chat.channels_collection.findOne
              _id: channel_doc._id
            ,
              fields: {subscribers: 1}

          if not up_to_date_channel_subscribers_doc?
            # The channel removed? Unlikely that we'll get here, but if we will, just continue
            console.warn "static-unread-channels-notifications-managers-registrar.coffee: We shouldn't get here!"

            return

          subscribers_to_update = up_to_date_channel_subscribers_doc.subscribers

          channel_subscribers_update_needed = false
          for subscriber_to_update in subscribers_to_update
            if not isSubscriberCandidateForProcessing(subscriber_to_update)
              continue

            channel_subscribers_update_needed = true

            subscriber_to_update[conf.processed_notifications_indicator_field_name] = proc_date

          if channel_subscribers_update_needed
            justdo_chat.channels_collection.rawCollection().update {_id: channel_doc._id}, {$set: {subscribers: subscribers_to_update}}

          return

        if processed_channels > 0
          justdo_chat.logger.info "Unread channels notifications - #{conf.notification_type} - processed_channels: #{processed_channels}; notifications_sent: #{notifications_sent} ; channel_access_rejected: #{channel_access_rejected} - DONE"

        return

      Meteor.setInterval proc, conf.polling_interval_ms

    share.unread_channels_notifications_conf[conf.notification_type] = conf

    return

JustdoChat.registerUnreadChannelsNotificationsManager