PACK.jquery_events.push(
  {
    # destroy current cell editor if blurred out and value didn't change
    args: ['blur', 'input.editor-text,input.tree-control-editor-input']
    handler: (e) ->
      Meteor.defer =>
        if (e.currentTarget == $('input.editor-text', @container).get(0)) or
          (e.currentTarget == $('input.tree-control-editor-input', @container).get(0))
            @_grid.getEditorLock().commitCurrentEdit()   
  }
)
