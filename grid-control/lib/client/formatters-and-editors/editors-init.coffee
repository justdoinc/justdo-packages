PACK.Editors = {}

GridControl.installEditor = (editor_name, editor_prototype) ->
  prototype = Object.create(base_slick_grid_editors_prototype)

  _.extend prototype, editor_prototype

  EditorConstructor = (context) ->
    @context = context

    @doc = undefined

    # @doc will store the data associated with the editor.
    # slick grid will provide us this data by calling @loadValue()
    # Note that @loadValue() is called on every data update
    # to keep us updated.
    #
    # During the initial call to the editor constructor, we don't
    # know yet @doc, therefore some of the editor's methods can't
    # be called, for example: @getOriginalValue() and @getOriginalItem().
    #
    # Before @_data_ready is set, methods that rely on it will
    # throw an exception.
    #
    # Since in GridControl's use case*, the @loadValue
    # will be called immediately after @init(), it is safe to assume
    # that @init() is the only place you can't call methods that rely
    # on @doc.
    #
    # * Not true for SlickGrid in general.

    @init() # See base_slick_grid_editors_prototype below

    return

  EditorConstructor.prototype = prototype

  PACK.Editors[editor_name] = EditorConstructor

  return

GridControl.installEditorExtension = (options) ->
  check options, {
    editor_name: String
    extended_editor_name: String
    prototype_extensions: Object
  }

  {
    editor_name
    extended_editor_name
    prototype_extensions
  } = options

  if not (parent_editor = GridControl.getEditors()[extended_editor_name])?
    throw Meteor.Error "unknown-editor", "Editor #{extended_editor_name} doesn't exist"

  new_editor_prototype = Object.create(parent_editor.prototype)

  # Leave reference to the extended formatter
  _.extend new_editor_prototype, prototype_extensions,
    extended_editor_name: extended_editor_name

  # Leave references to the extended editor that began
  # the extensions chain
  if not new_editor_prototype.original_extended_editor_name?
    new_editor_prototype.original_extended_editor_name =
      extended_editor_name

  GridControl.installEditor editor_name, new_editor_prototype

  return 

GridControl.getEditors = ->
  return PACK.Editors

PACK.EditorsHelpers = {}

_.extend GridControl.prototype,
  _editors: null
  _load_editors: ->
    @_editors = {}

    for editor_name, editor of PACK.Editors
      do (editor) =>
        @_editors[editor_name] = (context) =>
          # Enrich slick grid context with grid control context

          field_schema = @schema[context.column.id]

          _.extend context,
            grid_control: @
            field_name: context.column.field
            schema: field_schema # XXX REMOVE ME, use only field_schema
            field_schema: field_schema
            options: field_schema.grid_column_editor_options or {}

          return new editor(context)

base_slick_grid_editors_prototype =
  #
  # Slick Grid's Editors API required methods 
  #
  loadValue: (doc) ->
    # Called with the current data document right after the
    # first editor init and again once data updates occured

    @doc = doc

    init_value = @getEditorFieldValueFromDoc()

    @setInputValue(init_value)

    return

  applyValue: (item, state) ->
    # Slick grid requires this one, to be defined for every
    # editor...
    item[@getEditorFieldName()] = state

    return

  isValueChanged: ->
    field_doc_value = @getEditorFieldValueFromDoc()

    if field_doc_value?
      return field_doc_value != @serializeValue()
    else
      # If field_doc_value is undefined/null in the document
      # consider it changed only if @serializeValue() is defined
      return @serializeValue()?

  validate: ->
    serialized_value = @serializeValue()

    #
    # Validate against field schema
    #
    field_name = @getEditorFieldName()

    field_schema = {}
    field_schema[field_name] = @context.field_schema
    field_simple_schema = new SimpleSchema(field_schema)

    serialized_value_in_object = {}
    serialized_value_in_object[field_name] = serialized_value

    if not ((validation_context = field_simple_schema.newContext()).validate(serialized_value_in_object))
      ik = _.map validation_context.invalidKeys(), (o) ->
        "option `#{o.name}': #{validation_context.keyErrorMessage(o.name)}"

      return {
        valid: false
        msg: ik.join(";\n")
      }

    #
    # Validate against editors @validator()
    #
    if _.isString(error_messgae = @validator(serialized_value))
      return {
        valid: false
        msg: error_messgae
      }
    else
      return {
        valid: true
        msg: null
      }

  #
  # Default implementations
  #
  validator: (value) -> undefined # in case an editor doesn't implement validator, we assume all values are valid

  #
  # Helpers
  #
  getEditorFieldName: -> @context.field_name

  requireDataReady: ->
    if not @doc?
      throw Meteor.Error "editor-data-not-ready-yet", "Editor data not ready yet, avoid calling data methods from @init()"

    return

  getEditorDoc: ->
    # Returns the data document associated with the editor
    # (the one provided to @loadValue())

    @requireDataReady()

    return @doc

  getEditorFieldValueFromDoc: ->
    # Returns the editor value from the data document
    # associated with it (the one provided to @loadValue())
    #
    # Will return undefined if it isn't set

    return @getEditorDoc()[@getEditorFieldName()]

  callFormatter: (formatter_name) ->
    # Get the output of formatter for current editor_args

    active_cell = @context.grid.getActiveCell()

    formatter = @context.grid_control._formatters[formatter_name]

    formatter_output = formatter active_cell.row,
      active_cell.cell,
      @context.item[@context.column.field],
      @context.column,
      @context.item

    return formatter_output

  saveAndExit: ->
    @context.grid_control.saveAndExitActiveEditor()

    return

  getValue: -> @serializeValue() # XXX Consider getting rid of this one.
                                 # Used by us due to wrong docs
                                 # slick.grid doesn't use it.

  setValue: -> @setInputValue() # XXX Consider getting rid of this one.
                                # Used by us due to wrong docs
                                # slick.grid doesn't use it.
