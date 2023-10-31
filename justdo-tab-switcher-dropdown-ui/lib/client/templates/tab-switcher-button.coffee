APP.executeAfterAppLibCode ->
  project_page_module = APP.modules.project_page

  Template.project_operations_tab_switcher.onRendered ->
    @tab_switcher_dropdown = new share.TabSwitcherDropdown(@firstNode)
    return

  Template.project_operations_tab_switcher.helpers
    ready: -> project_page_module.getCurrentTabId()?

    getCurrentSectionItem: ->
      return APP.modules.project_page.tab_switcher_manager.getCurrentSectionItem()

  Template.project_operations_tab_switcher.events
    "mouseup button": (e, tpl) ->
      Meteor.defer ->
        # Focus the search input when dropdown is opened
        if $(".views-search-input").is(":visible")
          $(".views-search-input").val("").trigger("change")
          Tracker.flush() # To refresh the list with the new filter.
          $(".views-search-input").focus()

        return

      return

  Template.project_operations_tab_switcher.onDestroyed ->
    @tab_switcher_dropdown?.destroy()
    return
