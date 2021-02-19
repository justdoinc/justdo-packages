Template.members_multi_selector_widget.onCreated ->
  tpl = @

  tpl.search_input_rv = new ReactiveVar null
  tpl.filtered_members_rv = new ReactiveVar null

  tpl.autorun ->
    members = Template.currentData().members
    if members? and not (Tracker.nonreactive -> tpl.filtered_members_rv.get())?
      tpl.filtered_members_rv.set members

  tpl.autorun ->
    filtered_members = tpl.filtered_members_rv.get()

    if tpl.data.onItemsChange?
      tpl.data.onItemsChange filtered_members
    
    return

  return

Template.members_multi_selector_widget.onRendered ->
  tpl = @
  $(".calendar-member-selector").on "shown.bs.dropdown", ->
    $(".calendar-member-selector-search").focus().val ""
    tpl.search_input_rv.set null
    return

  return

Template.members_multi_selector_widget.helpers
  filteredMembers: (members) ->    
    tpl = Template.instance()

    if not (search_input = tpl.search_input_rv.get())?
      return members

    return JustdoHelpers.filterUsersIdsArray(members, search_input)

  memberInFilter: (user_id) ->
    tpl = Template.instance()
    filtered_members = tpl.filtered_members_rv.get()
    return filtered_members.includes user_id

  memberAvatar: (user_id) ->
    user = Meteor.users.findOne(user_id)
    if user?
      return JustdoAvatar.showUserAvatarOrFallback(user)
  
  memberName: (user_id) ->
    return JustdoHelpers.displayName(user_id)

  memberFilterIsActive: ->
    tpl = Template.instance()
    filtered_members = tpl.filtered_members_rv.get()
    if filtered_members.length > 0
      return true
    else
      return false

Template.members_multi_selector_widget.events
  "keyup .calendar-member-selector-search": (e, tpl) ->
    value = $(e.target).val().trim()
    if _.isEmpty value
      tpl.search_input_rv.set null
    else
      tpl.search_input_rv.set value
    return

  "keydown .calendar-member-selector .dropdown-menu": (e, tpl) ->
    $dropdown_item = $(e.target).closest(".calendar-member-selector-search,.dropdown-item")

    if e.keyCode == 38 # Up
      e.preventDefault()
      if ($prev_item = $dropdown_item.prevAll(".dropdown-item").first()).length > 0
        $prev_item.focus()
      else
        $(".calendar-member-selector-search").focus()

    if e.keyCode == 40 # Down
      e.preventDefault()
      $dropdown_item.nextAll(".dropdown-item").first().focus()

    if e.keyCode == 27 # Escape
      $(".calendar-member-selector .dropdown-menu").dropdown "hide"

    return
  
  "click .calendar-members-show-all": (e, tpl) ->
    e.stopPropagation()

    tpl.filtered_members_rv.set tpl.data.members
    return
  
  "click .calendar-members-show-none": (e, tpl) ->
    e.stopPropagation()
    tpl.filtered_members_rv.set []
    return
  
  "click .calendar-filter-member-item": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()

    user_id = Blaze.getData(e.target)
    filtered_members = tpl.filtered_members_rv.get()

    if (index = filtered_members.indexOf user_id) > -1
      filtered_members.splice(index, 1)
    else
      filtered_members.push user_id

    tpl.filtered_members_rv.set filtered_members

    return