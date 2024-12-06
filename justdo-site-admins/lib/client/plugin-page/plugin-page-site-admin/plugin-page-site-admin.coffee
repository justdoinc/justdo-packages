Template.justdo_site_admins_page_site_admin.onCreated ->
  @current_view = new ReactiveVar (@data.view_name or JustdoSiteAdmins.default_site_admin_page_view)
  # In case only /justdo-site-admins is entered in url
  Router.go "justdo_site_admins_page_#{@current_view.get().replaceAll "-", "_"}", {}, {replaceState: true}

  @menu_hidden_rv = new ReactiveVar false
  
  # Keep track of browser's prev/next page button
  @autorun =>
    if (route_name = Router.current()?.route?.getName())?
      @current_view.set route_name.replaceAll("justdo_site_admins_page_", "").replaceAll "_", "-"
    return

  return

Template.justdo_site_admins_page_site_admin.helpers
  leftDrawerItems: ->
    current_view = Template.instance().current_view
    items = _.map JD.getPlaceholderItems("site-admins-left-drawer"), (item) ->
      item.template_data.current_view = current_view
      return item
    return items

  currentView: -> Template.instance().current_view.get()

  viewTitle: ->
    current_view = Template.instance().current_view.get()
    if (title = JustdoSiteAdmins.view_name_to_title_and_template_name.get(current_view)?.title)?
      return title
    return "Loading..."

  viewTemplateName: ->
    current_view = Template.instance().current_view.get()
    if (template_name = JustdoSiteAdmins.view_name_to_title_and_template_name.get(current_view)?.template_name)?
      return template_name

  getMinWidth: ->
    main_module = APP.modules.main
    project_page_module = APP.modules.project_page

    min_project_container_width =
      project_page_module.options?.min_project_container_dim?.width or 0

    window_dim = main_module.window_dim.get().width

    return Math.max(min_project_container_width, window_dim)

  menuIsHidden: ->
    return Template.instance().menu_hidden_rv.get()


Template.justdo_site_admins_page_site_admin.events
  "click .site-admins-menu-item": (e, tpl) ->
    target = $(e.target.closest(".site-admins-menu-item")).attr "target"
    tpl.current_view.set target
    Router.go "justdo_site_admins_page_#{target.replaceAll "-", "_"}"
    return

  "click .site-admins-resize-handle": (e, tpl) ->
    tpl.menu_hidden_rv.set !tpl.menu_hidden_rv.get()

    return
