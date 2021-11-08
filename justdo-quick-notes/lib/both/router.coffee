_.extend JustdoQuickNotes.prototype,
  setupRouter: ->
    Router.route "/justdo-quick-notes", ->
      @render "justdo_quick_notes_page"

      return
    ,
      name: "justdo_quick_notes_page"

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        JD.registerPlaceholderItem "justdo-quick-notes",
          data:
            html: """
              <a class="text-dark text-uppercase d-flex align-items-center text-decoration-none" href="/justdo-quick-notes">
                <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
                  <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
                </div>
                #{JustdoQuickNotes.custom_page_label}
              </a>
            """

          domain: "drawer-pages"
          position: 100

          listingCondition: ->
            return true

    return