$(document).on "keydown", (e) ->
  e = e || window.event
  if e.keyCode == 27
    APP.emit("doc-esc-click", e)

  return

$(document).on "click", (e) ->
  APP.emit("doc-click", e)

  return

$(document).on "show.bs.dropdown", (e) ->
  APP.emit("doc-bootstrap-dropdown-show", e)

  return

$(document).on "show.boundelement", (e) ->
  APP.emit("doc-bound-element-show", e)

  return
