# YOU *AREN'T* OBLIGATED TO CALL JustdoChat.registerChannelTypeServerSpecific for
# types you got no server specific confs for.

JustdoChat.registerChannelTypeServerSpecific
  channel_type: "task" # Must be the same as task-channel-both-register.coffee

  _immediateInit: ->
    # @ is the JustdoChat object's

    # When a user stop being a member of a task unsubscribe him from the task chat
    @tasks_collection.after.update (user_id, doc, field_names, modifier, options) =>
      # Remove the user as subscriber from tasks channels when the user is removed
      # from the task users field: either for a specific task, or when the user removed
      # from the project completely.
      if "users" in field_names
        # We will have modifier?.$pull?.users?.$in when the user removed from a specific task/tasks
        if not (users_to_remove = modifier?.$pull?.users?.$in)?
          if (user_to_remove = modifier?.$pull?.users)?
            # This will happen when the user completely removed from the project
            users_to_remove = [user_to_remove]
          else
            return # nothing to do

        if _.isEmpty(users_to_remove) # extra safe
          return

        # Note, I consciously decided not to generate channel object here to:
        #   1. Avoid overhead involved
        #   2. Transpassing security is required, and I don't want to add an option to init channel object without performing user to avoid
        #      security implications from reducing strict security.
        #        Example where transpassing security is required: user A remove user B, user B has a task not shared with user A (if we init
        #        a channel obj, user A will be the performing user and won't be allowed to operate on tasks he isn't a member of)
        #   3. Potential cases where we won't have user_id from collection hooks (not sure if we have such cases).
        # Daniel C.

        #
        # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
        # and to drop obsolete indexes (see MESSAGES_FETCHING_INDEX there)
        #
        query = {task_id: doc._id}

        update =
          $pull:
            subscribers:
              user_id:
                $in: users_to_remove


        # We use rawCollection() since the request is too heavy for collection2/simple-schema
        @channels_collection.rawCollection().update(query, update)

        return

    # When a task is removed, rename its subscribers field to "archived_subscribers",
    # read more about that field in schemas.coffee .
    @tasks_collection.after.remove (user_id, doc, field_names, modifier, options) =>
      #
      # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
      # and to drop obsolete indexes (see MESSAGES_FETCHING_INDEX there)
      #
      query = {task_id: doc._id}

      update =
        $rename:
          subscribers: "archived_subscribers"

      # We use rawCollection() since the request is too heavy for collection2/simple-schema
      @channels_collection.rawCollection().update(query, update)

      return

    # When a project is removed, rename the subscribers field of all its channels to
    # archived_subscribers. read more about that field in schemas.coffee .
    APP.executeAfterAppLibCode =>
      # APP.projects is initiated in the lib app's lib folder

      # DEVELOPER, don't copy paste this part without considering product implication
      # of post project-removed procedures, search the code for
      # AVOID_DRASTIC_POST_PROJECT_REMOVAL_PROCEDURES and read comment there.
      APP.projects.on "project-removed", (project_id) =>
        console.log "PROJECT REMOVED", project_id

        #
        # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
        # and to drop obsolete indexes (see CHANNEL_AUGMENTED_FIELDS_INDEX there)
        #
        query = {project_id: project_id}

        update =
          $rename:
            subscribers: "archived_subscribers"

        options =
          multi: true

        # We use rawCollection() since the request is too heavy for collection2/simple-schema
        @channels_collection.rawCollection().update(query, update, options)

        return

    return

  _deferredInit: ->
    # @ is the JustdoChat object's

    return