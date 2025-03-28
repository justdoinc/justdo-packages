# YOU *AREN'T* OBLIGATED TO CALL JustdoChat.registerChannelTypeServerSpecific for
# types you got no server specific confs for.

JustdoChat.registerChannelTypeServerSpecific
  channel_type: "task" # Must be the same as task-channel-both-register.coffee

  _immediateInit: ->
    grid_data_com = APP.projects._grid_data_com
    # @ is the JustdoChat object's

    # When a user stop being a member of a task:
    #
    #  * unsubscribe him from the task chat
    #  * Remove entry he has in the open_windows field of that task (if any).
    removeSubscribersFromChannel = (task_id, users_to_remove) =>
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
      # and to drop obsolete indexes (see CHANNEL_IDENTIFIER_INDEX there)
      #
      # task_id can be a string or an obj of {$in: [task_ids]}
      query = {task_id: task_id}

      #
      # Remove from subscribers, remove from bottom_windows
      #

      update =
        $pull:
          subscribers:
            user_id:
              $in: users_to_remove

          bottom_windows:
            user_id:
              $in: users_to_remove

      options =
        multi: true

      # We use rawCollection() since the request is too heavy for collection2/simple-schema
      APP.justdo_analytics.logMongoRawConnectionOp(@channels_collection._name, "update", query, update, options)
      @channels_collection.rawCollection().update(query, update, options)

      return

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

        removeSubscribersFromChannel doc._id, users_to_remove

        return
    APP.on "batched-collection-update-executed", (collection, selector, modifier, mongo_update_options) =>
      if collection isnt APP.collections.Tasks
        return

      # task_ids could be an obj of {$in: [task_ids]}
      if not (task_ids = selector?._id)?
        return

      if not (users_to_remove = modifier?.$pull?.users?.$in)?
        return
      
      removeSubscribersFromChannel task_ids, users_to_remove

      return
  
    # When a task is removed:
    #
    #  * Rename its subscribers field to "archived_subscribers", read more about that
    #    field in schemas.coffee.
    #  * Remove its bottom_windows field.
    archiveTaskChannel = (task_id) =>
      query = {task_id}
      #
      # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
      # and to drop obsolete indexes (see CHANNEL_IDENTIFIER_INDEX there)
      #
      update =
        $rename:
          subscribers: "archived_subscribers"
        $unset:
          bottom_windows: ""

      # We use rawCollection() since the request is too heavy for collection2/simple-schema
      APP.justdo_analytics.logMongoRawConnectionOp(@channels_collection._name, "update", query, update)
      @channels_collection.rawCollection().update(query, update)

      return
    
    @tasks_collection.after.remove (user_id, doc, field_names, modifier, options) =>
      archiveTaskChannel doc._id

      return
      
    grid_data_com.setGridMethodMiddleware "afterRemoveParent", (path, performing_user, options) =>
      if not options.no_more_parents
        return true
      
      if not (task_id = options?.item?._id)?
        return true
      
      archiveTaskChannel task_id

      return true

    # When a project is removed, rename the subscribers field of all its channels to
    # archived_subscribers. read more about that field in schemas.coffee .
    APP.executeAfterAppLibCode =>
      # APP.projects is initiated in the lib app's lib folder

      # DEVELOPER, don't copy paste this part without considering product implication
      # of post project-removed procedures, search the code for
      # AVOID_DRASTIC_POST_PROJECT_REMOVAL_PROCEDURES and read comment there.
      APP.projects.on "project-removed", (project_id) =>
        #
        # IMPORTANT, if you change the following, don't forget to update the collections-indexes.coffee
        # and to drop obsolete indexes (see CHANNEL_AUGMENTED_FIELDS_INDEX there)
        #
        query = {project_id: project_id}

        update =
          $rename:
            subscribers: "archived_subscribers"
          $unset:
            bottom_windows: ""

        options =
          multi: true

        # We use rawCollection() since the request is too heavy for collection2/simple-schema
        APP.justdo_analytics.logMongoRawConnectionOp(@channels_collection._name, "update", query, update, options)
        @channels_collection.rawCollection().update(query, update, options)

        return

    return

  _deferredInit: ->
    # @ is the JustdoChat object's

    return