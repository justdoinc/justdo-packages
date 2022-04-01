APP.executeAfterAppLibCode ->
  share.GridViewsDropdown = JustdoHelpers.generateNewTemplateDropdown "grid-views-dropdown-menu", "grid_views_dropdown_menu",
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
              top: new_position.top - 11
              left: new_position.left

        $(".dropdown-menu.show").removeClass("show")

      return

  Template.grid_views_dropdown_menu.onCreated ->
    @active_grid_view_rv = new ReactiveVar null
    @rename_grid_view_id_rv = new ReactiveVar null

    return

  Template.grid_views_dropdown_menu.onRendered ->
    $(".grid-views-search-input").focus()

    return

  Template.grid_views_dropdown_menu.helpers
    gridViews: ->
      return APP.collections.GridViews.find().fetch()

    activeView: ->
      return Template.instance().active_grid_view_rv.get()

    showRenameInput: ->
      return Template.instance().rename_grid_view_id_rv.get() == @_id

  Template.grid_views_dropdown_menu.events
    "click .grid-views-add": (e, tpl) ->
      APP.justdo_grid_views.upsert null, {
        title: "View, " + moment(new Date()).format("MMM d") + ", " + moment(new Date()).format("HH:mm")
        shared: true
        hierarchy: {type: "justdo", justdo_id: JD.activeJustdoId()}
        view: APP.modules.project_page.mainGridControl().getView()
      }

      return

    "click .grid-view-item": (e, tpl) ->
      tpl.active_grid_view_rv.set APP.collections.GridViews.findOne @

      return

    "click .grid-view-item .dropdown-item-label": (e, tpl) ->
      view = EJSON.parse @view
      APP.modules.project_page.mainGridControl().setView view
      $(".grid-views-dropdown-menu").removeClass "open"

      return

    "click .dropdown-item-settings": (e, tpl) ->
      $el = $(e.currentTarget).closest ".dropdown-item-settings"
      position_left = $el.position().left
      position_top = $el.position().top
      $(".grid-view-settings-dropdown").css({top: position_top, left: position_left}).addClass "open"

      return

    "click .grid-views-dropdown-menu-wrapper": (e, tpl) ->
      dropdown_item_settings = $(e.target).parents(".dropdown-item-settings")

      if not dropdown_item_settings[0]
        $(".grid-view-settings-dropdown").removeClass "open"

      return

    "click .grid-view-rename": (e, tpl) ->
      active_view = tpl.active_grid_view_rv.get()
      tpl.rename_grid_view_id_rv.set active_view._id

      Meteor.defer ->
        tpl.$(".dropdown-item-rename-input").focus()

      return

    "click .grid-view-share": (e, tpl) ->
      active_view = tpl.active_grid_view_rv.get()
      APP.justdo_grid_views.upsert active_view._id, {shared: !active_view.shared}

      return

    "click .grid-view-delete": (e, tpl) ->
      active_view = tpl.active_grid_view_rv.get()
      APP.justdo_grid_views.upsert active_view._id, {deleted: true}

      return

  return
