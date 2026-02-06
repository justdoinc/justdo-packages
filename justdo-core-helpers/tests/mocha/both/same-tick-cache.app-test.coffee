# Tests for the SameTickCache framework in justdo-core-helpers.
#
# The SameTickCache provides a per-event-loop-turn cache that auto-clears
# via setTimeout(0). It supports basic CRUD, memoized procedures, tick UIDs,
# and pre-clear hooks.
#
# These tests run in "both" (server + client) since the cache is loaded
# on both environments.

if Package["justdoinc:justdo-core-helpers"]?
  {expect} = require "chai"

  describe "JustdoCoreHelpers - SameTickCache", ->
    @timeout 10000

    afterEach ->
      JustdoCoreHelpers.sameTickCachePurge()
      return

    # ========================================
    # Basic Operations (set / get / exists)
    # ========================================

    describe "Basic Operations (set/get/exists)", ->

      it "should store and retrieve a value", ->
        JustdoCoreHelpers.sameTickCacheSet("test_key", 42)
        expect(JustdoCoreHelpers.sameTickCacheGet("test_key")).to.equal 42
        return

      it "should return undefined for a key that was never set", ->
        expect(JustdoCoreHelpers.sameTickCacheGet("nonexistent")).to.be.undefined
        return

      it "should report true from sameTickCacheExists for a set key", ->
        JustdoCoreHelpers.sameTickCacheSet("test_key", "hello")
        expect(JustdoCoreHelpers.sameTickCacheExists("test_key")).to.be.true
        return

      it "should report false from sameTickCacheExists for a key that was never set", ->
        expect(JustdoCoreHelpers.sameTickCacheExists("nonexistent")).to.be.false
        return

      it "should overwrite an existing value when set is called again", ->
        JustdoCoreHelpers.sameTickCacheSet("test_key", "first")
        JustdoCoreHelpers.sameTickCacheSet("test_key", "second")
        expect(JustdoCoreHelpers.sameTickCacheGet("test_key")).to.equal "second"
        return

      it "should store and retrieve null as a valid value", ->
        JustdoCoreHelpers.sameTickCacheSet("null_key", null)
        # null is stored, so "exists" checks via the `of` operator should be true
        expect(JustdoCoreHelpers.sameTickCacheExists("null_key")).to.be.true
        expect(JustdoCoreHelpers.sameTickCacheGet("null_key")).to.be.null
        return

      it "should store and retrieve false as a valid value", ->
        JustdoCoreHelpers.sameTickCacheSet("false_key", false)
        expect(JustdoCoreHelpers.sameTickCacheExists("false_key")).to.be.true
        expect(JustdoCoreHelpers.sameTickCacheGet("false_key")).to.be.false
        return

      it "should store and retrieve objects and arrays", ->
        obj = {a: 1, b: [2, 3]}
        JustdoCoreHelpers.sameTickCacheSet("obj_key", obj)
        expect(JustdoCoreHelpers.sameTickCacheGet("obj_key")).to.equal obj
        return

      it "should return the set value from sameTickCacheSet", ->
        result = JustdoCoreHelpers.sameTickCacheSet("test_key", "value")
        expect(result).to.equal "value"
        return

    # ========================================
    # Unset
    # ========================================

    describe "Unset", ->

      it "should remove a key with sameTickCacheUnset", ->
        JustdoCoreHelpers.sameTickCacheSet("test_key", "value")
        JustdoCoreHelpers.sameTickCacheUnset("test_key")
        expect(JustdoCoreHelpers.sameTickCacheExists("test_key")).to.be.false
        return

      it "should make sameTickCacheGet return undefined after unset", ->
        JustdoCoreHelpers.sameTickCacheSet("test_key", "value")
        JustdoCoreHelpers.sameTickCacheUnset("test_key")
        expect(JustdoCoreHelpers.sameTickCacheGet("test_key")).to.be.undefined
        return

      it "should not affect other keys when unsetting one key", ->
        JustdoCoreHelpers.sameTickCacheSet("key_a", "A")
        JustdoCoreHelpers.sameTickCacheSet("key_b", "B")
        JustdoCoreHelpers.sameTickCacheUnset("key_a")
        expect(JustdoCoreHelpers.sameTickCacheExists("key_a")).to.be.false
        expect(JustdoCoreHelpers.sameTickCacheGet("key_b")).to.equal "B"
        return

      it "should handle sameTickCacheUnset on a non-existent key without error", ->
        # Should not throw
        JustdoCoreHelpers.sameTickCacheUnset("never_set_key")
        return

    # ========================================
    # Purge
    # ========================================

    describe "Purge", ->

      it "should clear all keys when sameTickCachePurge is called", ->
        JustdoCoreHelpers.sameTickCacheSet("key_1", "val_1")
        JustdoCoreHelpers.sameTickCacheSet("key_2", "val_2")
        JustdoCoreHelpers.sameTickCacheSet("key_3", "val_3")
        JustdoCoreHelpers.sameTickCachePurge()
        expect(JustdoCoreHelpers.sameTickCacheExists("key_1")).to.be.false
        expect(JustdoCoreHelpers.sameTickCacheExists("key_2")).to.be.false
        expect(JustdoCoreHelpers.sameTickCacheExists("key_3")).to.be.false
        return

      it "should allow setting new values after purge", ->
        JustdoCoreHelpers.sameTickCacheSet("key_1", "before")
        JustdoCoreHelpers.sameTickCachePurge()
        JustdoCoreHelpers.sameTickCacheSet("key_1", "after")
        expect(JustdoCoreHelpers.sameTickCacheGet("key_1")).to.equal "after"
        return

      it "should return a new empty object from purge", ->
        JustdoCoreHelpers.sameTickCacheSet("key_1", "val")
        result = JustdoCoreHelpers.sameTickCachePurge()
        expect(result).to.be.an("object")
        expect(_.keys(result).length).to.equal 0
        return

    # ========================================
    # Auto-Clear (setTimeout 0)
    # ========================================

    describe "Auto-Clear (setTimeout 0)", ->

      # We need to wait for any pending clear_job from previous tests
      # before testing auto-clear behavior.
      beforeEach (done) ->
        JustdoCoreHelpers.sameTickCachePurge()
        setTimeout ->
          done()
          return
        , 50
        return

      it "should automatically clear the cache on the next tick", (done) ->
        JustdoCoreHelpers.sameTickCacheSet("auto_key", "auto_value")
        expect(JustdoCoreHelpers.sameTickCacheGet("auto_key")).to.equal "auto_value"

        setTimeout ->
          expect(JustdoCoreHelpers.sameTickCacheExists("auto_key")).to.be.false
          expect(JustdoCoreHelpers.sameTickCacheGet("auto_key")).to.be.undefined
          done()
          return
        , 50
        return

      it "should allow new values to be set after auto-clear", (done) ->
        JustdoCoreHelpers.sameTickCacheSet("first_key", "first_value")

        setTimeout ->
          # After auto-clear, the cache should be empty
          expect(JustdoCoreHelpers.sameTickCacheExists("first_key")).to.be.false

          # But we can set new values
          JustdoCoreHelpers.sameTickCacheSet("second_key", "second_value")
          expect(JustdoCoreHelpers.sameTickCacheGet("second_key")).to.equal "second_value"
          done()
          return
        , 50
        return

      it "should clear all keys in a single auto-clear", (done) ->
        JustdoCoreHelpers.sameTickCacheSet("key_a", "A")
        JustdoCoreHelpers.sameTickCacheSet("key_b", "B")
        JustdoCoreHelpers.sameTickCacheSet("key_c", "C")

        setTimeout ->
          expect(JustdoCoreHelpers.sameTickCacheExists("key_a")).to.be.false
          expect(JustdoCoreHelpers.sameTickCacheExists("key_b")).to.be.false
          expect(JustdoCoreHelpers.sameTickCacheExists("key_c")).to.be.false
          done()
          return
        , 50
        return

    # ========================================
    # getTickUid
    # ========================================

    describe "getTickUid", ->

      it "should return a string", ->
        uid = JustdoCoreHelpers.getTickUid()
        expect(uid).to.be.a "string"
        expect(uid.length).to.be.greaterThan 0
        return

      it "should return the same value within the same tick", ->
        uid_1 = JustdoCoreHelpers.getTickUid()
        uid_2 = JustdoCoreHelpers.getTickUid()
        expect(uid_1).to.equal uid_2
        return

      it "should return a different value after cache clears (next tick)", (done) ->
        uid_before = JustdoCoreHelpers.getTickUid()

        # Purge to simulate a new tick (auto-clear resets the cache)
        JustdoCoreHelpers.sameTickCachePurge()

        # Wait for any pending clear_job and start a fresh tick
        setTimeout ->
          uid_after = JustdoCoreHelpers.getTickUid()
          expect(uid_after).to.not.equal uid_before
          done()
          return
        , 50
        return

      it "should store the tick uid under the __tick_id key", ->
        uid = JustdoCoreHelpers.getTickUid()
        expect(JustdoCoreHelpers.sameTickCacheGet("__tick_id")).to.equal uid
        return

    # ========================================
    # generateSameTickCachedProcedure
    # ========================================

    describe "generateSameTickCachedProcedure", ->

      it "should call the wrapped procedure and return its result", ->
        proc = -> 42
        cached_proc = JustdoCoreHelpers.generateSameTickCachedProcedure("test_proc", proc)
        result = cached_proc()
        expect(result).to.equal 42
        return

      it "should call the procedure only once within the same tick", ->
        call_count = 0
        proc = ->
          call_count += 1
          return "result"
        cached_proc = JustdoCoreHelpers.generateSameTickCachedProcedure("count_proc", proc)

        cached_proc()
        cached_proc()
        cached_proc()
        expect(call_count).to.equal 1
        return

      it "should return the cached result on subsequent calls", ->
        proc = -> {value: Math.random()}
        cached_proc = JustdoCoreHelpers.generateSameTickCachedProcedure("obj_proc", proc)

        result_1 = cached_proc()
        result_2 = cached_proc()
        # Should be the exact same object reference
        expect(result_1).to.equal result_2
        return

      it "should re-execute the procedure after cache clears (next tick)", (done) ->
        call_count = 0
        proc = ->
          call_count += 1
          return call_count
        cached_proc = JustdoCoreHelpers.generateSameTickCachedProcedure("reexec_proc", proc)

        first_result = cached_proc()
        expect(first_result).to.equal 1

        JustdoCoreHelpers.sameTickCachePurge()
        setTimeout ->
          second_result = cached_proc()
          expect(second_result).to.equal 2
          expect(call_count).to.equal 2
          done()
          return
        , 50
        return

      it "should differentiate cache keys based on arguments", ->
        proc = (a, b) -> a + b
        cached_proc = JustdoCoreHelpers.generateSameTickCachedProcedure("args_proc", proc)

        result_1 = cached_proc(1, 2)
        result_2 = cached_proc(3, 4)
        expect(result_1).to.equal 3
        expect(result_2).to.equal 7
        return

      it "should use the same cache entry for identical arguments", ->
        call_count = 0
        proc = (x) ->
          call_count += 1
          return x * 2
        cached_proc = JustdoCoreHelpers.generateSameTickCachedProcedure("same_args_proc", proc)

        cached_proc(5)
        cached_proc(5)
        cached_proc(5)
        expect(call_count).to.equal 1
        expect(cached_proc(5)).to.equal 10
        return

      it "should work with zero arguments (no argument suffix on cache key)", ->
        proc = -> "no_args_result"
        cached_proc = JustdoCoreHelpers.generateSameTickCachedProcedure("no_args_proc", proc)

        result = cached_proc()
        expect(result).to.equal "no_args_result"

        # Verify it's cached under the base key (no :: suffix)
        expect(JustdoCoreHelpers.sameTickCacheExists("no_args_proc")).to.be.true
        return

      it "should pass all arguments through to the wrapped procedure", ->
        received_args = null
        proc = (args...) ->
          received_args = args
          return "done"
        cached_proc = JustdoCoreHelpers.generateSameTickCachedProcedure("passthrough_proc", proc)

        cached_proc("a", "b", "c")
        expect(received_args).to.deep.equal ["a", "b", "c"]
        return

      it "should build cache key as key::arg1:arg2 for multiple arguments", ->
        proc = (a, b) -> "#{a}-#{b}"
        cached_proc = JustdoCoreHelpers.generateSameTickCachedProcedure("multi_key_proc", proc)

        cached_proc("x", "y")

        # The key should be "multi_key_proc::x:y"
        expect(JustdoCoreHelpers.sameTickCacheExists("multi_key_proc::x:y")).to.be.true
        expect(JustdoCoreHelpers.sameTickCacheGet("multi_key_proc::x:y")).to.equal "x-y"
        return

    # ========================================
    # registerSameTickCachePreClearProcedure
    # ========================================

    describe "registerSameTickCachePreClearProcedure", ->

      # Note: registered procedures persist for the lifetime of the process
      # (there's no unregister API). We register once and use flags/counters.

      pre_clear_call_count = 0
      pre_clear_received_cache = null

      before ->
        JustdoCoreHelpers.registerSameTickCachePreClearProcedure (cache_obj) ->
          pre_clear_call_count += 1
          pre_clear_received_cache = cache_obj
          return
        return

      beforeEach (done) ->
        # Reset tracking variables and ensure no pending clear_job
        pre_clear_call_count = 0
        pre_clear_received_cache = null
        JustdoCoreHelpers.sameTickCachePurge()
        setTimeout ->
          pre_clear_call_count = 0
          pre_clear_received_cache = null
          done()
          return
        , 50
        return

      it "should invoke the registered callback on auto-clear", (done) ->
        JustdoCoreHelpers.sameTickCacheSet("pre_clear_test", "value")

        setTimeout ->
          expect(pre_clear_call_count).to.be.greaterThan 0
          done()
          return
        , 50
        return

      it "should pass the cache object to the callback", (done) ->
        JustdoCoreHelpers.sameTickCacheSet("marker_key", "marker_value")

        setTimeout ->
          # The callback should have received the cache with our marker
          expect(pre_clear_received_cache).to.be.an "object"
          expect(pre_clear_received_cache.marker_key).to.equal "marker_value"
          done()
          return
        , 50
        return

      it "should not invoke pre-clear procedures on manual sameTickCachePurge", (done) ->
        # Reset after any pending timeouts
        JustdoCoreHelpers.sameTickCachePurge()
        setTimeout ->
          pre_clear_call_count = 0

          # Set a value and immediately purge (manual)
          JustdoCoreHelpers.sameTickCacheSet("manual_purge_test", "value")
          JustdoCoreHelpers.sameTickCachePurge()

          # The pre-clear procedure should NOT have been called by purge itself
          # (only by the auto-clear timeout)
          count_after_purge = pre_clear_call_count

          # Wait for the auto-clear timeout to fire
          setTimeout ->
            # The auto-clear will fire and call pre-clear procedures,
            # but the cache will already be empty
            expect(count_after_purge).to.equal 0
            done()
            return
          , 50
          return
        , 50
        return

      it "should support multiple registered procedures", (done) ->
        second_proc_called = false
        JustdoCoreHelpers.registerSameTickCachePreClearProcedure ->
          second_proc_called = true
          return

        JustdoCoreHelpers.sameTickCacheSet("multi_proc_test", "value")

        setTimeout ->
          expect(pre_clear_call_count).to.be.greaterThan 0
          expect(second_proc_called).to.be.true
          done()
          return
        , 50
        return
