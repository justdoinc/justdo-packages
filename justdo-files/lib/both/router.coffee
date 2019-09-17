_.extend JustdoFiles.prototype,
  setupRouter: ->
    Router.route '/justdo-files', ->
      @render 'justdo_files_page'

      return
    ,
      name: 'justdo_files_page'

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        APP.modules.main.registerDrawerMenuItem "top", "justdo-files",
          data:
            html: """
              <a href="/justdo-files"><i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>PAGE NAME</a>
            """

          position: 100

          listingCondition: ->
            return true

    return