# If you want to change the vars below, update corresponding
# header.sass vars oh header.sass as well.
drawer_brand_height = 46
drawer_top_menu_padding_top = 10
drawer_top_menu_padding_bottom = 0
drawer_top_menu_item_vertical_padding = 4
drawer_top_menu_item_height = 22 + (drawer_top_menu_item_vertical_padding * 2)

APP.executeAfterAppLibCode ->
  main_module = APP.modules.main
  project_page_module = APP.modules.project_page

  Template.header.helpers
    getHeaderWidth: ->
      min_project_container_width =
        project_page_module.options?.min_project_container_dim?.width or 0

      window_dim = main_module.window_dim.get().width

      return Math.max(min_project_container_width, window_dim) - 1

    projects: -> APP.collections.Projects.find({}, {sort: {createdAt: 1}}).fetch()

    middleHeaderTemplate: -> main_module.getCustomHeaderTemplate("middle")

    rightHeaderTemplate: -> main_module.getCustomHeaderTemplate("right")

    pagesMenuItems: ->
      return main_module.getDrawerMenuItems("pages")

    bottomMenuItems: ->
      return main_module.getDrawerMenuItems("bottom")

    drawerProjectsListTop: ->
      return drawer_brand_height + drawer_top_menu_padding_top + drawer_top_menu_padding_bottom + (drawer_top_menu_item_height * (main_module.getDrawerMenuItems("pages").length + 1)) # + 1 is for the for the built-in projects list title

  Template.header.events
    "click .drawer-hamburger": (e, tmpl) ->
      $(".global-wrapper").addClass "drawer-open"

    "click .drawer-nav": (e, tmpl) ->
      $(".global-wrapper").removeClass "drawer-open"

    "click .drawer-overlay": (e, tmpl) ->
      $(".global-wrapper").removeClass "drawer-open"

    "click .create-new-project":(e, tmpl) ->
      APP.projects.createNewProject({}, (err, project_id) -> Router.go "project", {_id: project_id})
