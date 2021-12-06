_.extend JustdoQuickNotes.prototype,
  _setupPublications: ->
    @_publishQuickNotes()

    return

  _publishQuickNotes: ->
    self = @

    Meteor.publish "activeQuickNotes", (options) ->
      if not @userId?
        @ready() # No quick notes for anonymous
        return

      #
      # NOTE: active_quick_notes_query is using QUICK_NOTES_REORDER_PUT_BEFORE_QUERY_INDEX (user_id)
      #
      active_quick_notes_query =
        user_id: @userId
        completed: null
        deleted: null

      active_quick_notes_options =
        sort:
          order: -1

      if options.limit?
        active_quick_notes_options.limit = options.limit

      return self.quick_notes_collection.find active_quick_notes_query, active_quick_notes_options

    Meteor.publish "completedQuickNotes", (options) ->
      if not @userId?
        @ready() # No quick notes for anonymous
        return

      #
      # NOTE: completed_quick_notes_query is using QUICK_NOTES_REORDER_PUT_BEFORE_QUERY_INDEX (user_id)
      #
      completed_quick_notes_query =
        user_id: @userId
        completed:
          $exists: true
        deleted: null

      completed_quick_notes_options =
        sort:
          order: -1

      if options.limit?
        completed_quick_notes_options.limit = options.limit

      return self.quick_notes_collection.find completed_quick_notes_query, completed_quick_notes_options

    return
