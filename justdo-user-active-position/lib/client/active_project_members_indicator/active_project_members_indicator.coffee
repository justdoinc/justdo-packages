Template.active_project_members_indicator.onCreated ->
  # This dependency is used to trigger a re-render of the template to check if the users are inactive
  @check_user_inactive_dep = new Tracker.Dependency()
  @check_user_inactive_interval = Meteor.setInterval =>
    @check_user_inactive_dep.changed()
  , JustdoUserActivePosition.check_user_inactive_interval

Template.active_project_members_indicator.helpers
  curProjectMembers: -> 
    member_ids = _.map APP.justdo_user_active_position.getProjectMembersCurrentPositionsCursor().map (ledger_doc) -> ledger_doc.UID
    member_ids_without_self = _.without member_ids, Meteor.userId()
    return Meteor.users.find {_id: {$in: member_ids_without_self}}
  
  isUserInactive: ->
    tpl = Template.instance()
    tpl.check_user_inactive_dep.depend()
    return APP.justdo_user_active_position.isUserLedgerDocInactive @_id

Template.active_project_members_indicator.onDestroyed ->
  Meteor.clearInterval @check_user_inactive_interval
  return