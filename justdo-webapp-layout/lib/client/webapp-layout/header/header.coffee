APP.executeAfterAppLibCode ->
  main_module = APP.modules.main
  project_page_module = APP.modules.project_page

  Template.header.helpers
    globalRightNavbarItems: ->
      return JD.getPlaceholderItems("global-right-navbar").reverse() # We reverse to have consistent order with the float right behaviour of the project-right-navbar

    getHeaderWidth: ->
      min_project_container_width =
        project_page_module.options?.min_project_container_dim?.width or 0

      window_dim = main_module.window_dim.get().width

      return Math.max(min_project_container_width, window_dim)

    drawerHeaderItems: ->
      return JD.getPlaceholderItems("drawer-header")

    drawerBeforeBodyItems: ->
      return JD.getPlaceholderItems("drawer-before-body")

    drawerBodyItems: ->
      return JD.getPlaceholderItems("drawer-body")

    middleHeaderTemplate: -> main_module.getCustomHeaderTemplate("middle")

    drawerPagesMenuItems: -> JD.getPlaceholderItems("drawer-pages")

    drawerBottomMenuItems: -> JD.getPlaceholderItems("drawer-bottom")

    drawerProjectsListTop: ->
      return drawer_brand_height + drawer_top_menu_padding_top + drawer_top_menu_padding_bottom + (drawer_top_menu_item_height * (JD.getPlaceholderItems("drawer-pages").length + 1)) # + 1 is for the for the built-in projects list title

    justDoVersion: ->
      return APP.env_rv.get()?.APP_VERSION

  JD.registerPlaceholderItem "justdo-chat-recent-activity",
    data:
      template: "justdo_chat_recent_activity_button"
      template_data: {}

    domain: "global-right-navbar"
    position: 100

  Template.header.events
    "click .drawer-icon": ->
      $(".global-wrapper").addClass "drawer-open"

    "click .create-new-project":(e, tmpl) ->
      APP.projects.createNewProject({}, (err, project_id) ->
        if err?
          JustdoSnackbar.show
            text: err.reason
          return
        Router.go "project", {_id: project_id})

      $(".global-wrapper").removeClass "drawer-open"

    "click .drawer .drawer-footer a, click .pages-section a, click .drawer-backdrop":(e, tmpl) ->
      $(".global-wrapper").removeClass "drawer-open"
