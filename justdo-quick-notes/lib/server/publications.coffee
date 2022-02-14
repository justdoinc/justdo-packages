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

      quick_notes_query =
        user_id: @userId
        deleted: null

      # For displaying active quick note count in toolbar, we'll display 99+ for more than 99 quick notes.
      # Thus we only need up to 100.
      quick_notes_cursor = self.quick_notes_collection.find quick_notes_query, {limit: 100}

      active_quick_notes_count = 0
      completed_quick_notes_count = 0
      initial = true

      quick_notes_count_tracker = quick_notes_cursor.observe
        added: (doc) ->
          if doc.completed
            completed_quick_notes_count += 1
          else
            active_quick_notes_count += 1

          if not initial
            publish_this.changed "quick_notes_info", "completed_quick_notes_count", {count: completed_quick_notes_count}
            publish_this.changed "quick_notes_info", "active_quick_notes_count", {count: active_quick_notes_count}

          return

        changed: (new_doc, old_doc) ->
          if new_doc.completed and not old_doc.completed
            completed_quick_notes_count += 1
            active_quick_notes_count -= 1
          if not new_doc.completed and old_doc.completed
            completed_quick_notes_count -= 1
            active_quick_notes_count += 1

          publish_this.changed "quick_notes_info", "completed_quick_notes_count", {count: completed_quick_notes_count}
          publish_this.changed "quick_notes_info", "active_quick_notes_count", {count: active_quick_notes_count}

          return

        removed: (old_doc) ->
          if old_doc.completed
            completed_quick_notes_count -= 1
          else
            active_quick_notes_count -= 1

          if not initial
            publish_this.changed "quick_notes_info", "completed_quick_notes_count", {count: completed_quick_notes_count}
            publish_this.changed "quick_notes_info", "active_quick_notes_count", {count: active_quick_notes_count}

          return

      initial = false

      publish_this.added "quick_notes_info", "completed_quick_notes_count", {count: completed_quick_notes_count}
      publish_this.added "quick_notes_info", "active_quick_notes_count", {count: active_quick_notes_count}

      publish_this.onStop ->
        quick_notes_count_tracker.stop()

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
