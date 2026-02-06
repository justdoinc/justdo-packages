# Tests for the Barriers utility in JustdoHelpers.
#
# Covers:
#   - Basic resolve flow (single barrier, multiple barriers, multiple callbacks)
#   - Race condition regression: resolve/reject BEFORE runCbAfterBarriers
#   - Timeout fallback when barriers are never resolved
#   - Idempotency (double resolve)

{expect} = require "chai"

describe "Barriers", ->
  @timeout 5000

  # Helper: returns a promise that resolves after the given milliseconds.
  sleep = (ms) ->
    return new Promise (resolve) ->
      Meteor.setTimeout resolve, ms
      return

  # ---------------------------------------------------------------------------
  # Basic resolve flow
  # ---------------------------------------------------------------------------
  describe "basic resolve flow", ->

    it "should execute callback when a single barrier is resolved", ->
      barriers = new JustdoHelpers.Barriers({missing_barrier_timeout: 2000})
      cb_executed = false

      barriers.runCbAfterBarriers "single_barrier", ->
        cb_executed = true
        return

      barriers.markBarrierAsResolved "single_barrier"

      # Give the microtask / promise chain time to settle
      await sleep 50

      expect(cb_executed).to.equal true
      return

    it "should execute callback when all barriers in a list are resolved", ->
      barriers = new JustdoHelpers.Barriers({missing_barrier_timeout: 2000})
      cb_executed = false
      barrier_ids = ["b1", "b2", "b3"]

      barriers.runCbAfterBarriers barrier_ids, ->
        cb_executed = true
        return

      for id in barrier_ids
        barriers.markBarrierAsResolved id

      await sleep 50

      expect(cb_executed).to.equal true
      return

    it "should fire multiple callbacks registered on the same barrier", ->
      barriers = new JustdoHelpers.Barriers({missing_barrier_timeout: 2000})
      cb1_executed = false
      cb2_executed = false

      barriers.runCbAfterBarriers "shared_barrier", ->
        cb1_executed = true
        return

      barriers.runCbAfterBarriers "shared_barrier", ->
        cb2_executed = true
        return

      barriers.markBarrierAsResolved "shared_barrier"

      await sleep 50

      expect(cb1_executed).to.equal true
      expect(cb2_executed).to.equal true
      return

  # ---------------------------------------------------------------------------
  # Race condition: resolve / reject BEFORE registration (regression tests)
  # ---------------------------------------------------------------------------
  describe "race condition: resolve before registration (regression)", ->

    it "should execute callback when markBarrierAsResolved is called BEFORE runCbAfterBarriers", ->
      # This is the core regression test for commit f4c7aad1b.
      # With the old code the resolve was silently lost, so the callback would
      # only fire via the timeout fallback — never via actual promise resolution.
      barrier_timeout = 2000
      barriers = new JustdoHelpers.Barriers({missing_barrier_timeout: barrier_timeout})
      cb_executed = false
      cb_executed_at = null

      start = Date.now()

      # 1. Resolve BEFORE any runCbAfterBarriers call
      barriers.markBarrierAsResolved "early_barrier"

      # 2. Register the callback afterwards
      barriers.runCbAfterBarriers "early_barrier", ->
        cb_executed = true
        cb_executed_at = Date.now()
        return

      # 3. Wait just enough for the promise microtask to settle
      await sleep 100

      expect(cb_executed).to.equal true

      # Verify it resolved quickly (via promise), NOT via the timeout fallback
      elapsed = cb_executed_at - start
      expect(elapsed).to.be.below barrier_timeout
      return

    it "should execute callback when some barriers are resolved before and some after registration", ->
      barriers = new JustdoHelpers.Barriers({missing_barrier_timeout: 2000})
      cb_executed = false

      # Pre-resolve one barrier before registering
      barriers.markBarrierAsResolved "pre_resolved"

      # Register callback that depends on both barriers
      barriers.runCbAfterBarriers ["pre_resolved", "post_resolved"], ->
        cb_executed = true
        return

      # Resolve the second barrier after registration
      barriers.markBarrierAsResolved "post_resolved"

      await sleep 100

      expect(cb_executed).to.equal true
      return

    it "should execute callback (via timeout) when markBarrierAsRejected is called BEFORE runCbAfterBarriers", ->
      # Rejection triggers .catch (not .then), so the callback fires via timeout.
      barrier_timeout = 300
      barriers = new JustdoHelpers.Barriers({missing_barrier_timeout: barrier_timeout})
      cb_executed = false

      # Reject BEFORE registration
      barriers.markBarrierAsRejected "early_reject_barrier"

      barriers.runCbAfterBarriers "early_reject_barrier", ->
        cb_executed = true
        return

      # Should NOT have fired immediately (rejection doesn't trigger .then)
      await sleep 50
      expect(cb_executed).to.equal false

      # Should fire after the timeout fallback
      await sleep barrier_timeout + 200
      expect(cb_executed).to.equal true
      return

  # ---------------------------------------------------------------------------
  # Timeout fallback
  # ---------------------------------------------------------------------------
  describe "timeout behavior", ->

    it "should execute callback via timeout when a barrier is never resolved", ->
      barrier_timeout = 300
      barriers = new JustdoHelpers.Barriers({missing_barrier_timeout: barrier_timeout})
      cb_executed = false

      barriers.runCbAfterBarriers "never_resolved", ->
        cb_executed = true
        return

      # Not yet
      await sleep 50
      expect(cb_executed).to.equal false

      # After timeout
      await sleep barrier_timeout + 200
      expect(cb_executed).to.equal true
      return

    it "should execute callback via timeout when only some barriers are resolved", ->
      barrier_timeout = 300
      barriers = new JustdoHelpers.Barriers({missing_barrier_timeout: barrier_timeout})
      cb_executed = false

      barriers.runCbAfterBarriers ["resolved_1", "resolved_2", "never_resolved"], ->
        cb_executed = true
        return

      barriers.markBarrierAsResolved "resolved_1"
      barriers.markBarrierAsResolved "resolved_2"
      # "never_resolved" is intentionally left unresolved

      await sleep 50
      expect(cb_executed).to.equal false

      await sleep barrier_timeout + 200
      expect(cb_executed).to.equal true
      return

  # ---------------------------------------------------------------------------
  # Idempotency
  # ---------------------------------------------------------------------------
  describe "idempotency", ->

    it "should handle resolving the same barrier twice without error", ->
      barriers = new JustdoHelpers.Barriers({missing_barrier_timeout: 2000})
      cb_executed_count = 0

      barriers.runCbAfterBarriers "double_resolve", ->
        cb_executed_count += 1
        return

      barriers.markBarrierAsResolved "double_resolve"
      barriers.markBarrierAsResolved "double_resolve"

      await sleep 100

      # Callback must execute exactly once
      expect(cb_executed_count).to.equal 1
      return
