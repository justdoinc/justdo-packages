_.extend JustdoI18n.prototype,
  _attachCollectionsSchemas: -> 
    Meteor.users.attachSchema
      "profile.lang":
        label: "User preferred language"
        type: String
        optional: true
    return