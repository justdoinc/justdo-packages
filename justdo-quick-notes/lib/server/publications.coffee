_.extend JustdoQuickNotes.prototype,
  _setupPublications: ->
    @_publishQuickNotes()

    return

  _publishQuickNotes: ->
    self = @

    Meteor.publish "activeQuickNotes", (active_note_limit = 0) ->
      if not @userId?
        @ready() # No quick notes for anonymous
        return

      query =
        user_id: @userId
        completed: null
        deleted: null

      options =
        sort:
          order: -1
        limit: active_note_limit

      return self.quick_notes_collection.find query, options

    Meteor.publish "completedQuickNotes", (completed_note_limit = JustdoQuickNotes.completed_note_default_query_limit) ->
      if not @userId?
        @ready() # No quick notes for anonymous
        return

      query =
        user_id: @userId
        completed:
          $exists: true
        deleted: null

      options =
        sort:
          order: -1
        limit: completed_note_limit

      return self.quick_notes_collection.find query, options

    return
