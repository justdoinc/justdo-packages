APP.executeAfterAppLibCode ->
  Template.tutorials.onCreated ->
    @request_sent = new ReactiveVar false

    @tutorials = new ReactiveVar [
      {
        "title": "welcome_to_justdo",
        "media": "https://player.vimeo.com/video/813068460?texttrack=#{APP.justdo_i18n.getVimeoLangTag()}#t=7.5s"
        "media_type": "iframe"
        "media_id": "vimeo-player"
        "media_style": "position:absolute;top:0;left:0;width:100%;height:100%;"
        "allow": "autoplay; fullscreen; picture-in-picture"
        "class": "welcome"
        "status": "" # pending, done
      },
      {
        "title": "set_justdo_name_title",
        "subtitle": "set_justdo_name_subtitle",
        "media": "/packages/justdoinc_justdo-tutorials/lib/client/project-header-tutorial/tutorials/media/set_name.mp4"
        "status": "pending"
      },
      {
        "title": "create_first_task_title",
        "subtitle": "create_first_task_subtitle",
        "media": "/packages/justdoinc_justdo-tutorials/lib/client/project-header-tutorial/tutorials/media/create_task.mp4"
        "status": "pending"
      },
      {
        "title": "invite_members_title",
        "subtitle": "invite_members_subtitle",
        "media": "/packages/justdoinc_justdo-tutorials/lib/client/project-header-tutorial/tutorials/media/invite_members.mp4"
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

    $(".nav-tutorials.dropdown").on "shown.bs.dropdown", ->
      if $(".nav-tutorials.dropdown").hasClass "highlighted"
        $(".nav-tutorials.dropdown").removeClass "highlighted"

      return

    @autorun =>
      $vimeo_player = @$("#vimeo-player")
      if not (existing_src = $vimeo_player.attr "src")?
        return
      existing_src = new URL existing_src
      existing_src.searchParams.set "texttrack", APP.justdo_i18n.getVimeoLangTag()
      $vimeo_player.attr "src", existing_src.toString()
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
    
    loadMediaIfVimeoPlayerIsLoaded: ->
      # This is to make sure the vimeo player is loaded before the dropdown is shown,
      # but not before the user clicks on the dropdown.
      if not APP.justdo_vimeo_loader.isVimeoPlayerLoaded()
        $(".nav-tutorials").one "shown.bs.dropdown", ->
          APP.justdo_vimeo_loader.loadVimeoPlayer()
          return
        return

      return @media

    promoUnlocked: ->
      tutorials = Template.instance().tutorials.get()

      for tutorial in tutorials
        if tutorial.status != "done"
          return false

      return true

    requestSent: ->
      return Template.instance().request_sent.get()

  Template.tutorials.events
    "click .tutorials-wrapper": (e, tpl) ->
      e.stopPropagation()
      e.preventDefault()

      return
    
    "mouseenter .tutorials-wrapper": (e, tpl) ->
      APP.justdo_tutorials.is_tutorial_dropdown_allowed_to_close = true
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

    "mouseenter .welcome": (e, tpl) ->
      player = new Vimeo.Player($("#vimeo-player"))
      player.play()

      return

    "mouseleave .welcome": (e, tpl) ->
      player = new Vimeo.Player($("#vimeo-player"))
      player.pause()

      return
