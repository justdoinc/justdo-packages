Template.members_multi_selector_widget.onCreated ->
  tpl = @

  tpl.search_input_rv = new ReactiveVar null
  tpl.filtered_members_rv = new ReactiveVar null  # member ids array
  tpl.show_dropdown_menu_rv = new ReactiveVar false

  tpl.autorun ->
    members = Template.currentData().members
    if members? and not (Tracker.nonreactive -> tpl.filtered_members_rv.get())?
      if (default_selected_members = (Tracker.nonreactive -> Template.currentData().default_selected_members))?
        tpl.filtered_members_rv.set default_selected_members
      else
        tpl.filtered_members_rv.set members.slice()
    
    return

  tpl.autorun ->
    filtered_members = tpl.filtered_members_rv.get()

    if tpl.data.onItemsChange?
      tpl.data.onItemsChange filtered_members
    
    return

  return

Template.members_multi_selector_widget.onRendered ->
  tpl = @
  $(".members-multi-selector").on "show.bs.dropdown", ->
    tpl.show_dropdown_menu_rv.set true
    return

  $(".members-multi-selector").on "shown.bs.dropdown", ->
    $(".members-multi-selector-search").focus().val ""
    tpl.search_input_rv.set null
    return
  
  $(".members-multi-selector").on "hidden.bs.dropdown", ->
    tpl.show_dropdown_menu_rv.set false
    return

  return

Template.members_multi_selector_widget.helpers
  showDropdownMenu: -> Template.instance().show_dropdown_menu_rv.get()

  filteredMembers: (members) ->    
    tpl = Template.instance()

    search_input = tpl.search_input_rv.get()

    return JustdoHelpers.filterUsersIdsArray(members, search_input)

  memberInFilter: (user) ->
    tpl = Template.instance()
    filtered_members = tpl.filtered_members_rv.get()
    return filtered_members.includes user._id

  memberAvatar: (user) ->
    user = Meteor.users.findOne(user._id)
    if user?
      return JustdoAvatar.showUserAvatarOrFallback(user)
  
  memberName: (user) ->
    return JustdoHelpers.displayName(user._id)

  memberFilterIsActive: ->
    tpl = Template.instance()
    filtered_members = tpl.filtered_members_rv.get()
    if filtered_members.length > 0
      return true
    else
      return false

Template.members_multi_selector_widget.events
  "keyup .members-multi-selector-search": (e, tpl) ->
    value = $(e.target).val().trim()
    if _.isEmpty value
      tpl.search_input_rv.set null
    else
      tpl.search_input_rv.set value
    return

  "keydown .members-multi-selector .dropdown-menu": (e, tpl) ->
    $dropdown_item = $(e.target).closest(".members-multi-selector-search,.dropdown-item")

    if e.keyCode == 38 # Up
      e.preventDefault()
      if ($prev_item = $dropdown_item.prevAll(".dropdown-item").first()).length > 0
        $prev_item.focus()
      else
        $(".members-multi-selector-search").focus()

    if e.keyCode == 40 # Down
      e.preventDefault()
      $dropdown_item.nextAll(".dropdown-item").first().focus()

    if e.keyCode == 27 # Escape
      $(".members-multi-selector .dropdown-menu").dropdown "hide"

    return
  
  "click .members-selector-show-all": (e, tpl) ->
    e.stopPropagation()

    tpl.filtered_members_rv.set tpl.data.members.slice()
    
    return
  
  "click .members-selector-show-none": (e, tpl) ->
    e.stopPropagation()
    tpl.filtered_members_rv.set []
    return
  
  "click .members-selector-filter-member-item": (e, tpl) ->
    e.preventDefault()
    e.stopPropagation()

    user_id = Blaze.getData(e.target)._id
    filtered_members = tpl.filtered_members_rv.get()

    if (index = filtered_members.indexOf user_id) > -1
      filtered_members.splice(index, 1)
    else
      filtered_members.push user_id

    tpl.filtered_members_rv.set filtered_members

    return
    