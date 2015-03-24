TestCol = share.TestCol

th = new TestHelpers
  timeout: 5000

Tinytest.add 'GridControl - basics - defined, and is object', (test) ->
  test.isTrue _.isObject(GridControl)

Tinytest.addAsync 'GridControl - init/destroy/reactivity - init event is called on time', (test, onComplete) ->
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete

  gc = new GridControl TestCol, document.createElement("div")

  gc.on "init", ->
    onCompleteOnce ->
      test.isTrue gc._initialized
      test.isFalse gc._destroyed
      test.instanceOf gc._grid_data, GridData
      test.instanceOf gc._grid, Slick.Grid

Tinytest.addAsync 'GridControl - init/destroy/reactivity - destroy method works as expected after initialization', (test, onComplete) ->
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete

  gc = new GridControl TestCol, document.createElement("div")

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

  gc = new GridControl TestCol, document.createElement("div")

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
    gc = new GridControl TestCol, document.createElement("div")

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
    gc = new GridControl TestCol, document.createElement("div")

    gc.on "destroyed", ->
      onCompleteOnce ->
        test.isFalse gc._initialized
        test.isTrue gc._destroyed
        test.isNull gc._grid_data
        test.isNull gc._grid

  comp.stop()
