APP.executeAfterAppLibCode ->
  Template.tutorials.onCreated ->
    @request_sent = new ReactiveVar false

    @tutorials = new ReactiveVar [
      {
        "title": TAPi18n.__("set_justdo_name_title"),
        "subtitle": TAPi18n.__("set_justdo_name_subtitle"),
        "media": "/packages/justdoinc_justdo-tutorials/lib/client/project-header-tutorial/tutorials/media/set_name.mp4"
        "status": "" # pending, done
      },
      {
        "title": TAPi18n.__("create_first_task_title"),
        "subtitle": TAPi18n.__("create_first_task_subtitle"),
        "media": "/packages/justdoinc_justdo-tutorials/lib/client/project-header-tutorial/tutorials/media/create_task.mp4"
        "status": "pending"
      },
      {
        "title": TAPi18n.__("import_tasks_title"),
        "subtitle": TAPi18n.__("import_tasks_subtitle"),
        "media": "/packages/justdoinc_justdo-tutorials/lib/client/project-header-tutorial/tutorials/media/import_tasks.mp4"
        "status": "pending"
      },
      {
        "title": TAPi18n.__("customize_columns_title"),
        "subtitle": TAPi18n.__("customize_columns_subtitle"),
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

      return

    "click .tutorial-instruction-btn .btn": (e, tpl) ->
      tutorials = tpl.tutorials.get()
      tutorials[@index - 1].status = "done"

      if tutorials.length == @index
        $(".promo").addClass "active"
      else
        tutorials[@index]?.status = "active"

      tpl.tutorials.set tutorials

      return

    "click .promo .request": (e, tpl) ->
      tpl.request_sent.set true

      return
