# README
#
# For now we go with ultra-minimal implementation, if in the future
# needs will expand - we'll need to convert to justdo's packages
# skeleton

JustdoProjectsSharedComponents =
  initSharedComponents: ->
    # Call this function only in environment that doesn't
    # init the real JustdoProjects!
    # JustdoProjects takes care of all the inits it needs.

    @attachUserProfileCollectionSchema()

    return

  attachUserProfileCollectionSchema: ->
    user_justdo_projects_simple_schema = new SimpleSchema
      post_reg_init:
        type: Boolean
        defaultValue: false
      daily_email_projects_array:
        type: [String]
        defaultValue: []
      prevent_notifications_for:
        type: [String]
        optional: true

    Meteor.users.attachSchema
      justdo_projects:
        type: user_justdo_projects_simple_schema

    return