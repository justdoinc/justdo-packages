_.extend Projects.prototype,
  isAdminOfProjectDoc: (project_doc, user_id) ->
    if not user_id?
      return false

    admins = _.map project_doc.members, (member) ->
      if not member.is_admin
        return false
      return member.user_id

    return user_id in admins

  getMembersIdsFromProjectDocMembersField: (members) ->
    _.map members, (member) -> member.user_id

  getMembersIdsFromProjectDoc: (project_doc) ->
    @getMembersIdsFromProjectDocMembersField(project_doc?.members)

  getRemovedMembersIdsFromProjectDoc: (project_doc) ->
    @getMembersIdsFromProjectDocMembersField(project_doc?.removed_members)

  getAdminsIdsFromProjectDoc: (project_doc, _invert=false) ->
    filtered_members =
      _.filter project_doc?.members, (member) -> if not _invert then member.is_admin else not member.is_admin

    return @getMembersIdsFromProjectDocMembersField filtered_members

  getNonAdminsIdsFromProjectDoc: (project_doc) ->
    @getAdminsIdsFromProjectDoc project_doc, true