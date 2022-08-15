_.extend JustdoTasksCollectionsManager.prototype,
  _attachTasksCollectionSchema: ->
    self = @

    # Note: default order of columns derived from the fields order of definition
    # below

    title_field_grid_dependencies_fields = [
        "owner_id",
        "priority",
        "pending_owner_id",
        "is_removed_owner",
        "seqId",
        "files",
        "description",
        "p:justdo-files:files_count",
        "p:dp:is_project",
        "p:dp:is_archived_project",
        "priv:jdt:running_since",
        "priv:favorite",
        "p:checklist:is_checklist",
        "p:checklist:is_checked",
        "p:checklist:total_count",
        "p:checklist:checked_count",
        "p:checklist:has_partial",
        "p:rp:b:unassigned-work-hours",
        "p:rp:b:work-hours_p",
        "p:rp:b:work-hours_e"
      ]

    Schema =
      title:
        label: "Subject"

        grid_editable_column: true
        grid_visible_column: true
        grid_default_grid_view: true
        grid_default_width: 400

        grid_dependencies_fields: title_field_grid_dependencies_fields

        type: String
        optional: true

        grid_column_editor: "TextareaWithTreeControlsEditor"

        grid_default_frozen_column: true
        user_editable_column: true

      description:
        label: "Description"

        exclude_from_tasks_grid_pub: true

        grid_editable_column: false
        user_editable_column: true
        grid_visible_column: false

        type: String
        optional: true

        grid_search_when_out_of_view: true

      description_lock:
        grid_editable_column: false
        grid_visible_column: false

        type: Object
        optional: true
        blackbox: true

      status:
        label: "Notes"

        grid_editable_column: true
        grid_visible_column: true
        grid_default_grid_view: true
        grid_default_grid_view_position: 100
        grid_default_width: 196
        user_editable_column: true

        grid_dependencies_fields: ["status_by"]

        type: String
        optional: true

        grid_column_formatter: "statusFieldFormatter"
        grid_column_editor: "TextareaEditor"

      status_by:
        label: "Notes By"

        grid_editable_column: false
        grid_visible_column: false

        type: String
        optional: true

        grid_foreign_key_collection: -> Meteor.users
        grid_foreign_key_collection_relevant_fields:
          "profile.first_name": 1
          "profile.last_name": 1

        autoValue: JustdoHelpers.generateDependentAutoValue({
          field_id: "status_by"
          dependent_field_id: "status"
          autoValue: (self) -> return self.userId
          onDependencyCleared: -> return null
          })

      status_updated_at:
        label: "Notes Updated At"

        grid_editable_column: false
        grid_visible_column: false

        type: Date
        optional: true

        autoValue: JustdoHelpers.generateDependentAutoValue({
          field_id: "status_updated_at"
          dependent_field_id: "status"
          autoValue: -> return new Date
          onDependencyCleared: -> return null
          })

      state:
        label: "State"

        grid_editable_column: true
        grid_visible_column: true
        grid_default_grid_view: true
        grid_default_grid_view_position: 200
        grid_default_width: 122
        user_editable_column: true

        type: String
        optional: true

        autoValue: ->
          getDefaultInsertValue = =>
            # On insert or upsert resulting in insert, *only if unset*,
            # set to the default value "pending" unless we got a special
            # case:
            #
            #   * If inserted with root as its single parent, and with
            #   no state set explicitly, set to the nil state (which
            #   represent category)
            default_insert_value = "pending"

            if @isSet
              # Never change an explicitly set state value
              return undefined

            # If unset, see whether parents field is set, if so,
            # see if any special case applied

            parents_field = @field("parents")

            if parents_field.isSet
              parents = parents_field.value
              if _.size(parents) == 1 and "0" of parents
                # Root level task added, set default state to nil
                return "nil"

            # In any other case, just set to default value
            return default_insert_value

          if @isInsert
            return getDefaultInsertValue()
          else if @isUpsert
            if (default_insert_value = getDefaultInsertValue())?
              # If undefined is returned, means we should do nothing with the value
              return {$setOnInsert: default_insert_value}

            return undefined

          return undefined # in any other operation type, don't change state

        grid_values:
          "pending":
            txt: "Pending"
            order: 0
            due_list_state: true
            bg_color: "00000000"

          "in-progress":
            txt: "In progress"
            order: 1
            due_list_state: true
            bg_color: "0288d1"

          "done":
            txt: "Done"
            order: 2
            due_list_state: false
            bg_color: "38B000"

          "will-not-do":
            txt: "Cancelled"
            order: 3
            due_list_state: false
            bg_color: "90a4ae"

          "on-hold":
            txt: "On hold"
            order: 4
            due_list_state: false
            bg_color: "d32f2f"

          "duplicate":
            txt: "Duplicate"
            order: 5
            due_list_state: false
            bg_color: "00000000"

          "nil":
            txt: "\u2014"
            order: 6
            print: "\u2014"
            skip_xss_guard: true
            html: "<div class='null-state'></div>"

            due_list_state: true

        # We keep the following for documentation purpose, if in the future, you want to retire grid_values,
        # you can move them to the grid_removed_values to allow correct presentation of their labels in records
        # that still has them. Read more in the simple_schema_extensions.coffee file.
        #
        # You can specify the order property, but currently no functionality will use it.
        #
        grid_removed_values: (grid_control) ->
          "pending":
            txt: "Pending"

            due_list_state: true

          "on-hold":
            txt: "On hold"

            due_list_state: true

        grid_column_filter_settings:
          type: "whitelist"

        grid_column_formatter: "keyValueFormatter"
        grid_column_editor: "SelectorEditor"

      state_updated_at:
        label: "State changed at"

        grid_editable_column: false
        grid_visible_column: false

        type: Date
        optional: true

        autoValue: ->
          if Meteor.isClient
            return

          @unset() # Ignore any data requested by the user, only if we return non-undefined
                   # value it will be set

          if not this.isUpdate or not @field("state").isSet
            return undefined

          # Set state_updated_at, only if it is an update operation that involves the state
          return new Date()

      follow_up:
        label: "Follow Up"

        grid_editable_column: true
        grid_visible_column: true
        user_editable_column: true
        grid_default_grid_view: false
        grid_default_width: 140

        grid_column_formatter: "unicodeDateFollowUpDateFormatter"
        grid_column_editor: "UnicodeDateFollowUpDateEditor"

        type: String
        optional: true

        grid_column_filter_settings:
          type: "unicode-dates-filter"
          options: {
            filter_options: [
              {
                type: "relative-range",
                id: "follow-up-today",
                label: "Today's",
                relative_range: [0, 0]
              }
              {
                type: "relative-range",
                id: "past-follow-up",
                label: "Past due",
                relative_range: [null, -1]
              }
              {
                type: "relative-range",
                id: "due-in-7-days",
                label: "Next 7 days",
                relative_range: [1, 7]
              }
              {
                type: "relative-range",
                id: "due-in-30-days",
                label: "Next 30 days",
                relative_range: [1, 30]
              }
              {
                type: "custom-range"
              }
            ]
          }

      start_date:
        label: "Start Date"

        grid_editable_column: true
        grid_visible_column: true
        user_editable_column: true
        grid_default_grid_view: true
        grid_default_grid_view_position: 300
        grid_default_width: 122

        grid_column_formatter: "unicodeDateFormatter"
        grid_column_editor: "UnicodeDateEditor"

        type: String
        optional: true

        grid_column_filter_settings:
          type: "unicode-dates-filter"
          options: {
            filter_options: [
              {
                type: "relative-range",
                id: "started",
                label: "Started",
                relative_range: [null, 0]
              }
              {
                type: "relative-range",
                id: "starting-7-days",
                label: "Starting within 7 days",
                relative_range: [1, 7]
              }
              {
                type: "relative-range",
                id: "starting-30-days",
                label: "Starting within 30 days",
                relative_range: [1, 30]
              }
            ]
          }

      end_date:
        label: "End Date"

        grid_editable_column: true
        grid_visible_column: true
        user_editable_column: true
        grid_default_grid_view: true
        grid_default_grid_view_position: 400
        grid_default_width: 122

        grid_column_formatter: "unicodeDateFormatter"
        grid_column_editor: "UnicodeDateEditor"

        type: String
        optional: true

        grid_column_filter_settings:
          type: "unicode-dates-filter"
          options: {
            filter_options: [
              {
                type: "relative-range",
                id: "ending-today",
                label: "Ending today",
                relative_range: [0, 0]
              }
              {
                type: "relative-range",
                id: "ended-last-7-days",
                label: "Ended in the last 7 days",
                relative_range: [-8, -1]
              }
              {
                type: "relative-range",
                id: "ended-last-30-days",
                label: "Ended in the last 30 days",
                relative_range: [-31, -1]
              }
              {
                type: "relative-range",
                id: "ended",
                label: "Ended",
                relative_range: [null, -1]
              }
            ]
          }

      due_date:
        label: "Due Date"

        grid_editable_column: true
        grid_visible_column: true
        user_editable_column: true
        grid_default_grid_view: false
        grid_default_width: 122

        grid_column_formatter: "unicodeDateFormatter"
        grid_column_editor: "UnicodeDateEditor"

        type: String
        optional: true

        grid_column_filter_settings:
          type: "unicode-dates-filter"
          options: {
            filter_options: [
              {
                type: "relative-range",
                id: "due-today",
                label: "Due Today",
                relative_range: [0, 0]
              }
              {
                type: "relative-range",
                id: "past-due",
                label: "Past Due",
                relative_range: [null, -1]
              }
              {
                type: "relative-range",
                id: "due-in-7-days",
                label: "Due within 7 days",
                relative_range: [1, 7]
              }
              {
                type: "relative-range",
                id: "due-in-30-days",
                label: "Due within 30 days",
                relative_range: [1, 30]
              }
              {
                type: "custom-range"
              }
            ]
          }

      priority:
        label: "Priority"
        grid_editable_column: true
        grid_visible_column: true
        user_editable_column: true
        grid_default_grid_view: false
        grid_default_width: 51

        type: Number
        # decimal: true # uncomment if you want to allow floats
                        # consider effect on mobile apps if you
                        # do so.

        # optional: true
        # grid_effects_metadata_rendering: true

        min: 0
        max: 100

        autoValue: ->
          if @isSet
            # Do nothing if value provided.
            return undefined

          defaule_value = 0

          # On insert, set the value
          if this.isInsert
            return defaule_value
          else if this.isUpsert
            return {$setOnInsert: defaule_value}

          return undefined

        grid_column_filter_settings:
          type: "numeric-filter"

        grid_ranges: [
          {
            id: "not-set",
            label: "Not set",
            range: [null, 0]
          }
          {
            id: "low",
            label: "Low (1-49)",
            range: [1, 49]
          }
          {
            id: "medium",
            label: "Medium (50-74)",
            range: [50, 74]
          }
          {
            id: "high",
            label: "High (75-95)",
            range: [75, 95]
          }
          {
            id: "top",
            label: "Top (96-100)",
            range: [96, null]
          }
        ]

      project_id:
        label: "JustDo ID"

        type: String

        autoValue: ->
          # If the code is not from trusted code unset the update
          if not @isFromTrustedCode
            if @isSet
              self.logger.warn "Untrusted attempt to change project_id rejected"

              return @unset()

          return # Keep this return to return undefined (as required by autoValue)

      parents:
        label: "Parents"

        grid_editable_column: false
        grid_visible_column: false

        type: Object

        blackbox: true

      parents2:
        label: "Parents 2"

        grid_editable_column: false
        grid_visible_column: false

        type: [Object]

        blackbox: true

        exclude_from_tasks_grid_pub: true

      users:
        label: "Users"

        exclude_from_tasks_grid_pub: true

        grid_editable_column: false
        grid_visible_column: false

        type: [String]

      seqId:
        label: "Task Sequence ID"

        grid_search_when_out_of_view: true

        autoValue: ->
          # If the code is not from the server (isFromTrustedCode)
          # unset the update
          if not @isFromTrustedCode
            if @isSet
              self.logger.warn "Untrusted attempt to change seqID rejected"

              return @unset()

          return # Keep this return to return undefined (as required by autoValue)

        type: Number

      created_by_user_id:
        label: "Created by user ID"
        
        exclude_from_tasks_grid_pub: true

        grid_editable_column: false
        grid_visible_column: false
        optional: true
        type: String
        autoValue: ->
          # Don't allow changing this field from non-insert ops
          # or by untrusted code

          if not(this.isInsert or this.isUpsert)
            return @unset()

          if not @isFromTrustedCode
            # Allow trusted sources to set created_by_user_id

            if @isSet
              self.logger.warn "Untrusted attempt to change created_by_user_id rejected"

              return @unset()

          return

      updated_by:
        label: "Updated by user ID"
        grid_editable_column: false
        grid_visible_column: false
        optional: true
        type: String
        autoValue: ->
          # Don't allow changing this field from non-update ops
          # or by untrusted code

          if not @isFromTrustedCode
            if @isSet
              return @unset()

          if not @isUpdate
            return @unset()

          if not @isSet
            try
              # Important, this won't help for operations originated from the Server
              # for these operations you must set updated_by_user_id by yourself!
              # See editItem of grid-data-com and use it for operation originated from
              # the Server
              return Meteor.userId()
            catch e
              return

          # In any other case, just keep the original field value
          return

      users_updated_at:
        label: "Users Updated"

        grid_editable_column: false
        grid_visible_column: false

        exclude_from_tasks_grid_pub: true

        type: Date

        optional: true
        autoValue: ->
          if not (users_field = this.field("users")).isSet
            @unset()

            return

          if this.isUpdate
            return new Date()
          else if this.isInsert
            return new Date()
          else if this.isUpsert
            return {$setOnInsert: new Date()}
          else
            @unset()

          return

      createdAt:
        label: "Created"

        grid_editable_column: false
        grid_visible_column: true
        grid_default_grid_view: false
        grid_default_width: 160

        grid_column_formatter: "datetimeFormatter"

        type: Date
        autoValue: ->
          if this.isInsert
            return new Date()
          else if this.isUpsert
            return {$setOnInsert: new Date()}
          else
            @unset()

        grid_column_filter_settings:
          type: "dates-filter"
          options: {
            filter_options: [
              {
                type: "relative-range",
                id: "last-24-hours",
                label: "Last 24 hours",
                relative_range: [-1, null]
              }
              {
                type: "relative-range",
                id: "last-7-days",
                label: "Last 7 days",
                relative_range: [-7, null]
              }
              {
                type: "relative-range",
                id: "last-30-days",
                label: "Last 30 days",
                relative_range: [-30, null]
              }
              {
                type: "custom-range"
              }
            ]
          }

      updatedAt:
        label: "Updated"

        grid_editable_column: false
        user_editable_column: true # Not really user editable field, once a allow/deny update received with it, we set it to the server time below
        grid_visible_column: true
        grid_default_grid_view: false
        grid_default_width: 160

        grid_column_formatter: "datetimeFormatter"

        type: Date

        optional: true
        autoValue: ->
          if (doc_id = this.docId)? and _.isObject(doc_id)
            if (users_field = this.field("users")).isSet and users_field.operator in ["$pull", "$push"]
              # Do nothing for users field updates performed in bulk update.

              # We don't want updatedAt of tasks to be updated as a result of bulk updates
              # as it is likely to make queries that looks for *intentional* updates by users to
              # *specific* items non-useful.

              # See users_updated_at field

              @unset()

              return

            if /parents\..*?\.order/.test(_.keys(doc_id)[0])
              # Do nothing for order update resulted from move
              # of other items
              return

          other_affected_keys = _.without(_.values(this.affectedKeys()), "updatedAt")

          if Meteor.isClient
            # Do not set the updatedAt if only private fields are updated.
            #
            # We do the following only for the client side, since the server takes
            # that case into account in other places, and avoid updating the updatedAt
            # if only private fields are updated
            other_non_private_affected_keys = _.filter other_affected_keys, (key) -> key.substr(0, 5) != "priv:"

            if _.isEmpty other_non_private_affected_keys
              @unset()

              return

          # If client-only fields are updated, don't add updatedAt. At the moment attempt to change client-only
          # fields in the server will be blocked, so no point of considering the case of client-only fields edited
          # in the server side.
          fields_by_update_type = JustdoHelpers.getFieldsByUpdateType(self.tasks_collection, other_affected_keys)
          if fields_by_update_type.client_only.length > 0
            @unset()

            return

          if this.isUpdate
            return new Date()
          else if this.isInsert
            return new Date()
          else if this.isUpsert
            return {$setOnInsert: new Date()}
          else
            @unset()

        grid_column_filter_settings:
          type: "dates-filter"
          options: {
            filter_options: [
              {
                type: "relative-range",
                id: "last-24-hours",
                label: "Last 24 hours",
                relative_range: [-1, null]
              }
              {
                type: "relative-range",
                id: "last-7-days",
                label: "Last 7 days",
                relative_range: [-7, null]
              }
              {
                type: "relative-range",
                id: "last-30-days",
                label: "Last 30 days",
                relative_range: [-30, null]
              }
              {
                type: "custom-range"
              }
            ]
          }

      _secret:
        # The unmerged publication delete the _secret field from the published docs
        type: "skip-type-check"

        optional: true

        autoValue: ->
          # If the code is not from trusted code unset the update
          if not @isFromTrustedCode
            for affected_key of @affectedKeys()
              if affected_key.indexOf("_secret") > -1
               throw self._error "permission-denied", "Untrusted attempt to change the _secret subdocument rejected"

            if @isSet
              console.warn "Untrusted attempt to change the task's _secret field rejected"

              return @unset()

          return # Keep this return to return undefined (as required by autoValue)

      "priv:favorite":
        label: "Favorite"

        type: Date

        optional: true

    # We use this to debug multi filters at once behavior - don't remove
    #
    # another_state:
    #   label: "Another State"
    #
    #   grid_editable_column: true
    #   grid_visible_column: true
    #   grid_default_grid_view: true
    #   grid_default_width: 200
    #
    #   type: String
    #   optional: true
    #
    #   defaultValue: "pending"
    #
    #   grid_values: (grid_control) ->
    #     "pending-b":
    #       txt: "Pending B"
    #     "in-progress-b":
    #       txt: "In progress B"
    #     "done-b":
    #       txt: "Done B"
    #     "will-not-do-b":
    #       txt: "Won't do B"
    #     "on-hold-b":
    #       txt: "On hold B"
    #     "do-later-b":
    #       txt: "Do later B"
    #     "nil-b":
    #       txt: "None"
    #       html: "<div class='null-state'></div>"
    #
    #   grid_column_filter_settings:
    #     type: "whitelist"
    #
    #   grid_column_formatter: "keyValueFormatter"
    #   grid_column_editor: "SelectorEditor"


    for field_name in ["_raw_added_users_dates", "_raw_removed_users_dates"]
      do (field_name) =>
        Schema[field_name] =
          type: Object

          optional: true

          blackbox: true

          autoValue: ->
            # If the code is not from trusted code unset the update
            if not @isFromTrustedCode
              if @isSet
                self.logger.warn "Untrusted attempt to change task's #{field_name} field rejected"

                return @unset()

            return # Keep this return to return undefined (as required by autoValue)

    for field_name in ["_raw_updated_date", "_raw_removed_date"]
      do (field_name) =>
        Schema[field_name] =
          type: "skip-type-check"

          optional: true

          autoValue: ->
            # If the code is not from trusted code unset the update
            if not @isFromTrustedCode
              if @isSet
                self.logger.warn "Untrusted attempt to change task's #{field_name} field rejected"

                return @unset()

            return # Keep this return to return undefined (as required by autoValue)

    for field_name in ["_raw_removed_users"]
      do (field_name) =>
        Schema[field_name] =
          type: [String]

          optional: true

          autoValue: ->
            # If the code is not from trusted code unset the update
            if not @isFromTrustedCode
              if @isSet
                self.logger.warn "Untrusted attempt to change task's #{field_name} field rejected"

                return @unset()

            return # Keep this return to return undefined (as required by autoValue)

    @tasks_collection.attachSchema Schema
