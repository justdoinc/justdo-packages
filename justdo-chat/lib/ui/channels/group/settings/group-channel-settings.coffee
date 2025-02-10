Template.group_channel_settings.onCreated ->
  @channel = @data?.channel
  @channel_members_doc_rv = new ReactiveVar [Meteor.userId()]   
  
  @project_id = @channel?.getChannelIdentifier()?.project_id or JD.activeJustdoId()
  @project_members_doc_rv = new ReactiveVar []

  @members_to_add_rv = new ReactiveVar @data?.members_to_add or []
  @members_to_remove_rv = new ReactiveVar []

  @autorun =>
    channel_members_ids = _.uniq [Meteor.userId()].concat(_.map @channel?.getSubscribersArray(), (subscriber) -> subscriber.user_id)
    @channel_members_doc_rv.set JustdoHelpers.getUsersDocsByIds(channel_members_ids)

    project_member_ids = _.map APP.collections.Projects.findOne(@project_id, {fields: {members: 1}})?.members, (member) -> member.user_id
    project_member_ids = _.without project_member_ids, ...channel_members_ids
    @project_members_doc_rv.set JustdoHelpers.getUsersDocsByIds project_member_ids
    return
  
  @disabledReason = (action_id, user_id) ->
    is_channel_exists = @channel?
    is_user_channel_admin = if is_channel_exists then @channel.isPerformingUserAdmin() else true

    if action_id is "keep-users" # Remove
      if user_id is Meteor.userId()
        if not is_channel_exists
          return "You can't remove yourself from the channel you're creating"
        else
          channel_admin_ids = @channel?.getAdminIds() or []
          if (_.size(channel_admin_ids) is 1) and (channel_admin_ids[0] is Meteor.userId())
            return "You can't remove yourself from the channel because you are the only admin"

    return

  return

Template.group_channel_settings.helpers
  sections: ->
    tpl = Template.instance()

    if not (tpl.channel?) or (tpl.channel?.isPerformingUserAdmin())
      ret =
        [
          {
            action_id: "add-users"
            caption: TAPi18n.__ "member_management_dialog_add_members"
            action_users_reactive_var: tpl.project_members_doc_rv
            no_members_msg: "No members to add"
          },
          {
            action_id: "keep-users"
            caption: TAPi18n.__ "members_management_dialog_keep_members"
            action_users_reactive_var: tpl.channel_members_doc_rv
            no_members_msg: "This channel doesn't have any members"
          }
        ]
    else
      ret =
        [
          {
            action_id: "keep-users"
            caption: TAPi18n.__ "members_management_dialog_members"
            action_users_reactive_var: tpl.channel_members_doc_rv
            no_members_msg: "This channel doesn't have any members"
          }
        ]

    return ret

  title: ->
    channel = Template.instance().channel
    return channel?.getChannelTitle() or ""

  description: ->
    channel = Template.instance().channel
    return channel?.getChannelDescription() or ""
  
  projectId: ->
    return Template.instance().project_id
  
  existingMembers: ->
    tpl = Template.instance()

    return tpl.channel_members_doc_rv.get()
  
Template.group_channel_members_editor.onCreated ->
  @getMainTemplate = =>
    return Template.closestInstance("group_channel_settings")

  return

Template.group_channel_members_editor.helpers
  # Currently only the channel associated project members can be group channel members.
  users: ->
    return @action_users_reactive_var.get()

Template.group_channel_members_editor.events
  "click .user-btn": (e, tpl) ->
    main_tpl = tpl.getMainTemplate()
    user_id = @_id
    channel_members = main_tpl.channel_members_doc_rv.get()
    is_user_channel_member = _.find(channel_members, (user_doc) -> user_doc._id is user_id)?

    # No effect on non-admins
    if (main_tpl.channel?) and (not main_tpl.channel.isPerformingUserAdmin())
      return
    
    if (disabled_reason = main_tpl.disabledReason tpl.data.action_id, user_id)?
      JustdoSnackbar.show 
        text: disabled_reason
      return

    if is_user_channel_member
      action = "remove"
    else
      action = "add"
    members_to_add_or_remove = main_tpl["members_to_#{action}_rv"].get()

    if user_id in members_to_add_or_remove
      members_to_add_or_remove = _.without members_to_add_or_remove, user_id
    else
      members_to_add_or_remove.push user_id

    main_tpl["members_to_#{action}_rv"].set members_to_add_or_remove

    return


Template.group_channel_settings_user_btn.onCreated ->
  @getMainTemplate = =>
    return Template.closestInstance("group_channel_settings")

  return

Template.group_channel_settings_user_btn.helpers
  disabledReason: ->
    tpl = Template.instance()
    main_tpl = tpl.getMainTemplate()
    return main_tpl.disabledReason Template.parentData().action_id, @_id

  isUserChannelAdmin: ->
    main_tpl = Template.instance().getMainTemplate()
    if not (channel = main_tpl.channel)?
      return true
    
    return channel.isPerformingUserAdmin()

  showYouIfIsOwner: ->
    if @_id is Meteor.userId()
      return "(#{JustdoHelpers.ucFirst TAPi18n.__ "you"})"

    return ""

  isChannelMember: ->
    if @_id is Meteor.userId()
      return true

    tpl = Template.instance()
    channel_members = tpl.getMainTemplate().channel_members_doc_rv.get()
    return _.find(channel_members, (member) => member._id is @_id)?
  
  isMemberToAdd: ->
    tpl = Template.instance()
    members_to_add = tpl.getMainTemplate().members_to_add_rv.get()
    return @_id in members_to_add
  
  isMemberToRemove: ->
    tpl = Template.instance()
    members_to_remove = tpl.getMainTemplate().members_to_remove_rv.get()
    return @_id in members_to_remove