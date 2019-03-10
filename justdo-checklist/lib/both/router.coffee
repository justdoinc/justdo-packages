_.extend JustdoChecklist.prototype,
  setupRouter: ->
    Router.route '/justdo-checklist', ->
      @render 'justdo_checklist_page'

      return
    ,
      name: 'justdo_checklist_page'

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        APP.modules.main.registerDrawerMenuItem "top", "justdo-checklist",
          data:
            html: """
              <a href="/justdo-checklist"><i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>PAGE NAME</a>
            """

          position: 100

          listingCondition: ->
            return true

    return