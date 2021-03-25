Template.meetings_meeting_members.helpers
  box_grid: ->
    cols: 16 + 1 # Meeting dialog has fixed-width 680px. 16 (users) + 1 (add user button) it's a Max count the dialog can contain

  primary_users: -> [@organizer_id]

  secondary_users: -> _.without @users, @organizer_id

  show_button: -> if not @locked or @organizer_id == Meteor.userId() then "always" else "never"

Template.meetings_meeting_members.events
  "click .avatar-box-button": (e, tmpl) ->
    template_data = tmpl.data
    message_template =
      APP.helpers.renderTemplateInNewNode(Template.meetings_meeting_members_editor, template_data)

    bootbox.dialog
      title: "Edit Meeting Participants"
      message: message_template.node
      animate: false
      className: "members-editor-dialog bootbox-new-design"

      onEscape: ->
        return true

      buttons:
        cancel:
          label: "Cancel"

          className: "btn-light"

          callback: ->
            return true

        submit:
          label: "Save"
          callback: =>
            members_to_remove = _getMembersIdsInReactiveVarByProceedState(users_to_keep, false)
            members_to_add = _getMembersIdsInReactiveVarByProceedState(users_to_add, true)

            if _.isEmpty(members_to_remove) and _.isEmpty(members_to_add)
              # Nothing to do
              return true

            if members_to_add?.length != 0
              APP.meetings_manager_plugin.meetings_manager.addUsersToMeeting template_data._id, members_to_add

            if members_to_remove?.length != 0
              APP.meetings_manager_plugin.meetings_manager.removeUsersFromMeeting template_data._id, members_to_remove
#
# Editor dialog
#

# Note: we assume only one confirmation dialog at a time
users_to_keep = new ReactiveVar null
users_to_add = new ReactiveVar null
cascade = new ReactiveVar true
notes = new ReactiveVar {}, JustdoHelpers.jsonComp

_getUsersDocsByIdsWithProceedFlag = (members_array, default_proceed_val=true) ->
  # Returns APP.helpers.getUsersDocsByIds(members_array) output with
  # a `proceed` property assigned to each user doc.
  # The `proceed` property will have a reactive variable initiated to
  # default_proceed_val value


  # Note, _getUsersDocsByIdsWithProceedFlag is called outside of a computation
  # se we don't need to worry about reactivity and its consequence on proceed
  # values upon invalidations
  members = APP.helpers.getUsersDocsByIds(members_array)

  for member in members
    member.proceed = new ReactiveVar default_proceed_val

  return JustdoHelpers.filterUsersDocsArray members, null

_setProceedStateForAllUsersInReactiveVar = (reactive_var, state) ->
  members = reactive_var.get()

  for member in members
    member.proceed.set state

_getMembersIdsInReactiveVarByProceedState = (reactive_var, proceed_state=true) ->
  return _.map(_.filter(reactive_var.get(), (item) -> item.proceed.get() == proceed_state), (item) -> item._id)

Template.meetings_meeting_members_editor.onCreated ->
  data = @data

  module = APP.modules.project_page

  if not (item_users = data.users)?
    throw module._error("unknown-data-context", "can't determine current task user")
  _users_to_keep = _.without item_users, Meteor.userId(), data.organizer_id

  if not (project_members = (project = module.curProj())?.getMembersIds())?
    throw module._error("unknown-data-context", "can't determine project members")
  _users_to_add = _.difference project_members, item_users

  users_to_keep.set _getUsersDocsByIdsWithProceedFlag(_users_to_keep, true)
  users_to_add.set _getUsersDocsByIdsWithProceedFlag(_users_to_add, false)
  cascade.set true
  notes.set {}

  return

Template.meetings_meeting_members_editor.helpers
  users_to_keep: users_to_keep.get()
  users_to_add: users_to_add.get()
  sections: ->
    [
      {
        action_id: "keep-users"
        caption: "Current Participants:"
        action_users_reactive_var: users_to_keep
        proceed_message: "Keep"
        dont_proceed_message: "Remove"
        proceed_status_fa_icon: null
        dont_proceed_status_fa_icon: "fa-times"
      },
      {
        action_id: "add-users"
        caption: "Add Participants:"
        action_users_reactive_var: users_to_add
        proceed_message: "Add"
        dont_proceed_message: "Don't add"
        proceed_status_fa_icon: "fa-check"
        dont_proceed_status_fa_icon: null
      }
    ]
  cascade: -> cascade.get()
  display_notes_section: -> not _.isEmpty notes.get()
  notes: ->
    return

Template.meetings_meeting_members_editor.events
  "change .cascade-action-checkbox": (e) ->
    checked = e.target.checked

    if checked
      cascade.set true
    else
      cascade.set false

Template.meetings_meeting_members_editor.onDestroyed ->
  users_to_keep.set null
  users_to_add.set null
  cascade.set true
  notes.set {}

#
# Editor dialog sections
#
Template.meetings_meeting_members_editor_section.helpers
  perform_action: -> @proceed_action_reactive_var.get()
  action_users: -> @action_users_reactive_var.get()

Template.meetings_meeting_members_editor_section.events
  "click .select-all": ->
    _setProceedStateForAllUsersInReactiveVar @action_users_reactive_var, true

  "click .select-none": ->
    _setProceedStateForAllUsersInReactiveVar @action_users_reactive_var, false

#
# Editor dialog section user button
#
Template.meetings_meeting_members_editor_user_btn.onCreated ->
  @user_doc = JustdoHelpers.getUsersDocsByIds @data._id

Template.meetings_meeting_members_editor_user_btn.helpers
  user_doc: -> Template.instance().user_doc
  proceed_message: -> Template.parentData(1).proceed_message
  dont_proceed_message: -> Template.parentTemplate.parentData(1).dont_proceed_messageData(1).dont_proceed_message
  status_fa_icon: ->
    if @proceed.get()
      return Template.parentData(1).proceed_status_fa_icon

    return Template.parentData(1).dont_proceed_status_fa_icon

  btn_title: ->
    user_doc = Template.instance().user_doc

    display_name = JustdoHelpers.displayName(user_doc)
    if @proceed.get()
      message = Template.parentData(1).dont_proceed_message
    else
      message = Template.parentData(1).proceed_message

    return "#{message} #{display_name}"

Template.meetings_meeting_members_editor_user_btn.events
  "click .user-btn": (e) ->
    current_state = @proceed.get()
    new_state = not current_state

    @proceed.set(new_state)

    return
