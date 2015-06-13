TestCol = share.TestCol
initData = share.initData

helpers = share.helpers

users = ("user#{id}@gmail.com" for id in [0...10])
password = "123456"

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

Tinytest.addAsync 'GridData - operations - addChild', (test, onComplete) ->
  subscription = null
  onCompleteOnce = null
  th.getOnCompleteOnceOrTimeoutWithUser test, onComplete, users[0], password, [
    ->
      subscription = Meteor.subscribe "testCol"
    ,
    ->
      if subscription.ready()
        gd = new GridData TestCol

        gd.on "init", ->
          gd.addChild "/not-existing-item/", (err, item_id, path) ->
            test.equal err.error, "unkown-path"

            gd.addChild "/1/", (err, item_id, path) -> # /1/ doesn't belong to user0
              test.equal err.error, "unkown-path"

              gd.addChild "/10/", (err, item_id, path) ->
                test.equal path, "/10/#{item_id}/"

                gd.addChild "/10", (err, item_id, path) ->
                  test.equal path, "/10/#{item_id}/"

                  onCompleteOnce()
  ], (cb) ->
    onCompleteOnce = cb

Tinytest.addAsync 'GridData - operations - addSibling', (test, onComplete) ->
  subscription = null
  onCompleteOnce = null
  th.getOnCompleteOnceOrTimeoutWithUser test, onComplete, users[0], password, [
    ->
      subscription = Meteor.subscribe "testCol"
    ,
    ->
      if subscription.ready()
        gd = new GridData TestCol

        gd.on "init", ->
          gd.addSibling "/not-existing-item/", (err, item_id, path) ->
            console.log err
            test.equal err.error, "unkown-path"

            gd.addSibling "/1/", (err, item_id, path) -> # /1/ doesn't belong to user0
              test.equal err.error, "unkown-path"

              gd.addSibling "/10/", (err, item_id, path) ->
                test.equal path, "/#{item_id}/"

                gd.addSibling "/10", (err, item_id, path) ->
                  test.equal path, "/#{item_id}/"

                  onCompleteOnce()
  ], (cb) ->
    onCompleteOnce = cb

Tinytest.addAsync 'GridData - operations - movePath', (test, onComplete) ->
  subscription = null
  onCompleteOnce = null
  th.getOnCompleteOnceOrTimeoutWithUser test, onComplete, users[0], password, [
    ->
      subscription = Meteor.subscribe "testCol"
    ,
    ->
      if subscription.ready()
        gd = new GridData TestCol

        gd.on "init", ->
          gd.movePath "/not-existing-item/", {order: 0}, (err) ->
            test.equal err.error, "unkown-path"

            gd.movePath "/1/", {order: 0}, (err) -> # /1/ doesn't belong to user0
              test.equal err.error, "unkown-path"

              # Move order same parent path
              path = "/10/"
              gd.movePath path, {order: 0}, (err) ->
                gd.once "rebuild", ->
                  item_id = helpers.getPathItemId(path)

                  test.equal gd.items_by_id[item_id].parents[0].order, 0

                  # Don't allow moving to a parent not under our permission
                  path = "/10/"
                  gd.movePath path, {parent: "1", order: 3}, (err) ->
                    test.equal err.error, "unkown-path"
                    # Don't allow moving to unknown parent
                    path = "/10/"
                    gd.movePath path, {parent: "100"}, (err) ->
                      test.equal err.error, "unkown-path"

                      # Add a new child to "/" to which we will move /10/
                      gd.addChild "/", (err, new_parent_id, new_parent_path) ->

                        path = "/10/"
                        gd.movePath path, {parent: new_parent_id, order: 3}, (err) ->
                          gd.once "rebuild", ->
                            item_id = helpers.getPathItemId(path)

                            test.isTrue not("0" of gd.items_by_id[item_id].parents)
                            test.equal gd.items_by_id[item_id].parents[new_parent_id].order, 3

                            # Move to end of current parent (order not specified)
                            path = "#{new_parent_path}10/"
                            gd.movePath path, {parent: new_parent_id}, (err) ->
                              gd.once "rebuild", ->
                                item_id = helpers.getPathItemId(path)

                                test.equal gd.items_by_id[item_id].parents[new_parent_id].order, 4

                                # Move to same location order all should remain the same
                                path = "#{new_parent_path}10/"
                                gd.movePath path, {parent: new_parent_id, order: 4}, (err) ->
                                  # gd.once "rebuild", -> No rebuild should happen since we don't change the db in this case
                                  item_id = helpers.getPathItemId(path)

                                  test.equal gd.items_by_id[item_id].parents[new_parent_id].order, 4

                                  # replacing increments order of item existing in location
                                  gd.addChild "/", (err, replacing_child_id, replacing_child_path) ->
                                    gd.movePath replacing_child_path, {parent: new_parent_id, order: 4}, (err) ->
                                      gd.once "rebuild", ->
                                        test.equal gd.items_by_id[replacing_child_id].parents[new_parent_id].order, 4
                                        test.equal gd.items_by_id[item_id].parents[new_parent_id].order, 5

                                        path = "/#{new_parent_id}/10/"
                                        gd.movePath path, {parent: "0", order: 4}, (err) ->
                                          gd.once "rebuild", ->
                                            item_id = helpers.getPathItemId(path)
                                            test.equal gd.items_by_id[item_id].parents["0"].order, 4

                                            gd.addChild "/10/", (err, new_parent_id, new_parent_path) ->
                                              gd.movePath "/10/", {parent: new_parent_id}, (err) ->
                                                test.equal err.error, "infinite-loop"

                                                onCompleteOnce()


  ], (cb) ->
    onCompleteOnce = cb
