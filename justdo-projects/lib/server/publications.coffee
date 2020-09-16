sync_safety_delta_ms = 0 * 60 * 1000 # 0 minutes (We'll see whether this is necessary, I tend to think it isn't -Daniel)
getCurrentSyncTimeWithSafetyDelta = -> new Date(new Date() - sync_safety_delta_ms)

_.extend Projects.prototype,
  _setupPublications: ->
    @_setupUserProjectsPublication()
    @_setupUnmergedUserProjectsTasksPublication()

    # Defined in required-actions.coffee
    # @_setupUserRequiredActionsPublication()

    return

  _setupUserProjectsPublication: ->
    self = @

    guests_published_fields =
      title: 1
      lastTaskSeqId: 1

      "custom_fields": 1
      "removed_custom_fields": 1

      "conf": 1

      "createdAt": 1

    non_guests_published_fields = _.extend {}, guests_published_fields,
      "members.user_id": 1
      "members.is_admin": 1
      "members.is_guest": 1

      "removed_members.user_id": 1

    Meteor.publish "userProjects", (guest_projects=false) -> # Note the use of -> not =>, we need @userId
      if not @userId?
        this.ready() # no projects for anonymous
        return

      if guest_projects
        guests_query =
          members:
            $elemMatch:
              user_id: @userId
              is_guest: true
        
        return self.projects_collection.find(guests_query, {fields: guests_published_fields})
      else
        non_guests_query =
          members:
            $elemMatch:
              user_id: @userId
              $or: [
                {is_guest: false}
                {is_guest: null}
              ]

        return self.projects_collection.find(non_guests_query, {fields: non_guests_published_fields})

    return

  _setupUnmergedUserProjectsTasksPublication: ->
    self = @

    @_grid_data_com.setupTasksAugmentedFieldsPublication()

    @_grid_data_com.setupGridPublication
      name: GridDataCom.helpers.getCollectionUnmergedPubSubName(self.items_collection)
      unmerged_pub: true
      unmergedPublication_options:
        getCollectionItemsIdentifyingCriteria: (subscription_options) ->
          tasks: {project_id: subscription_options.project_id}
        getCollectionsWithPotentialDdpConflicts: (subscription_options) ->
          tasks: true
        getCollectionsWithSyncSupport: (subscription_options) ->
          tasks: true
      middleware_incharge: true
      middleware: (collection, private_data_collection, options, sub_args, query, private_data_query, query_options, private_data_query_options) ->
        publish_this = @

        sub_options = sub_args[0]
        pub_options = sub_args[1] or {}

        # Options:
        #
        # project_id (required String): the project_id to get the
        # tasks for.
        #
        # sync (optional, Date, default false): If provided,
        # We will assume that the requesting client has in his storage
        # documents that changed/created until the point in time provided
        # by sync (we assume that the /_timesync of the app is used to sync
        # the client's time with the servers time for this purpose.)
        #
        # # If sync is provided, behaviour will be as follows:
        #
        #   * Documents that the user becomes aware of - either as a result of creation
        #   or as a result of being added to their members - will be sent with the added
        #   message.
        #
        #   * Documents that been changed since the last sync, will be sent with the changed
        #   message - *with all their fields* and not only the changed fields.
        #
        #   * A removed message will be sent for all the Documents that the user isn't aware of anymore
        #   - either as a result of removal or as a result of being removed from their members.
        #
        # # Clients are assumed to behave as follows to data-inconsistencies - that might happen:
        #
        #   * If the client receives a changed message for a document it didn't have before
        #   it should create that document with all the fields provided in the changed requrest.
        #   * If the client receives an added message for a document it already has - it should
        #   remove the one it has in store, and use the new one instead.
        #   * If the client receives a removed message for a document it doesn't know - it should
        #   simply ignore the request.
        #
        # As such, it should be safe, and it is *encouraged* to send the sync option with a margin
        # of safety of few minutes before the last known point in time, as there should be no adverse
        # effects to the receival of updates the client's storage is already aware of. (Where on the
        # other, hand in-accurate/out of sync sync option might result in invalid data set for the
        # client).
        #
        # IMPORTANT: sync requests doesn't support direct documents removals from the tasks collection!
        # We won't send the removed message for these documents.
        # Ensure that all tasks removal will pass through the before.remove collection hook defined
        # in: grid-data-com-server.coffee
        #
        # # Client implementation notice:
        #
        #   * When a project is removed, don't forget to clear the internal DB from the project tasks!
        #   Distinguish between project removal, and project document removal for case of logging-out
        #   (make a decision for whether you want to keep documents in case of logging-out).
        #   * Provide a mean to 'reset' the local storage (isn't needed on the web if storage
        #   isn't maintained between refreshes).
        #
        # get_parents_as_string (optional Bool, default true): If
        # false by default. If set to true the publication will return for each item
        # a field with the following name and structure:
        # _parents_str: "parent_id_1:order_in_parent_1,parent_id_2:order_in_parent_2,..."
        #
        # # General notes regarding tasks private data docs available under the Changelog
        # of the webapp for version v1.117.0

        {project_id, get_parents_as_string, sync} = sub_options
        # Validate options
        if not project_id?
          throw self._error "missing-argument", "You must specify the list of project_ids you want to subscribe to"
        check project_id, String
        check get_parents_as_string, Match.Maybe(Boolean)
        check sync, Match.Maybe(Date)

        req_user_id = query.users

        query.project_id = project_id
        private_data_query.project_id = project_id
        if not sync?
          sync = getCurrentSyncTimeWithSafetyDelta()

          initial_payload_query = _.extend {}, query
          initial_payload_query.$or = [
            {_raw_updated_date: {$lte: sync}},
            {_raw_updated_date: null}
          ]
          initial_payload_cursor = collection.find initial_payload_query, query_options

          private_data_initial_payload_query = _.extend {}, private_data_query
          private_data_initial_payload_query.$or = [
            {_raw_updated_date: {$lte: sync}},
            {_raw_updated_date: null}
          ]
          private_data_initial_payload_cursor = private_data_collection.find private_data_initial_payload_query, private_data_query_options

        query._raw_updated_date = {$gt: sync}
        private_data_query._raw_updated_date = {$gt: sync}

        #
        # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
        # and to drop obsolete indexes (see
        # FETCH_PROJECT_TASKS_OF_SPECIFIC_USERS_INDEX/FETCH_PROJECT_TASKS_OF_SPECIFIC_USERS_WITH_RAW_UPDATED_DATE_INDEX there)
        #
        cursor = collection.find query, query_options

        #
        # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
        # and to drop obsolete indexes (see
        # FETCH_PROJECT_TASKS_PRIVATE_DATA_OF_SPECIFIC_USER_FROZEN_AWARE_INDEX/FETCH_PROJECT_TASKS_PRIVATE_DATA_OF_SPECIFIC_USER_FROZEN_AWARE_WITH_RAW_UPDATED_DATE_INDEX there)
        #
        private_data_cursor = private_data_collection.find private_data_query, private_data_query_options

        # pub_options.custom_col_name
        target_col_name = JustdoHelpers.getCollectionNameFromCursor(cursor)
        if (custom_col_name = pub_options.custom_col_name)?
          target_col_name = custom_col_name

        # pub_options.label
        label = pub_options.label
        if not label?
          getItemId = (id) ->
            return id
        else
          getItemId = (id) ->
            return "#{id}::#{label}"

        _removeRawFields = (data) ->
          delete data._raw_updated_date
          delete data._raw_added_users_dates
          delete data._raw_removed_users_dates
          delete data._raw_removed_users
          delete data._raw_removed_date

          return

        _removeSecretFields = (data) ->
          # Anything under the _secret is not published
          delete data._secret

          return

        # sub_options.get_parents_as_string
        if not get_parents_as_string? or not get_parents_as_string
          dataMapsExtensions = (id, data, action) ->
            if action == "removed"
              # Nothing to do for removed
              return

            _removeRawFields(data)
            _removeSecretFields(data)

            return

        else
          dependent_field = "parents"
          map = (id, data) ->
            parents = data.parents

            _parents_str = ""

            for parent_id, parent_details of parents
              _parents_str += "#{parent_id}:#{parent_details.order},"

            _parents_str = _parents_str.slice(0, -1)

            return {_parents_str}

          if dependent_field == "_id"
            # Normalize, so we won't need to check both cases.
            dependent_field = "id"

          dataMapsExtensions = (id, data, action) ->
            if action == "removed"
              # Nothing to do for removed
              return

            _removeRawFields(data)
            _removeSecretFields(data)

            if data[dependent_field]? or
                  (dependent_field == "id" and action == "added")
              # id is not part of data, and is always existing, but we will perform
              # map only on "added" if we depend on it
              if (new_data = map(id, data))?
                _.extend data, new_data # note in-place change

            return

        _removePrivateDataDocsRawFields = (data) ->
          delete data._raw_updated_date
          delete data._raw_removed_date

          return

        privateDataMapsExtensions = (id, data, action) ->
          if action == "removed"
            # Nothing to do for removed
            return

          # We don't want the following fields to interfere with the real
          # task collection fields, in addition
          #
          # VERY IMPORTANT the absence of these fields, in particular the
          # project_id, serves us when determining whether only the private
          # fields of a specific task been received by the client (so the task
          # data should be completely ignored, until the rest of the real fields
          # will transmit). Be very careful to change the lines below and
          # consider the impact on others (incl. Mobile) carefully! Daniel C. 
          delete data.user_id
          delete data.task_id
          delete data.project_id

          _removePrivateDataDocsRawFields(data)

          return

        if sync?
          # For sync subscriptions, we setup a tracker, named removed_tracker, that is responsible to:
          #
          # Removed below means: (1) Actual item removal (2) Removal of the user from the item's users
          # field.
          #
          #   1. Send removed messages for all the documents that been removed since
          #   the sync time.
          #   2. Since, the tasks `cursor` below for the main `tracker`, for sync requests,
          #   doesn't return tasks that haven't been modified since sync time, if these tasks
          #   will be removed, it won't trigger for them the removed callback.
          #
          #   We therefore need to track removals. And in order to avoid duplicate removed message
          #   for tasks that changed after sync subscription initial payload got submitted, and
          #   then got removed, we move the full responsibility to send removed messages to
          #   the removed_tracker.

          removed_tasks_collection_query =
            project_id: query.project_id
            _raw_updated_date: {$gt: sync}
            _raw_removed_users: req_user_id

          #
          # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
          # and to drop obsolete indexes (see FETCH_REMOVED_TASKS_OF_SPECIFIC_USERS_INDEX there)
          #
          removed_cursor = collection.find(removed_tasks_collection_query, {fields: {_id: 1, "_raw_removed_users_dates.#{req_user_id}": 1}})
          removed_tracker = removed_cursor.observeChanges
            added: (id, data) ->
              if (user_removed_date = data._raw_removed_users_dates[req_user_id])?
                # If the removed time is known for the user in the data._raw_removed_users_dates[req_user_id]
                # send the removed message only if necessary.
                if sync < user_removed_date
                  publish_this.removed target_col_name, getItemId(id)
              else
                # If the removed time is unknown for the user, send the removed message.
                publish_this.removed target_col_name, getItemId(id)

              return

          # END if sync?

        # When a task's private data is added by the observer we get its task_id from which
        # we can derive the task id with which we should publish the fields to the client.
        # (Reminder, the client is blind to the existence of the additional collection, to
        # the client it seems like all fields belongs to the Tasks collection).
        # Later on, when changed/removed updates for that private data received by the observer
        # we won't get the task_id field again, only the private data doc id.
        # Hence, we must keep map from private data doc id to the published task id (as set by
        # the getItemId() for the task_id).
        private_data_doc_id_to_task_id_map = {}

        #
        # Gather and send items initial payload, if there are such
        #
        if initial_payload_cursor? and private_data_initial_payload_cursor?
          #
          # Gather regular items payload
          #
          initial_payload_items = {}
          initial_payload_cursor.forEach (data) ->
            id = data._id

            if label?
              # If we got a label for this subscription, add the _label
              # field.
              data._label = label


            # Note: we always use "changed" and not "added", to avoid our fields from replacing
            # pre-existing fields that might had been sent already before from the regular
            # cursor (either in this session or the previous one!)
            #
            # You can read more about it in the comment titled:
            #
            # 'Comment regarding operation used to pulish document for the first time'.
            dataMapsExtensions(id, data, "changed")

            initial_payload_items[id] = data

          #
          # Gather private data payload
          #
          initial_payload_private_data_items = _.map private_data_initial_payload_cursor.fetch(), (data) ->
            id = data._id

            delete data._id # To keep in-line with ddp expectation that the id won't be part of the fields object

            if not data.task_id?
              console.warn "A private data doc without a task_id field received by the private_data_tracker 'added' hook, this should never happen check why: private data doc id: #{id}"

              return

            # Read comment above for private_data_doc_id_to_task_id_map.
            private_data_doc_id_to_task_id_map[id] = getItemId(data.task_id)

            # Note: we always use "changed" and not "added", to avoid our fields from replacing
            # pre-existing fields that might had been sent already before from the regular
            # cursor (either in this session or the previous one!)
            #
            # You can read more about it in the comment titled:
            #
            # 'Comment regarding operation used to pulish document for the first time'.
            privateDataMapsExtensions(id, data, "changed")

            return [private_data_doc_id_to_task_id_map[id], data]

          # A note regarding why we wire the initial_payload_private_data_items as the Changes Journal
          # part of the init_payload message and not as part of the initial_payload_items:
          #
          # My initial idea was to _.each the private_data_initial_payload_cursor.fetch() and then
          # simply push the items to the initial_payload_items messages.
          #
          # The thing is, that I want to be able to implement a very efficient algo on the client side
          # to merge the initial payload items into the pseudo mongo underlying collection data structure,
          # one that doesn't involve looping over each item.
          #
          # The initial_payload_private_data_items are of change nature, and not insert nature,
          # they are adding to the documents passed as part of the initial payload.
          #
          # Therefore, if we were adding them to the initial_payload, that will mean that the algo
          # won't be able to assume each id appears only once and perform a simple merge to the underlying
          # data structure.
          #
          # That's why I decided to pass the private data as the Changes Journal (and actually what triggered
          # the Changes Journal concept to begin with, though in the future, it will allow us to do interesting
          # caching server side, so it has a broaded place in the initial payload idea).
          #
          # -Daniel
          publish_this.initPayload target_col_name, {init_payload: initial_payload_items, changes_journal: initial_payload_private_data_items, sync_id: sync}

        #
        # Initiate trackers
        #
        tracker = cursor.observeChanges
          added: (id, data) ->
            operation = "changed"
            # # Comment regarding operation used to pulish document for the first time
            #
            # In the past we used something like this instead:
            #
            #   operation = "added"
            #   if sync? and data._raw_added_users_dates?[req_user_id] < sync
            #     operation = "changed"
            #
            # Now, with the introduction of private fields, we always use "changed" and not
            # "added".
            #
            # If an "added" message received from an umerged publication, the client should
            # replace whatever document already having the id published with the new fields
            # received.
            #
            # That means, that if the private_data_tracker already published the private data
            # for the task doc, sending the "added" message, will cause removal of the fields
            # published by the private_data_tracker (this is only one case in which the use
            # of "added" will cause us trouble).

            if label?
              # If we got a label for this subscription, add the _label
              # field.
              data._label = label

            dataMapsExtensions(id, data, operation)

            publish_this[operation] target_col_name, getItemId(id), data

            return

          changed: (id, data) ->
            dataMapsExtensions(id, data, "changed")

            publish_this.changed target_col_name, getItemId(id), data

            return

          removed: (id) ->
            if sync?
              # For sync subscription, the responsibility over removal detection
              # is passed to the removed_tracker, read more in the comment for the
              # removed_tracker above.

              return

            dataMapsExtensions(id, undefined, "removed")

            publish_this.removed target_col_name, getItemId(id)

            return

        private_data_tracker = private_data_cursor.observeChanges
          added: (id, data) ->
            operation = "changed"
            # Note: we always use "changed" and not "added", to avoid our fields from replacing
            # pre-existing fields that might had been sent already before from the regular
            # cursor (either in this session or the previous one!)
            #
            # You can read more about this above in the comment titled:
            #
            # 'Comment regarding operation used to pulish document for the first time'.

            if not data.task_id?
              console.warn "A private data doc without a task_id field received by the private_data_tracker 'added' hook, this should never happen check why: private data doc id: #{id}"

              return

            # Read comment above for private_data_doc_id_to_task_id_map.
            private_data_doc_id_to_task_id_map[id] = getItemId(data.task_id)

            privateDataMapsExtensions(id, data, operation)

            publish_this[operation] target_col_name, private_data_doc_id_to_task_id_map[id], data

            return

          changed: (id, data) ->
            if id not of private_data_doc_id_to_task_id_map
              console.warn "An id we aren't familiar with received by the private_data_tracker 'changed' hook, this should never happen, check why: private data doc id: #{id}"

              return

            privateDataMapsExtensions(id, data, "changed")

            publish_this.changed target_col_name, private_data_doc_id_to_task_id_map[id], data

            return

          removed: (id) ->
            if id not of private_data_doc_id_to_task_id_map
              console.warn "An id we aren't familiar with received by the private_data_tracker 'removed' hook, this should never happen, check why: private data doc id: #{id}"

              return

            delete private_data_doc_id_to_task_id_map[id]

            return

        publish_this.onStop ->
          tracker.stop()
          private_data_tracker.stop()

          if sync?
            removed_tracker.stop()

        publish_this.ready()

        return

    return