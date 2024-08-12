Template.justdo_site_admins_page_non_site_admin.onCreated ->
  @all_site_admins_ids_rv = new ReactiveVar([])

  @refreshAllSiteAdminsIds = ->
    APP.justdo_site_admins.getAllSiteAdminsIds (err, res) =>
      if err?
        JustdoSnackbar.show
          text: "Failed to load Site Admins list: #{err.reason}"

        return

      @all_site_admins_ids_rv.set(res)

      return

    return
  @refreshAllSiteAdminsIds()

  return

Template.justdo_site_admins_page_non_site_admin.helpers
  siteAdmins: ->
    tpl = Template.instance()

    return JustdoHelpers.getUsersDocsByIds(tpl.all_site_admins_ids_rv.get())

Template.justdo_site_admins_page_non_site_admin.events
  "click .refresh-site-admins": (e, tpl) ->
    return tpl.refreshAllSiteAdminsIds()
