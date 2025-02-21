Template.active_project_members_indicator.onCreated ->
  # This dependency is used to trigger a re-render of the template to check if the users are inactive
  @check_user_inactive_dep = new Tracker.Dependency()
  @check_user_inactive_interval = Meteor.setInterval =>
    @check_user_inactive_dep.changed()
  , JustdoUserActivePosition.check_user_inactive_interval

  @curProjectMembers = (limit = true) ->
    member_ids_without_self = APP.justdo_user_active_position.getProjectMembersCurrentPositionsCursor({UID: {$ne: Meteor.userId()}}, {fields: {UID: 1}}).map (ledger_doc) -> ledger_doc.UID

    # Fetch all users (without limit)
    users = Meteor.users.find({_id: {$in: member_ids_without_self}}).fetch()

    # Sort users: active first, inactive last
    sorted_users = _.sortBy users, (user) ->
      APP.justdo_user_active_position.isUserLedgerDocInactive(user._id)

    # Apply the limit after sorting
    if limit
      sorted_users = sorted_users.slice(0, JustdoUserActivePosition.max_visible_project_members)

    return sorted_users


Template.active_project_members_indicator.helpers
  curProjectMembersLimited: ->
    return Template.instance().curProjectMembers(true)

  curProjectMembersAll: ->
    return Template.instance().curProjectMembers(false)

  hiddenMembersCount: ->
    member_ids = _.map APP.justdo_user_active_position.getProjectMembersCurrentPositionsCursor().map (ledger_doc) -> ledger_doc.UID
    member_ids_without_self = _.without member_ids, Meteor.userId()
    active_members_count = Meteor.users.find({_id: {$in: member_ids_without_self}}).fetch().length

    hiddenMembersCount = Math.max(0, active_members_count - JustdoUserActivePosition.max_visible_project_members)
    return hiddenMembersCount

  isUserInactive: ->
    tpl = Template.instance()
    tpl.check_user_inactive_dep.depend()
    return APP.justdo_user_active_position.isUserLedgerDocInactive @_id

Template.active_project_members_indicator.events
  "click .member-avatar, click .active-project-members-dropdown .dropdown-item": (e) ->
    # This functionality has been temporarily put on hold. It was decided to open a direct chat when clicking on the avatar.

    # if not APP.justdo_user_active_position.isProjectMembersCurrentOnGridPositionsTrackerEnabled()
    #   APP.justdo_user_active_position.setupProjectMembersCurrentOnGridPositionsTracker()
    # else
    #   APP.justdo_user_active_position.removeProjectMembersCurrentOnGridPositionsTracker()

    user_id = @_id

    APP.justdo_chat.generateClientUserChatChannel(user_id)

    return




Template.active_project_members_indicator.onDestroyed ->
  Meteor.clearInterval @check_user_inactive_interval
  return
