Template.active_project_members_indicator.helpers
  curProjectMembers: -> 
    member_ids = _.map APP.justdo_user_active_position.getProjectMembersCurrentPositionsCursor().map (ledger_doc) -> ledger_doc.UID
    member_ids_without_self = _.without member_ids, Meteor.userId()
    return Meteor.users.find {_id: {$in: member_ids_without_self}}