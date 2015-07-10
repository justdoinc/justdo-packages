TestCollections = share.TestCollections
TestInvalidCollections = share.TestInvalidCollections

th = new TestHelpers
  timeout: 5000

Tinytest.add 'GridControl - basics - defined, and is object', (test) ->
  test.isTrue _.isObject(GridControl)

Tinytest.addAsync 'GridControl - init/destroy/reactivity - init event is called on time', (test, onComplete) ->
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete

  gc = new GridControl {items_collection: TestCollections.default}, document.createElement("div")

  gc.on "init", ->
    onCompleteOnce ->
      test.isTrue gc._initialized
      test.isFalse gc._destroyed
      test.instanceOf gc._grid_data, GridData
      test.instanceOf gc._grid, Slick.Grid

Tinytest.addAsync 'GridControl - init/destroy/reactivity - destroy method works as expected after initialization', (test, onComplete) ->
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete

  gc = new GridControl {items_collection: TestCollections.default}, document.createElement("div")

  gc.on "init", ->
    gc.destroy()

  gc.on "destroyed", ->
    onCompleteOnce ->
      test.isTrue gc._initialized
      test.isTrue gc._destroyed
      test.isNull gc._grid_data
      test.isNull gc._grid

Tinytest.addAsync 'GridControl - init/destroy/reactivity - don\'t initialize if destoryed before init', (test, onComplete) ->
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete

  gc = new GridControl {items_collection: TestCollections.default}, document.createElement("div")

  gc.on "destroyed", ->
    onCompleteOnce ->
      test.isFalse gc._initialized
      test.isTrue gc._destroyed
      test.isNull gc._grid_data
      test.isNull gc._grid

  gc.destroy()

Tinytest.addAsync 'GridControl - init/destroy/reactivity - destroy if containing computation stopped', (test, onComplete) ->
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete

  gc = null
  comp = Tracker.autorun ->
    gc = new GridControl {items_collection: TestCollections.default}, document.createElement("div")

  gc.on "init", ->
    comp.stop()

  gc.on "destroyed", ->
    onCompleteOnce ->
      test.isTrue gc._initialized
      test.isTrue gc._destroyed
      test.isNull gc._grid_data
      test.isNull gc._grid

Tinytest.addAsync 'GridControl - init/destroy/reactivity - don\'t initialize and destroy if containing computation stopped', (test, onComplete) ->
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete

  comp = Tracker.autorun ->
    gc = new GridControl {items_collection: TestCollections.default}, document.createElement("div")

    gc.on "destroyed", ->
      onCompleteOnce ->
        test.isFalse gc._initialized
        test.isTrue gc._destroyed
        test.isNull gc._grid_data
        test.isNull gc._grid

  comp.stop()

Tinytest.addAsync 'GridControl - schema validation - don\'t initialize for invalid schemas', (test, onComplete) ->
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete

  for collection_name, collection of TestInvalidCollections
    test.throws ->
      gc = new GridControl {items_collection: collection}, document.createElement("div")
    , Meteor.Error

  onCompleteOnce()

Tinytest.addAsync 'GridControl - schema validation - correct defaults set', (test, onComplete) ->
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete

  gc = new GridControl {items_collection: TestCollections.correct_defaults_set_for_visible_columns_of_type_string}, document.createElement("div")

  test.equal gc.schema.f1.grid_column_formatter, "textWithTreeControls"
  test.equal gc.schema.f1.grid_column_editor, "TextWithTreeControlsEditor"

  test.equal gc.schema.f2.grid_column_formatter, "defaultFormatter"
  test.equal gc.schema.f2.grid_column_editor, "TextEditor"

  test.equal gc.schema.f3.grid_column_formatter, "defaultFormatter"
  test.equal gc.schema.f3.grid_column_editor, null

  test.equal gc.schema.f4.grid_column_formatter, null
  test.equal gc.schema.f4.grid_column_editor, null

  onCompleteOnce()