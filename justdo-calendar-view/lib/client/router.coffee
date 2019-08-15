_.extend JustdoCalendarView.prototype,
  setupRouter: ->
    Router.route '/justdo-calendar-view', ->
      @render 'justdo_calendar_view_page'

      return
    ,
      name: 'justdo_calendar_view_page'

    if Meteor.isClient
      APP.executeAfterAppLibCode ->
        APP.modules.main.registerDrawerMenuItem "top", "justdo-calendar-view",
          data:
            html: """
              <a href="/justdo-calendar-view"><i class="fa fa-fw fa-handshake-o icons" aria-hidden="true"></i>PAGE NAME</a>
            """

          position: 100

          listingCondition: ->
            return true

    return