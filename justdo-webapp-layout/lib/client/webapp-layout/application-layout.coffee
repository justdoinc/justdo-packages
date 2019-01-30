APP.executeAfterAppLibCode ->
  main_module = APP.modules.main
  project_page_module = APP.modules.project_page

  initAppWrapperScolls = ->
    # Since in some situations .app-wrapper has visible scolls and in others
    # they are hidden, we need to reinit the scrolls in certain situations.
    $(".app-wrapper").scrollTop(0)
    $(".app-wrapper").scrollLeft(0)

    return

  Template.app_layout.onRendered ->
    @autorun ->
      # init app scrolls when moving between pages.

      JustdoHelpers.currentPageName() # Our reactive resource

      initAppWrapperScolls()

      return

  last_container_below_minimal_width_value = false
  Template.app_layout.helpers
    userRequirePostRegistrationInit: ->
      APP.projects.userRequirePostRegistrationInit()

    windowDimGravityOffset: ->
      custom_window_dim_offset = main_module.custom_window_dim_offset.get()
      custom_window_dim_gravity = main_module.custom_window_dim_gravity.get()

      if not /^[ns][ew]$/.test(custom_window_dim_gravity)
        custom_window_dim_gravity = "nw"
        APP.modules.main.logger.warn("Unrecognized custom_window_dim_gravity custom_window_dim_gravity using: #{custom_window_dim_gravity}")

      custom_window_dim_offset = 
        _.extend({width: 0, height: 0}, custom_window_dim_offset)

      gravity_offset = {left: 0, top: 0}

      if custom_window_dim_gravity[0] == "s"
        gravity_offset.top = custom_window_dim_offset.height

      if custom_window_dim_gravity[1] == "e"
        gravity_offset.left = custom_window_dim_offset.width

      return gravity_offset

    projectContainerBelowMinimalWidth: ->
      # Under the project page we allow the .app-wrapper to have visible scrolls
      # if the available width is too small to contain it.
      # 
      # The code here controls when it is time to allow the scrolls to show.
      # In addition, when scrolls are not needed anymore (e.g. if the window
      # resized) we make sure to init .app-wrapper scrolls (since after hiding
      # the scrolls the user might see .app-wrapper content offsetted)

      below = false
      if Router.current().route.getName() == "project"
        # Defined in 015-project-page-wireframe-manager.coffee
        below = project_page_module.projectContainerBelowMinimalWidth()

      if below == false and last_container_below_minimal_width_value == true
        initAppWrapperScolls()

      last_container_below_minimal_width_value = below

      return below
