visible_members_limit = 2

Template.active_project_members_indicator.onCreated ->
  # This dependency is used to trigger a re-render of the template to check if the users are inactive
  @check_user_inactive_dep = new Tracker.Dependency()
  @check_user_inactive_interval = Meteor.setInterval =>
    @check_user_inactive_dep.changed()
  , JustdoUserActivePosition.check_user_inactive_interval

  @curProjectMembers = (limit = true) ->
    member_ids = _.map APP.justdo_user_active_position.getProjectMembersCurrentPositionsCursor().map (ledger_doc) -> ledger_doc.UID
    member_ids_without_self = _.without member_ids, Meteor.userId()
    query_options = if limit then {limit: visible_members_limit} else {}

    return Meteor.users.find {_id: {$in: member_ids_without_self}}, query_options


Template.active_project_members_indicator.helpers
  curProjectMembersLimited: ->
    return Template.instance().curProjectMembers(true)

  curProjectMembersAll: ->
    return Template.instance().curProjectMembers(false)

  hiddenMembersCount: ->
    member_ids = _.map APP.justdo_user_active_position.getProjectMembersCurrentPositionsCursor().map (ledger_doc) -> ledger_doc.UID
    member_ids_without_self = _.without member_ids, Meteor.userId()
    active_members_count = Meteor.users.find({_id: {$in: member_ids_without_self}}).fetch().length

    hiddenMembersCount = Math.max(0, active_members_count - visible_members_limit)
    return hiddenMembersCount

  isUserInactive: ->
    tpl = Template.instance()
    tpl.check_user_inactive_dep.depend()
    return APP.justdo_user_active_position.isUserLedgerDocInactive @_id

Template.active_project_members_indicator.events
  "click .member-avatar": ->
    if not APP.justdo_user_active_position.isProjectMembersCurrentOnGridPositionsTrackerEnabled()
      APP.justdo_user_active_position.setupProjectMembersCurrentOnGridPositionsTracker()
    else
      APP.justdo_user_active_position.removeProjectMembersCurrentOnGridPositionsTracker()
    return
Template.active_project_members_indicator.onDestroyed ->
  Meteor.clearInterval @check_user_inactive_interval
  return
