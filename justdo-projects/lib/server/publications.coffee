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

      "timezone": 1

    non_guests_published_fields = _.extend {}, guests_published_fields,
      "members.user_id": 1
      "members.is_admin": 1
      "members.is_guest": 1

      "removed_members.user_id": 1

    # XXX Should use "APP.justdo_org?" once dependency issue is resolved.
    if process.env.ORGANIZATIONS is "true"
      non_guests_published_fields.org_id = 1

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

        {project_id, get_parents_as_string, sync, paginated} = sub_options
        # Validate options
        if not project_id?
          throw self._error "missing-argument", "You must specify the list of project_ids you want to subscribe to"

        try
          self.emit "pre-setup-grid-publication", project_id
        catch err
          publish_this.error err
          return

        check project_id, String
        check get_parents_as_string, Match.Maybe(Boolean)
        check sync, Match.Maybe(Date)

        check paginated, Match.Maybe([Number])

        {allow_init_payload_forced_column_value_directive} = pub_options

        check allow_init_payload_forced_column_value_directive, Match.Maybe(Boolean)

        init_payload_forced_column_value = undefined

        if not allow_init_payload_forced_column_value_directive?
          allow_init_payload_forced_column_value_directive = false

        if allow_init_payload_forced_column_value_directive and not pub_options.init_payload_raw_cursors_mode
          throw self._error "invalid-argument", "The allow_init_payload_forced_column_value_directive publication option is only supported for the init_payload_raw_cursors_mode"

        if paginated?
          if sync?
            throw self._error "invalid-argument", "The paginated subscription option is not supported together with the sync option"

          if not pub_options.init_payload_raw_cursors_mode
            throw self._error "invalid-argument", "The paginated subscription option is only supported for the init_payload_raw_cursors_mode"

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

          private_data_initial_payload_query = _.extend {}, private_data_query
          private_data_initial_payload_query.$or = [
            {_raw_updated_date: {$lte: sync}},
            {_raw_updated_date: null}
          ]

          # There's no need to add the forbidden fields to the initial payload
          for forbidden_field_id in Projects.tasks_forbidden_fields
            Meteor._ensure query_options, "fields"
            query_options.fields[forbidden_field_id] = 0

          if pub_options.init_payload_raw_cursors_mode
            if allow_init_payload_forced_column_value_directive
              Meteor._ensure query_options, "fields"
              query_options.fields.project_id = 0 # The project_id is obvious from the request.

              init_payload_forced_column_value = {project_id: query.project_id}

            init_payload_query_options = _.extend {raw: true}, query_options
            init_payload_private_data_query_options = _.extend {raw: true}, private_data_query_options

            if not init_payload_private_data_query_options.fields?
              init_payload_private_data_query_options.fields = {}
            for forbidden_field_id in Projects.tasks_private_fields_docs_initial_payload_redundant_fields
              init_payload_private_data_query_options.fields[forbidden_field_id] = 0

            if paginated?
              # ## Pagination model:
              #
              # Unlike usual pagination models, our model is based on creating fixed-sized segments in the
              # data-set (i.e the project's tasks). That means that each page might have a different amount
              # of pages.
              #
              # We are segmenting pages based on their seqId. A number that we know that for sure will be there
              # for every task, and it is very easy to segent the data based on.
              #
              # The last page, will include the the private fields and might have more pages
              # than the max_page_size, since we'll let it exceed the limit to capture all the items that
              # aren't covered by the boundaries resulting from (max_page_size * total_pages).
              #
              # Example:
              #
              # Task 1
              # Task 2
              # Task 3
              # Task 4
              # Task 5
              #
              # max_page_size = 2, total_pages = 2
              #
              # Page 1:
              # Task 1
              # Task 2
              # + All the private fields.
              #
              # Page 2:
              # Task 3
              # Task 4
              # Task 5 < Included even though max_page_size is 2.
              #
              # Each of the pages will return with the usual sync_id, the subscription to sync the
              # data should be requested with the minimum of all the sync_ids of all the pages received.
              # That will promise that the data will for sure be up-to-date for all the tasks.
              #
              #
              # ## Considerations made when planning the pagination system:
              #
              # The following was the original idea for the pagination model
              # I figured that it won't work so I (Daniel) didn't proceed with it. But the text
              # is good to understand the consideration made me when planning the pagination model.
              #
              # The original idea was to rely only on the amount of tasks in the project that can be
              # derived from the last_seq_id from the project publication, to decide how many pages to
              # request.
              #
              # That had the drawback that for users with very little tasks, for which one page is enough
              # we might still request many pages redundently (think a project with 1m tasks, a user that
              # has only one task in it).
              #
              # Second, and more seriously, it became very challenging to ensure that the pages content
              # won't change as we request them - leading for some tasks to never receive.
              #
              # Comments that added to the text below after it was abandoned were added inside []
              #
              # // OBSOLETE COMMENT 1. Pages consistency and time-stamp: < THIS IS AN ABANDONED IDEA !
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT When paginating, a crucial challenge is to ensure that the pages content won't change
              # // OBSOLETE COMMENT as we create them.
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT E.g Imagine that we were to query for the tasks belonging to user X.
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT Let's say that the page size is 3 tasks, and that in total that user belongs to 4 tasks.
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT First page sent to user:
              # // OBSOLETE COMMENT Task 1
              # // OBSOLETE COMMENT Task 22
              # // OBSOLETE COMMENT Task 53
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT Second page, not requested yet:
              # // OBSOLETE COMMENT Task 40
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT Now think of the following scenario, before the request for the 2nd page, the user got
              # // OBSOLETE COMMENT removed from task 22 - either due to loss of access (removed from users array), or due to
              # // OBSOLETE COMMENT actual removal of that task.
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT When the 2nd page will be queried, it'll return nothing, since task 40 is now on the first
              # // OBSOLETE COMMENT page.
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT First page:
              # // OBSOLETE COMMENT Task 1
              # // OBSOLETE COMMENT Task 53
              # // OBSOLETE COMMENT Task 40
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT Second page:
              # // OBSOLETE COMMENT Nil
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT In that scenario, the user that requested the 2 pages - will actually miss 1 task.
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT The purpose of the pagination_timestamp is to overcome this and promise consistency
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT We request in the query pages to which we were either added before the pagination_timestamp
              # // OBSOLETE COMMENT or those to which we lost access (either due to removal, or due to loss of permission),
              # // OBSOLETE COMMENT *after* the pagination_timestamp. [Here you can see that things starts getting complex already]
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT This way, each page provided by the DB will be consistent in content. When we'll prepare those
              # // OBSOLETE COMMENT pages for submission we'll ensure to remove the tasks to which the user lost access to.
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT Going back to the previous example the result will be:
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT First page requested:
              # // OBSOLETE COMMENT 
              # // OBSOLETE COMMENT   First page sent to user:
              # // OBSOLETE COMMENT   Task 1
              # // OBSOLETE COMMENT   Task 22
              # // OBSOLETE COMMENT   Task 53
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT   Second page, not requested yet:
              # // OBSOLETE COMMENT   Task 40
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT Second page requested:
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT    First page:
              # // OBSOLETE COMMENT    Task 1
              # // OBSOLETE COMMENT    Task 22
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT    Second page:
              # // OBSOLETE COMMENT    Task 40
              # // OBSOLETE COMMENT
              # // OBSOLETE COMMENT Note that in that case if the first page will be requested 2nd time it'll be sent without Task 3.

              check paginated, [Number]

              [max_page_size, total_pages, current_page] = paginated

              max_page_size = Math.round(max_page_size)
              total_pages = Math.round(total_pages)
              current_page = Math.round(current_page)

              if max_page_size < Projects.page_count_rounding_factor or max_page_size > Projects.max_page_size
                throw self._error "invalid-argument", "provided max_page_size isn't supported"

              if total_pages <= 1
                throw self._error "invalid-argument", "provided total_pages isn't supported"

              if current_page < 0 or current_page > total_pages - 1
                throw self._error "invalid-argument", "provided current_page isn't supported"

              is_last_page = current_page == total_pages - 1

              first_seq_id_inclusive = current_page * max_page_size
              last_seq_id_exclusive = null
              if not is_last_page
                # We don't limit the max page seqId in the last page
                last_seq_id_exclusive = first_seq_id_inclusive + max_page_size

              initial_payload_query.seqId = {$gte: first_seq_id_inclusive}

              if last_seq_id_exclusive?
                initial_payload_query.seqId.$lt = last_seq_id_exclusive

            initial_payload_cursor = collection.rawCollection().find initial_payload_query, init_payload_query_options
            if not paginated? or is_last_page
              private_data_initial_payload_cursor = private_data_collection.rawCollection().find private_data_initial_payload_query, init_payload_private_data_query_options
            else
              private_data_initial_payload_cursor = "SKIP"
          else
            initial_payload_cursor = collection.find initial_payload_query, query_options
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
          delete data._raw_updated_date_only_users
          delete data._raw_updated_date_sans_users
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
          # IF YOU ADD MORE FIELDS HERE ADD THEM ALSO TO: Projects.tasks_private_fields_docs_initial_payload_redundant_fields

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
          if pub_options.init_payload_raw_cursors_mode
            init_payload_msg_items =
              init_payload: initial_payload_cursor
              changes_journal: if private_data_initial_payload_cursor is "SKIP" then undefined else private_data_initial_payload_cursor # When pagination is used we include the private data only in the last page
              sync_id: sync

            if init_payload_forced_column_value?
              init_payload_msg_items.forced_column_value = init_payload_forced_column_value

            publish_this.initPayload target_col_name, init_payload_msg_items
          else
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
            publish_this.initPayload target_col_name,
              init_payload: initial_payload_items
              changes_journal: initial_payload_private_data_items
              sync_id: sync

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

            console.log "CONTINUE HERE"
            console.log "added", data

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