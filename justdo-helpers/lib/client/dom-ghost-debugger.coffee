_.extend JustdoHelpers,
  debugDom: (enable=true) ->
    if enable
      $("html").addClass("ghost")
    else
      $("html").removeClass("ghost")