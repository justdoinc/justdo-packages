PACK.Editors = {}
PACK.EditorsHelpers = {}
#PACK.EditorsInit = {}

_.extend GridControl.prototype,
  _editors: null
  _load_editors: ->
    @_editors = {}

    for editor_name, editor of PACK.Editors
      do (editor) =>
        @_editors[editor_name] = (args) =>
          args.grid_control = @

          schema = @schema[args.column.id]

          args.options = schema.grid_column_editor_options or {}

          return new editor(args)

#  _init_editors: ->
#    for editor_name, editor of @_editors
#      if editor_name of PACK.EditorsInit
#        PACK.EditorsInit[editor_name].call(@)
