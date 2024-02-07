Template.project_template_welcome_ai.events
  "focus .welcome-ai-input": (e, tpl) ->
    $(".welcome-ai-results").addClass "show"

    return

  "click .welcome-ai-btn": (e, tpl) ->
    request = $(".welcome-ai-input").val().trim()
    console.log request

    return
