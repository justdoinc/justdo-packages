_.extend MeetingsManager.prototype,
  _attachCollectionsSchemas: ->
    @meetings = new Mongo.Collection 'meetings_meetings'
    @meetings_tasks = new Mongo.Collection 'meetings_tasks'
    @meetings_private_notes = new Mongo.Collection 'meetings_private_notes'

    @meeting_metadata_schema = new SimpleSchema
      title:
        label: "Meeting title"
        type: String

      location:
        label: "Location"
        type: String
        optional: true

      date:
        label: "Date"
        type: Date
        optional: true

      time:
        label: "Time"
        optional: true
        type: String

      note:
        label: "Meeting Summary Notes"
        type: String
        optional: true

      note_lock:
        label: "Lock for Meeting Summary Notes"
        type: Object
        optional: true
        blackbox: true

    @meetings.attachSchema @meeting_metadata_schema

    @meetings.attachSchema

      project_id:
        label: "Project ID"
        type: String

      organizer_id:
        label: "Organizer"
        type: String

        # Set the organizer_id on insert
        autoValue: ->
          # XXX I don't quite understand this logic, and I'm not sure if it
          # does what's expected.
          if not @isFromTrustedCode
            if @isSet
              console.log "Untrusted attempt to modify organizer rejected"

            return

          if not @isSet and @isInsert
            return Meteor.userId()

          return

      users:
        label: "Members"
        type: [String]
        autoValue: ->
          if not @isSet and @isInsert
            return []
          return

      tasks:
        label: "Tasks"
        type: [Object]
        autoValue: ->
          if not @isSet and @isInsert
            return []
          return

      "tasks.$":
        blackbox: true

      status:
        label: "Status"
        type: String
        allowedValues: ["draft", "pending", "in-progress", "adjourned", "cancelled", "duplicate"]

      start:
        label: "Start Times"
        type: [Object]
        autoValue: ->
          if not @isSet and @isInsert
            return []
          return

      "start.$":
        blackbox: true

      end:
        label: "End Times"
        type: [Object]
        autoValue: ->
          if not @isSet and @isInsert
            return []
          return

      "end.$":
        blackbox: true

      locked:
        label: "Locked"
        type: Boolean
        autoValue: ->
          if not @isSet and @isInsert
            return false
          else
            return

      private:
        label: "Confidential"
        type: Boolean
        autoValue: ->
          if not @isSet and @isInsert
            return false
          else
            return

      updatedAt:
        label: "Updated"

        type: Date

        optional: true
        autoValue: ->
          return new Date()

    @meetings_tasks.attachSchema
      meeting_id:
        label: "Meeting Id"
        type: String

      task_id:
        label: "Task Id"
        type: String

      user_notes:
        label: "User Task Notes From Meeting"
        type: [Object]
        autoValue: ->
          if not @isSet and @isInsert
            return []
          return

      "user_notes.$":
        blackbox: true

      note:
        label: "Summary Note For Task"
        type: String
        optional: true

      note_lock:
        label: "Lock for Summary Note For Task"
        type: Object
        optional: true
        blackbox: true

      added_tasks:
        label: "Added Tasks From Meeting"
        type: [Object]
        autoValue: ->
          if not @isSet and @isInsert
            return []
          return

      "added_tasks.$":
        blackbox: true

      updatedAt:
        label: "Updated"

        type: Date

        optional: true
        autoValue: ->
          return new Date()

    @meetings_private_notes.attachSchema
      meeting_id:
        label: "Meeting Id"
        type: String

      task_id:
        label: "Task Id"
        type: String

      user_id:
        label: "User Id"
        type: String

      note:
        label: "Private User Task Note From Meeting"
        type: String
        optional: true

      updatedAt:
        label: "Updated"

        type: Date

        optional: true
        autoValue: ->
          return new Date()
