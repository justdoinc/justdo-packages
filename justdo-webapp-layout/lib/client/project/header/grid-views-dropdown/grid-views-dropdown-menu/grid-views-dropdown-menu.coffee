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
    tpl = @
    tpl.active_grid_view_rv = new ReactiveVar {}
    tpl.rename_grid_view_id_rv = new ReactiveVar null
    tpl.search_val_rv = new ReactiveVar null

    tpl.updateViewTitle = ->
      active_view = tpl.active_grid_view_rv.get()
      new_title = $(".dropdown-item-rename-input").val()
      APP.justdo_grid_views.upsert active_view._id, {title: new_title}
      tpl.rename_grid_view_id_rv.set null

      return

    return

  Template.grid_views_dropdown_menu.onRendered ->
    $(".grid-views-search-input").focus()

    return

  Template.grid_views_dropdown_menu.helpers
    gridViews: ->
      views = APP.collections.GridViews.find().fetch()

      if (search_val = Template.instance().search_val_rv.get())?
        filter_regexp = new RegExp("\\b#{JustdoHelpers.escapeRegExp(search_val)}", "i")
        views = _.filter views, (view) -> filter_regexp.test(view.title)

      return views

    activeView: ->
      return Template.instance().active_grid_view_rv.get()

    showRenameInput: ->
      return Template.instance().rename_grid_view_id_rv.get() == @_id

  Template.grid_views_dropdown_menu.events
    "keyup .grid-views-search-input": (e, tpl) ->
      search_val = $(".grid-views-search-input").val().trim()

      if _.isEmpty search_val
        tpl.search_val_rv.set null

      tpl.search_val_rv.set search_val

      return

    "focus .grid-views-search-input": (e, tpl) ->
      tpl.rename_grid_view_id_rv.set null

      return

    "click .grid-views-add": (e, tpl) ->
      tpl.rename_grid_view_id_rv.set null

      APP.justdo_grid_views.upsert null, {
        title: "View, " + moment(new Date()).format("MMM D") + ", " + moment(new Date()).format("HH:mm")
        shared: true
        hierarchy: {type: "justdo", justdo_id: JD.activeJustdoId()}
        view: APP.modules.project_page.mainGridControl().getView()
      }, (error) =>
        if error
          console.log error.reason
        else
          Meteor.defer ->
            $views_wrapper = $(".dropdown-items-wrapper")
            $views_wrapper.animate { scrollTop: $views_wrapper.prop("scrollHeight")}, 500

        return

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
      tpl.rename_grid_view_id_rv.set null

      $el = $(e.target).closest ".dropdown-item-settings"
      position_left = $el.position().left
      position_top = $el.position().top
      $(".grid-view-settings-dropdown").css({top: position_top, left: position_left}).addClass "open"

      return

    "click .grid-views-dropdown-menu-wrapper": (e, tpl) ->
      dropdown_item_settings = $(e.target).parents(".dropdown-item-settings")

      if not dropdown_item_settings[0]
        $(".grid-view-settings-dropdown").removeClass "open"

      return

    "click .grid-view-share": (e, tpl) ->
      active_view = tpl.active_grid_view_rv.get()
      APP.justdo_grid_views.upsert active_view._id, {shared: !active_view.shared}

      return

    "click .grid-view-delete": (e, tpl) ->
      active_view = tpl.active_grid_view_rv.get()
      APP.justdo_grid_views.upsert active_view._id, {deleted: true}

      return

    "click .grid-view-rename": (e, tpl) ->
      active_view = tpl.active_grid_view_rv.get()
      tpl.rename_grid_view_id_rv.set active_view._id

      Meteor.defer ->
        tpl.$(".dropdown-item-rename-input").focus()

      return

    "keydown .dropdown-item-rename-input": (e, tpl) ->
      if e.key == "Enter"
        tpl.updateViewTitle()

      return

    "click .dropdown-item-rename-save": (e, tpl) ->
      tpl.updateViewTitle()

      return

    "click .dropdown-item-rename-cancel": (e, tpl) ->
      tpl.rename_grid_view_id_rv.set null

      return

  return
