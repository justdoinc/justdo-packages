# license = window.LICENSE
license = {'permitted_domain':'localhost','grace_period_ends':'2025-05-18','valid_until':'2025-07-01','paid_users':1}

spinning_icon = """<span class="fa fa-spinner fa-spin"></span>"""

Template.justdo_site_admin_members.onCreated ->
  self = @

  @all_site_users_rv = new ReactiveVar([])
  if license? 
    @licensed_users_crv = JustdoHelpers.newComputedReactiveVar null, ->
      all_site_users = self.all_site_users_rv.get()

      if license.unlimited_users
        return new Set(_.map(all_site_users, (user_obj) -> user_obj._id))

      licensed_users_set = new Set()
      licensed_users_count = license.licensed_users

      sortByCreatedAtPredicate = (u1, u2) ->
        if u1.createdAt > u2.createdAt
          return 1
        if u1.createdAt < u2.createdAt
          return -1
        return 0

      all_site_users
        .filter (user) -> return (not APP.accounts.isUserDeactivated user) and (not APP.accounts.isUserExcluded user)
        .sort (u1, u2) ->
          # If both users are site admins, simply sort by their createdAt
          if u1.site_admin?.is_site_admin and u2.site_admin?.is_site_admin
            return sortByCreatedAtPredicate u1, u2

          # Site admins always take precedence when compared with normal user
          if u2.site_admin?.is_site_admin
            return 1
          if u1.site_admin?.is_site_admin
            return -1

          # If both users aren't site admins, simply sort by their createdAt
          return sortByCreatedAtPredicate u1, u2
        .slice(0, licensed_users_count)
        .forEach (user) -> licensed_users_set.add user._id

      return licensed_users_set

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
    remarks: (user) ->
      remarks = []

      # Excluded remarks can co-exist with site-admin or deactivated, but not expiring/expired.
      if APP.accounts.isUserExcluded(user)
        remarks.push """<span class="badge badge-success rounded-0 mr-1">Excluded</span>"""

      if APP.justdo_site_admins.isUserSiteAdmin(user)
        remarks.push """<span class="badge badge-primary rounded-0 mr-1">Site Admin</span>"""

      if APP.justdo_site_admins.isProxyUser?(user)
        remarks.push """<span class="badge badge-info rounded-0 mr-1">Proxy User</span>"""

      user_id_deactivated = false
      if APP.accounts.isUserDeactivated(user)
        user_id_deactivated = true
        remarks.push """<span class="badge badge-secondary rounded-0 mr-1">Deactivated</span>"""

      if self.licensed_users_crv?
        if not user_id_deactivated
          # We don't check expiration for deactivated users
          if not self.licensed_users_crv.get().has(user._id) and not APP.accounts.isUserExcluded(user)
            # If user isn't licensed, check if the furthest of user grace period and license grace period has passed
            user_grace_period_ends = moment(user.createdAt).add(license.new_users_grace_period, "days")
            license_grace_period_ends = moment(license.license_grace_period, "YYYY-MM-DD")

            if (furthest_grace_period = moment(Math.max user_grace_period_ends, license_grace_period_ends)) >= moment()
              remarks.push """<span class="badge badge-warning rounded-0 mr-1">License expires on #{furthest_grace_period.format(JustdoHelpers.getUserPreferredDateFormat())}</span>"""
            else
              remarks.push """<span class="badge badge-danger rounded-0 mr-1">License expired</span>"""

      return remarks.join(" ")

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
        return (not APP.accounts.isUserDeactivated user) and (not APP.accounts.isUserExcluded user)
      .length

    if not active_user_count
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
    return license?

  unlimitedLicense: -> license.unlimited_users

  licensedUsersCount: -> Template.instance().licensed_users_crv.get().size

  licensePermittedUsers: -> license.licensed_users

  licenseValidUntil: -> moment(license.expire_on, "YYYY-MM-DD").format JustdoHelpers.getUserPreferredDateFormat()

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
