Template.member_list_widget.onCreated ->
  tpl = @
  tpl.members_rv = new ReactiveVar []
  tpl.members_search_niddle_rv = new ReactiveVar ""

  @clearSearch = ->
    tpl.$(".search-box").val ""
    tpl.members_search_niddle_rv.set ""
    
    return

  @autorun ->
    tpl_data = Template.currentData()
    search_niddle = tpl.members_search_niddle_rv.get()

    members = JustdoHelpers.filterUsersIdsArray(tpl_data.members or [], search_niddle)
    
    special_options = tpl_data.special_options or []
    filter_regexp = JustdoHelpers.createUnicodeSupportedSearchTermRegex search_niddle
    special_options = _.filter special_options, (opt) ->
      return filter_regexp.test(opt._id) or filter_regexp.test(opt.label)

    tpl.members_rv.set special_options.concat(members)

    return
  
  @autorun ->
    tpl_data = Template.currentData()
    
    function_caller = tpl_data?.function_caller_rv?.get()
    
    if function_caller?
      tpl[function_caller[0]].apply tpl, function_caller.slice(1)
      
      tpl_data.function_caller_rv.set null
    
    return


  return

Template.member_list_widget.helpers
  members: ->
    return Template.instance().members_rv.get()
  
  memberAvatar: (user) ->
    return JustdoAvatar.showUserAvatarOrFallback(user)
  
  memberName: (user) ->
    return user.label or JustdoHelpers.displayName(user)

Template.member_list_widget.events
  "keyup .search-box": (e, tpl) ->
    val = $(e.target).closest(".search-box").val()
    tpl.members_search_niddle_rv.set val
    return
  
  "click .member-item": (e, tpl) ->
    user_id = $(e.target).closest(".member-item").data("user-id")
    if tpl.data?.onMemberClick?
      tpl.data.onMemberClick user_id
    return