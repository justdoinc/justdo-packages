_.extend Projects.prototype,
  userRequirePostRegistrationInit: ->
    if (user = Meteor.user())? and (post_reg_init = user.justdo_projects?.post_reg_init)? and post_reg_init == false
      return true

    return false

  getProjectDoc: (project_id, options) ->
    @projects_collection.findOne(project_id, options)

  getProjectMembersIds: (project_id, options) ->
    if not options?
      options = {}

    options = _.extend {include_removed_members: false}, options

    # The following will happen only for guests
    if not (members = @getProjectDoc(project_id, {fields: {members: 1}}).members)?
      members = [{user_id: Meteor.userId(), is_admin: false, is_guest: true}]
    
    members_ids = @getMembersIdsFromProjectDoc({members})

    if options.include_removed_members
      members_ids = members_ids.concat(@getRemovedMembersIdsFromProjectDoc(@getProjectDoc(project_id, {fields: {removed_members: 1}})))

    return members_ids
