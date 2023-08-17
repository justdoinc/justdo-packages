APP.executeAfterAppLibCode ->
  Template.tutorials.onCreated ->
    @request_sent = new ReactiveVar false

    @tutorials = new ReactiveVar [
      {
        "title": "set_justdo_name_title",
        "subtitle": "set_justdo_name_subtitle",
        "media": "/packages/justdoinc_justdo-tutorials/lib/client/project-header-tutorial/tutorials/media/set_name.mp4"
        "status": "" # pending, done
      },
      {
        "title": "create_first_task_title",
        "subtitle": "create_first_task_subtitle",
        "media": "/packages/justdoinc_justdo-tutorials/lib/client/project-header-tutorial/tutorials/media/create_task.mp4"
        "status": "pending"
      },
      {
        "title": "import_tasks_title",
        "subtitle": "import_tasks_subtitle",
        "media": "/packages/justdoinc_justdo-tutorials/lib/client/project-header-tutorial/tutorials/media/import_tasks.mp4"
        "status": "pending"
      },
      {
        "title": "customize_columns_title",
        "subtitle": "customize_columns_subtitle",
        "media": "/packages/justdoinc_justdo-tutorials/lib/client/project-header-tutorial/tutorials/media/customize_view.mp4"
        "status": "pending"
      }
    ]

    return

  Template.tutorials.onRendered ->
    $(".nav-tutorials.dropdown").on "hidden.bs.dropdown", ->
      $(".tutorial-item").removeClass "active"

      return

    return

  Template.tutorials.helpers
    tutorials: ->
      tutorials = Template.instance().tutorials.get()

      for tutorial, i in tutorials
        tutorial.index = i + 1

      return tutorials

    tutorialIsDone: ->
      return @status == "done"

    promoUnlocked: ->
      tutorials = Template.instance().tutorials.get()

      for tutorial in tutorials
        if tutorial.status != "done"
          return false

      return true

    requestSent: ->
      return Template.instance().request_sent.get()

  Template.tutorials.events
    "click .tutorials-wrapper .tutorial-item": (e, tpl) ->
      e.stopPropagation()

      return

    "mouseenter .tutorial-item": (e, tpl) ->
      $(".tutorial-item").removeClass "active"
      $(e.target).closest(".tutorial-item").addClass "active"
      media = $(e.target).find(".tutorial-media")[0]

      if media
        media.play()
        media.playbackRate = 1.5

      if APP.justdo_google_analytics?
        target = "text"
        if media
          target = "media"
        payload = 
          lang: APP.justdo_i18n?.getLang()
          tutorial_title: @title
        
        APP.justdo_google_analytics.sendEvent "tutorial-dropdown-mouseenter-tutorial-#{target}", payload

      return

    "click .tutorial-instruction-btn .btn": (e, tpl) ->
      tutorials = tpl.tutorials.get()
      tutorials[@index - 1].status = "done"

      if tutorials.length == @index
        $(".promo").addClass "active"
      else
        tutorials[@index]?.status = "active"
      
      if APP.justdo_google_analytics?
        payload = 
          lang: APP.justdo_i18n?.getLang()
          tutorial_title: @title
        APP.justdo_google_analytics.sendEvent "tutorial-dropdown-btn-clicked", payload

      tpl.tutorials.set tutorials

      return

    "click .promo .request": (e, tpl) ->
      tpl.request_sent.set true
      APP.justdo_google_analytics?.sendEvent "tutorial-dropdown-support-requested", {lang: APP.justdo_i18n?.getLang()}
      request_data =
        name: JustdoHelpers.displayName Meteor.user()
        email: JustdoHelpers.currentUserMainEmail()
        campaign: APP.justdo_promoters_campaigns?.getCampaignDoc()?._id
        source_template: "tutorial"
        message: "#{JustdoHelpers.displayName Meteor.user()} requested a 1:1 tutorial"

      tz = moment.tz.guess()
      if _.isString tz
        request_data.tz = tz

      Meteor.call "contactRequest", request_data, (err) ->
        if err?
          tpl.request_sent.set false
          JustdoSnackbar.show 
            text: err.reason or err
          return

      return
