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

    # Currently quickNotesInfo pub/sub only handles active quick note count.
    Meteor.publish "quickNotesInfo", ->
      if not @userId?
        @ready() # No quick notes info for anonymous
        return

      publish_this = @

      active_quick_notes_query =
        user_id: @userId
        completed: null
        deleted: null

      # For displaying active quick note count in toolbar, we'll display 99+ for more than 99 quick notes.
      # Thus we only need up to 100.
      active_quick_notes_cursor = self.quick_notes_collection.find active_quick_notes_query, {limit: 100}

      count = 0
      initial = true
      active_quick_notes_count_tracker = active_quick_notes_cursor.observeChanges
        added: (id, data) ->
          count += 1

          if not initial
            publish_this.changed "quick_notes_info", "active_quick_notes_count", {count: count}

        removed: (id) ->
          count -= 1

          if not initial
            publish_this.changed "quick_notes_info", "active_quick_notes_count", {count: count}

      initial = false
      publish_this.added "quick_notes_info", "active_quick_notes_count", {count: count}

      publish_this.onStop ->
        active_quick_notes_count_tracker.stop()

      publish_this.ready()

      return

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
          $ne: null
        deleted: null

      completed_quick_notes_options =
        sort:
          order: -1

      if options.limit?
        completed_quick_notes_options.limit = options.limit

      return self.quick_notes_collection.find completed_quick_notes_query, completed_quick_notes_options

    return
