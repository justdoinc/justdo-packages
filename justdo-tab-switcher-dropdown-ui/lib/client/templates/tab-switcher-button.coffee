APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.project_operations_tab_switcher.helpers
    ready: -> module.getCurrentTabId()?

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
