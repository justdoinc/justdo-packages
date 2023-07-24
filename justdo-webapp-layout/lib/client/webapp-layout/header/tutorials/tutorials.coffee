APP.executeAfterAppLibCode ->
  Template.tutorials.onCreated ->
    @tutorials = new ReactiveVar [
      {
        "title": "Set name for JustDo",
        "subtitle": "Effortlessly manage meetings, tracking tasks created",
        "media": "/packages/justdoinc_justdo-webapp-layout/lib/client/webapp-layout/header/tutorials/media/set_name.mp4"
        "status": "" # pending, done
      },
      {
        "title": "Create the first Task",
        "subtitle": "Send emails directly to tasks, maintaining a comprehensive.",
        "media": "/packages/justdoinc_justdo-webapp-layout/lib/client/webapp-layout/header/tutorials/media/create_task.mp4"
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
        media.playbackRate = 2

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
