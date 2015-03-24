TestCol = share.TestCol
initData = share.initData

th = new TestHelpers
  timeout: 20000

default_initData_users_count = 10
default_initData_items_count = 10 # min 10 items
defaultInitData = () ->
  initData default_initData_users_count, default_initData_items_count

isEditableId = (id) ->
  parseInt(id, 10) % 2 == 0

test_columns = ["title", "field_a", "field_b", "field_c", "field_d"]

getEditReq = (field, item) ->
  row: null # not in use by grid_data.edit()
  cell: test_columns.indexOf(field)
  grid:
    getColumns: -> {id: field} for field in test_columns
  item: item

defaultInitData()

Tinytest.add 'GridData - basics - defined, and is object', (test) ->
  test.isTrue _.isObject(GridData)

Tinytest.addAsync 'GridData - init/destroy/reactivity - init event is called on time', (test, onComplete) ->
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete, ->
    gd = new GridData TestCol

    gd.on "init", ->
      test.isTrue gd._initialized
      test.isFalse gd._destroyed
      test.instanceOf gd._items_tracker, LocalCollection.ObserveHandle
      test.instanceOf gd._flush_orchestrator, Tracker.Computation

      onCompleteOnce()

Tinytest.addAsync 'GridData - init/destroy/reactivity - destroy method works as expected after initialization', (test, onComplete) ->
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete

  gd = new GridData TestCol

  gd.on "init", ->
    gd.destroy()

  gd.on "destroyed", ->
    test.isTrue gd._initialized
    test.isTrue gd._destroyed
    test.isNull gd._items_tracker
    test.isTrue gd._flush_orchestrator.stopped

    onCompleteOnce()

Tinytest.addAsync 'GridData - init/destroy/reactivity - don\'t initialize if destoryed before init', (test, onComplete) ->
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete

  gd = new GridData TestCol

  gd.on "destroyed", ->
    test.isFalse gd._initialized
    test.isTrue gd._destroyed
    test.isNull gd._items_tracker
    test.isNull gd._flush_orchestrator

    onCompleteOnce()

  gd.destroy()

Tinytest.addAsync 'GridData - init/destroy/reactivity - destroy if containing computation stopped', (test, onComplete) ->
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete

  gd = null
  comp = Tracker.autorun ->
    gd = new GridData TestCol

  gd.on "init", ->
    comp.stop()

  gd.on "destroyed", ->
    test.isTrue gd._initialized
    test.isTrue gd._destroyed
    test.isNull gd._items_tracker
    test.isTrue gd._flush_orchestrator.stopped

    onCompleteOnce()

Tinytest.addAsync 'GridData - init/destroy/reactivity - don\'t initialize and destroy if containing computation stopped', (test, onComplete) ->
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete

  comp = Tracker.autorun ->
    gd = new GridData TestCol

    gd.on "destroyed", ->
      test.isFalse gd._initialized
      test.isTrue gd._destroyed
      test.isNull gd._items_tracker
      test.isNull gd._flush_orchestrator

      onCompleteOnce()

  comp.stop()

Tinytest.addAsync 'GridData - edit - flush called as expected, events emits as expected, permission handled correctly', (test, onComplete) ->
  subscribe_time = null
  subscription = null
  onCompleteOnce = th.getOnCompleteOnceOrTimeout test, onComplete, [
    ->
      subscribe_time = Date.now()
      subscription = Meteor.subscribe "testCol"
    ,
    ->
      if subscription.ready()
        subscribe_time = Date.now() - subscribe_time

        grid_data_init_time = Date.now()
        gd = new GridData TestCol

        test.equal gd._need_flush.curValue, 0

        gd.on "init", ->
          grid_data_init_time = Date.now() - grid_data_init_time

          console.log "Metrics: subscription time: #{subscribe_time}, GridData init time: #{grid_data_init_time}"

          gd.expandPath("/1/") # expand /1 so we'll have its child 10 XXX test that without expension - no event raised for the child

          # force flush to get update internal structures with inital state
          # before we change them, otherwise _flush will just build the entire
          # internal structures and won't change only those that we edit
          gd._flush()

          now = Date.now()
          getNewFieldContent = (id) -> "#{now} #{id}"

          expected_events_emitted = []
          gd.on "grid-item-changed", (row, fields) ->
            if row == 2 and fields.length == 1 and fields[0] == "field_a"
              expected_events_emitted[0] = 1

            if row == 2 and fields.length == 2 and fields[0] == "field_b" and fields[1] == "field_c"
              expected_events_emitted[1] = 1

            # The following rows points to same item
            if row == 1 and fields.length == 1 and fields[0] == "field_a"
              expected_events_emitted[2] = 1

            if row == 10 and fields.length == 1 and fields[0] == "field_a"
              expected_events_emitted[3] = 1

            if row == 1 and fields.length == 2 and fields[0] == "field_b" and fields[1] == "field_c"
              expected_events_emitted[4] = 1

            if row == 10 and fields.length == 2 and fields[0] == "field_b" and fields[1] == "field_c"
              expected_events_emitted[5] = 1

          # wait for the failures that arise from lack of permissions before
          # checking the data
          gd.once "edit-failed", ->
            expected_events_emitted_after_failure = []
            gd.on "grid-item-changed", (row, fields) ->
              if row == 0 and fields.length == 1 and fields[0] == "field_a"
                expected_events_emitted_after_failure[0] = 1

              if row == 3 and fields.length == 1 and fields[0] == "field_a"
                expected_events_emitted_after_failure[1] = 1

              if row == 5 and fields.length == 1 and fields[0] == "field_a"
                expected_events_emitted_after_failure[2] = 1

              if row == 7 and fields.length == 1 and fields[0] == "field_a"
                expected_events_emitted_after_failure[3] = 1

              if row == 9 and fields.length == 1 and fields[0] == "field_a"
                expected_events_emitted_after_failure[4] = 1

            gd.on "_flush", ->
              for item in TestCol.find().fetch()
                if isEditableId item._id
                  test.equal item.field_a, getNewFieldContent(item._id)
                  test.equal item.field_b, getNewFieldContent(item._id)
                  test.equal item.field_c, getNewFieldContent(item._id)
                else
                  test.equal item.field_a, ""
                  test.equal item.field_b, ""
                  test.equal item.field_c, ""

              test.equal _.reduce(expected_events_emitted, ((memo, num) -> memo + num), 0), 6
              test.equal _.reduce(expected_events_emitted_after_failure, ((memo, num) -> memo + num), 0), 5

              onCompleteOnce()

          # edit the items
          for id in [1..default_initData_items_count]
            id = "" + id

            item = TestCol.findOne(id)
            item.field_a = getNewFieldContent(id)
            gd.edit getEditReq("field_a", item)

            # we test the following only on editable item, because we don't
            # support at the moment revert operation that performed outside
            # the GridData instance failed
            if isEditableId id
              TestCol.update(id, $set: {field_b: getNewFieldContent(id), field_c: getNewFieldContent(id)})
  ]
