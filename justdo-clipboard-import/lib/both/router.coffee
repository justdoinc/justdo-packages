_.extend JustdoClipboardImport.prototype,
  setupRouter: ->
    ###
    Router.route '/justdo-clipboard-import', ->
      @render 'justdo_clipboard_import_page'

      return
    ,
      name: 'justdo_clipboard_import_page'

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        JD.registerPlaceholderItem "justdo-clipboard-import",
          data:
            html: """
              <a class="text-dark text-uppercase d-flex align-items-center text-decoration-none" href="/justdo-clipboard-import">
                <div class="menu-item-icon bg-primary p-2 text-white shadow-sm rounded-sm">
                  <i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>
                </div>
                #{JustdoClipboardImport.custom_page_label}
              </a>
            """

          domain: "drawer-pages"
          position: 100

          listingCondition: ->
            return true
    ###
    return