APP.executeAfterAppLibCode ->
  Template.tutorials.onCreated ->
    @tutorials = new ReactiveVar [
      {
        "title": "Set name for JustDo",
        "subtitle": "Effortlessly manage meetings, tracking tasks created",
        "media": ""
        "status": "active" # pending, active, done
      },
      {
        "title": "Create the first Task",
        "subtitle": "Send emails directly to tasks, maintaining a comprehensive.",
        "media": ""
        "status": "pending"
      },
      {
        "title": "Invite Corowkers",
        "subtitle": "Send emails directly to tasks, maintaining a comprehensive.",
        "media": ""
        "status": "pending"
      }
    ]

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

    "click .tutorial-instruction-btn .btn": (e, tpl) ->
      tutorials = tpl.tutorials.get()
      tutorials[@index - 1].status = "done"
      tutorials[@index]?.status = "active"
      tpl.tutorials.set tutorials

      return
