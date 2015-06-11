PACK.jquery_events.push(
  {
    # destroy current cell editor if blurred out and value didn't change
    args: ['blur', 'input.editor-text,input.editor-unicode-date,input.tree-control-editor-input']
    handler: (e) ->
      Meteor.defer =>
        if (e.currentTarget == $('input.editor-text', @container).get(0)) or
           (e.currentTarget == $('input.tree-control-editor-input', @container).get(0))
            @_grid.getEditorLock().commitCurrentEdit()

        # Destroy date editor only if blur isn't a result of opening the datepicker
        if (e.currentTarget == $('input.editor-unicode-date', @container).get(0))
          setTimeout =>
            if not $(".ui-datepicker").is(":visible")
              @_grid.getEditorLock().commitCurrentEdit()
          , 50
  }
)
