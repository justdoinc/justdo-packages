read_system_updates = new SimpleSchema
  read_at:
    label: "Read at"
    type: Date

  update_id:
    label: "Update ID"
    type: String

    custom: ->
      if not JustdoSystemUpdates.systemUpdateExists(@value)
        return "Unknown Update ID"

      return

_.extend JustdoSystemUpdates.prototype,
  _attachCollectionsSchemas: ->
    Meteor.users.attachSchema
      "profile.read_system_updates":
        type: [read_system_updates]
        optional: true

    return