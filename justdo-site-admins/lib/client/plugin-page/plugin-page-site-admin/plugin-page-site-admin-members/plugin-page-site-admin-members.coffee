spinning_icon = """<span class="fa fa-spinner fa-spin"></span>"""

Template.justdo_site_admin_members.onCreated ->
  self = @

  @all_site_users_rv = new ReactiveVar([])

  @users_filter_term_rv = new ReactiveVar(null)

  @order_by_field_rv = new ReactiveVar(null)
  @order_by_field_desc_rv = new ReactiveVar(false)

  @refreshAllUsers = ->
    APP.justdo_site_admins.getAllUsers (err, res) =>
      if err?
        JustdoSnackbar.show
          text: "Failed to load users list: #{err.reason}"

        return

      @all_site_users_rv.set(res)

      return

    return
  @refreshAllUsers()

  @pseudo_fields =
    name: (user) -> JustdoHelpers.displayName(user)
    email: (user) -> JustdoHelpers.getUserMainEmail(user)
    remarks: (user) -> APP.justdo_site_admins._getMembersPageUserRemarks user

  @all_sorted_filtered_site_users_rv = new ReactiveVar([])
  @autorun =>
    all_site_users = @all_site_users_rv.get()

    if (users_filter_term = @users_filter_term_rv.get())?
      filter_regexp = new RegExp("\\b#{JustdoHelpers.escapeRegExp(users_filter_term)}", "i")

      all_site_users = _.filter all_site_users, (user) =>
        for pseudo_field_id, pseudo_field_def of @pseudo_fields
          if filter_regexp.test(pseudo_field_def(user))
            return true

        return false

    if (order_by_field = @order_by_field_rv.get())?
      all_site_users = JustdoHelpers.localeAwareSortCaseInsensitive all_site_users, (doc) =>
        return @pseudo_fields[order_by_field](doc)

      if (order_by_field_desc = @order_by_field_desc_rv.get())
        all_site_users.reverse()

    @all_sorted_filtered_site_users_rv.set(all_site_users)
    return

  SiteAdminUserDropdownConstructor = JustdoHelpers.generateNewTemplateDropdown "site-admin-user-dropdown", "site_admin_user_dropdown",
    custom_bound_element_options:
      close_button_html: null

    updateDropdownPosition: ($connected_element) ->
      @$dropdown
        .position
          of: $connected_element
          my: "right top"
          at: "right bottom"
          collision: "fit fit"
          using: (new_position, details) =>
            target = details.target
            element = details.element
            element.element.addClass "animate slideIn shadow-lg"
            element.element.css
              top: new_position.top - 10
              left: new_position.left + 6
            return

        $(".dropdown-menu.show").removeClass("show") # Hide active dropdown

      return

  @site_admin_user_dropdown = new SiteAdminUserDropdownConstructor()

  @site_users_pages_rv = new ReactiveVar(1)
  @users_per_page = 30
  @getShownSiteUsers = ->
    all_sorted_filtered_site_users = @all_sorted_filtered_site_users_rv.get()
    return all_sorted_filtered_site_users.slice(0, @site_users_pages_rv.get() * @users_per_page)

  return

Template.justdo_site_admin_members.onDestroyed ->
  @site_admin_user_dropdown.destroy()

  return

Template.justdo_site_admin_members.helpers
  activeUsersCount: ->
    tpl = Template.instance()
    active_user_count = tpl.all_site_users_rv.get()
      .filter (user) ->
        return (not APP.accounts.isUserDeactivated user) and (not APP.accounts.isUserExcluded? user)
      .length

    if not active_user_count?
      return spinning_icon

    return active_user_count

  filteredUsersCount: ->
    search_term = Template.instance().users_filter_term_rv.get()
    filtered_users_count = 0

    if search_term?
      filtered_users_count = Template.instance().all_sorted_filtered_site_users_rv.get().length

    return filtered_users_count

  filterIsActive: ->
    return Template.instance().users_filter_term_rv.get()?

  licensingEnabled: ->
    return LICENSE_RV?.get()?

  unlimitedLicense: -> LICENSE_RV?.get().unlimited_users

  licensedUsersCount: -> 
    users = Template.instance().all_site_users_rv.get()
    licensed_users = _.filter users, (user) -> user.licensed
    return _.size licensed_users

  licensePermittedUsers: -> LICENSE_RV?.get().licensed_users

  licenseValidUntil: -> moment(LICENSE_RV?.get().expire_on, "YYYY-MM-DD").format JustdoHelpers.getUserPreferredDateFormat()

  siteUsers: ->
    tpl = Template.instance()
    return tpl.getShownSiteUsers()

  getPseudoFieldVal: (field_id) ->
    tpl = Template.instance()

    user_obj = @

    return tpl.pseudo_fields[field_id](user_obj)

  getPseudoRemarksVal: (field_id) -> # Because we need the xssGuard we can't use getPseudoFieldVal that takes an argument
    tpl = Template.instance()

    user_obj = @

    return tpl.pseudo_fields["remarks"](user_obj)

  getSortByIcon: (field_id) ->
    tpl = Template.instance()

    if field_id == tpl.order_by_field_rv.get()
      if tpl.order_by_field_desc_rv.get()
        return JustdoHelpers.xssGuard("""<i class="fa fa-chevron-up"></i>""", {allow_html_parsing: true, enclosing_char: ""})
      else
        return JustdoHelpers.xssGuard("""<i class="fa fa-chevron-down"></i>""", {allow_html_parsing: true, enclosing_char: ""})

    return

  orderByFieldDesc: ->
    return Template.instance().order_by_field_desc_rv.get()

  activeFilter: ->
    return Template.instance().order_by_field_rv.get()

Template.justdo_site_admin_members.events
  "keyup .users-filter": (e, tpl) ->
    $input = $(e.target).closest(".users-filter")

    if not _.isEmpty(users_filter_term = $input.val().trim())
      tpl.users_filter_term_rv.set users_filter_term
    else
      tpl.users_filter_term_rv.set null

    tpl.site_users_pages_rv.set 1
    $(".site-admins-content").animate { scrollTop: 0 }, "fast"

    return

  "click .users-filter-clear": (e, tpl) ->
    tpl.users_filter_term_rv.set null
    $(".users-filter").val ""

    return

  "click .refresh-site-users": (e, tpl) ->
    return tpl.refreshAllUsers()

  "click .sort-by": (e, tpl) ->
    sort_by = $(e.target).closest(".sort-by").attr("sort-by")

    tpl.order_by_field_rv.set(sort_by)

    if tpl.order_by_field_desc_rv.get() == true
      tpl.order_by_field_desc_rv.set(false)
    else
      tpl.order_by_field_desc_rv.set(true)

    return

  "click .site-admins-list-item-action": (e, tpl) ->
    e.stopPropagation()
    tpl.site_admin_user_dropdown.$connected_element = $(e.currentTarget)
    tpl.site_admin_user_dropdown.template_data = {"all_site_users_rv": tpl.all_site_users_rv, "user_data": @, "dropdown": tpl.site_admin_user_dropdown}
    tpl.site_admin_user_dropdown.openDropdown()

    return

  "scroll .site-admins-content": (e, tpl) ->
    $target = $(e.target).closest(".site-admins-content")
    if $target.scrollTop() + $target.innerHeight() >= $('.site-admins-table').innerHeight()
      if tpl.users_per_page * tpl.site_users_pages_rv.get() < tpl.all_sorted_filtered_site_users_rv.get().length
        tpl.site_users_pages_rv.set(tpl.site_users_pages_rv.get() + 1)

    return