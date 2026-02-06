# Tests for smart row formula formatter caching:
# - Layer 1: Per-column compile cache (_getCompiledFormula)
# - Layer 2: Per-row nested evaluation cache (sameTickCache in evaluateFormula)
#
# These tests use mock grid_control objects and are client-only since
# the formatter is installed via GridControl.installFormatter (client-only).

if Package["justdoinc:justdo-formula-fields"]? and Meteor.isClient
  {expect} = require "chai"

  describe "JustdoFormulaFields - Formatter Caching", ->
    formatter = null

    # Mock grid control with column data storage (mirrors grid_control._columns_data)
    mockGridControlWithColumnData = (field_defs_map) ->
      columns_data = {}
      return {
        getFieldDef: (field_id) ->
          return field_defs_map[field_id] or null
        getColumnData: (column_id, key) ->
          return columns_data[column_id]?[key]
        setColumnData: (column_id, key, value) ->
          if not columns_data[column_id]?
            columns_data[column_id] = {}
          columns_data[column_id][key] = value
          return
        clearColumnData: (column_id, key) ->
          if columns_data[column_id]?
            delete columns_data[column_id][key]
          return
        # Expose internal storage for test assertions
        _columns_data: columns_data
      }

    before (done) ->
      @timeout 30000
      APP.getEnv ->
        Meteor.defer ->
          formatter = GridControl.Formatters?.smartRowFormulaFormatter
          done()
          return
        return
      return

    afterEach ->
      # Clear sameTickCache after each test to avoid cross-test pollution
      JustdoHelpers.sameTickCachePurge()
      return

    # ========================================
    # Layer 1: Per-column compile cache
    # ========================================

    describe "_getCompiledFormula (compile cache)", ->

      it "should return compiled formula with correct properties", ->
        gc = mockGridControlWithColumnData({})
        result = formatter._getCompiledFormula(gc, "test_field", "{a} + {b}")
        expect(result).to.have.property "formula", "{a} + {b}"
        expect(result).to.have.property "mathjs_formula"
        expect(result).to.have.property "field_to_symbol"
        expect(result).to.have.property "compiled"
        expect(result.field_to_symbol).to.have.property "a"
        expect(result.field_to_symbol).to.have.property "b"
        return

      it "should store the compiled result in grid_control column data", ->
        gc = mockGridControlWithColumnData({})
        formatter._getCompiledFormula(gc, "test_field", "{a} + {b}")
        cached = gc.getColumnData("test_field", "srf_compiled")
        expect(cached).to.exist
        expect(cached.formula).to.equal "{a} + {b}"
        expect(cached.compiled).to.exist
        return

      it "should return cached result when formula has not changed", ->
        gc = mockGridControlWithColumnData({})
        result1 = formatter._getCompiledFormula(gc, "test_field", "{a} + {b}")
        result2 = formatter._getCompiledFormula(gc, "test_field", "{a} + {b}")
        # Should be the exact same object (reference equality)
        expect(result1).to.equal result2
        return

      it "should recompile when formula changes", ->
        gc = mockGridControlWithColumnData({})
        result1 = formatter._getCompiledFormula(gc, "test_field", "{a} + {b}")
        result2 = formatter._getCompiledFormula(gc, "test_field", "{a} * {b}")
        # Should be different objects
        expect(result1).to.not.equal result2
        expect(result1.formula).to.equal "{a} + {b}"
        expect(result2.formula).to.equal "{a} * {b}"
        return

      it "should cache independently per field", ->
        gc = mockGridControlWithColumnData({})
        result_f1 = formatter._getCompiledFormula(gc, "field_1", "{a} + {b}")
        result_f2 = formatter._getCompiledFormula(gc, "field_2", "{a} * {b}")
        # Different fields, different cache entries
        expect(result_f1).to.not.equal result_f2
        # Re-fetching should return cached
        expect(formatter._getCompiledFormula(gc, "field_1", "{a} + {b}")).to.equal result_f1
        expect(formatter._getCompiledFormula(gc, "field_2", "{a} * {b}")).to.equal result_f2
        return

      it "should produce a compiled expression that evaluates correctly", ->
        gc = mockGridControlWithColumnData({})
        {field_to_symbol, compiled} = formatter._getCompiledFormula(gc, "test_field", "{x} + {y}")
        args = {}
        args[field_to_symbol.x] = 10
        args[field_to_symbol.y] = 5
        result = compiled.evaluate(args)
        expect(result).to.equal 15
        return

      it "should produce identical evaluation results from cache", ->
        gc = mockGridControlWithColumnData({})
        # First call: compiles
        {field_to_symbol, compiled} = formatter._getCompiledFormula(gc, "test_field", "{x} + {y}")
        args = {}
        args[field_to_symbol.x] = 10
        args[field_to_symbol.y] = 5
        result1 = compiled.evaluate(args)

        # Second call: from cache
        cached = formatter._getCompiledFormula(gc, "test_field", "{x} + {y}")
        args2 = {}
        args2[cached.field_to_symbol.x] = 10
        args2[cached.field_to_symbol.y] = 5
        result2 = cached.compiled.evaluate(args2)

        expect(result1).to.equal result2
        expect(result1).to.equal 15
        return

      it "should throw for invalid formula (security restriction)", ->
        gc = mockGridControlWithColumnData({})
        expect(-> formatter._getCompiledFormula(gc, "test_field", "abs.constructor")).to.throw()
        return

      it "should not cache a failed compilation", ->
        gc = mockGridControlWithColumnData({})
        try
          formatter._getCompiledFormula(gc, "test_field", "abs.constructor")
        catch e
          # Expected

        # Column data should not contain a cached entry for this field
        cached = gc.getColumnData("test_field", "srf_compiled")
        # Either null or the entry has a different formula (from a previous test)
        if cached?
          expect(cached.formula).to.not.equal "abs.constructor"
        return

    # ========================================
    # Layer 2: Per-row nested evaluation cache (sameTickCache)
    # ========================================

    describe "evaluateFormula (sameTickCache)", ->

      it "should cache successful evaluation result in sameTickCache", ->
        gc = mockGridControlWithColumnData({
          srf_a:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{num_1}"
        })
        doc = {num_1: 42}
        path = "/0/test_task_1"

        result = formatter.evaluateFormula(gc, "srf_a", path, doc)
        expect(result.value).to.equal 42

        # Verify it's in sameTickCache
        cache_key = "srf-eval::srf_a::#{path}"
        expect(JustdoHelpers.sameTickCacheExists(cache_key)).to.be.true
        cached = JustdoHelpers.sameTickCacheGet(cache_key)
        expect(cached.value).to.equal 42
        return

      it "should return cached result on second call for same field and path", ->
        gc = mockGridControlWithColumnData({
          srf_a:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{num_1}"
        })
        doc = {num_1: 42}
        path = "/0/test_task_1"

        result1 = formatter.evaluateFormula(gc, "srf_a", path, doc)
        result2 = formatter.evaluateFormula(gc, "srf_a", path, doc)

        # Should be the exact same object (from cache)
        expect(result1).to.equal result2
        return

      it "should cache independently per path (different rows)", ->
        gc = mockGridControlWithColumnData({
          srf_a:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{num_1}"
        })
        doc1 = {num_1: 10}
        doc2 = {num_1: 20}

        result1 = formatter.evaluateFormula(gc, "srf_a", "/0/task_1", doc1)
        result2 = formatter.evaluateFormula(gc, "srf_a", "/0/task_2", doc2)

        expect(result1.value).to.equal 10
        expect(result2.value).to.equal 20
        expect(result1).to.not.equal result2
        return

      it "should cache independently per field_id", ->
        gc = mockGridControlWithColumnData({
          srf_a:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{num_1}"
          srf_b:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{num_1}"
        })
        doc = {num_1: 42}
        path = "/0/test_task_1"

        result_a = formatter.evaluateFormula(gc, "srf_a", path, doc)
        result_b = formatter.evaluateFormula(gc, "srf_b", path, doc)

        # Same value but different cache entries
        expect(result_a.value).to.equal 42
        expect(result_b.value).to.equal 42
        expect(result_a).to.not.equal result_b
        return

      it "should cache null value for empty formula", ->
        gc = mockGridControlWithColumnData({
          srf_a:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: ""
        })
        path = "/0/test_task_1"

        result = formatter.evaluateFormula(gc, "srf_a", path, {})
        expect(result.value).to.be.null

        # Verify cached
        cache_key = "srf-eval::srf_a::#{path}"
        expect(JustdoHelpers.sameTickCacheExists(cache_key)).to.be.true
        return

      it "should NOT cache circular dependency error", ->
        # Circular: srf_a -> srf_b -> srf_a
        gc = mockGridControlWithColumnData({
          srf_a:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{srf_b}"
          srf_b:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{srf_a}"
        })
        path = "/0/test_task_1"

        # Evaluate srf_a with srf_a already in the evaluating set (simulates
        # being called from within srf_a's own evaluation chain)
        evaluating = {"srf_a": true}
        result = formatter.evaluateFormula(gc, "srf_a", path, {}, evaluating)
        expect(result.error).to.be.true

        # The circular guard return should NOT be cached
        cache_key = "srf-eval::srf_a::#{path}"
        expect(JustdoHelpers.sameTickCacheExists(cache_key)).to.be.false
        return

      it "should return cached result even when called with different _evaluating_fields", ->
        gc = mockGridControlWithColumnData({
          srf_b:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{num_1}"
        })
        doc = {num_1: 99}
        path = "/0/test_task_1"

        # First call: no evaluating fields
        result1 = formatter.evaluateFormula(gc, "srf_b", path, doc, {})
        expect(result1.value).to.equal 99

        # Second call: different evaluating fields context
        result2 = formatter.evaluateFormula(gc, "srf_b", path, doc, {"srf_a": true})
        # Should return the cached result
        expect(result2).to.equal result1
        return

    # ========================================
    # sameTickCache lifecycle
    # ========================================

    describe "sameTickCache lifecycle", ->

      it "should auto-clear cached evaluateFormula results after the tick ends", (done) ->
        @timeout 5000
        gc = mockGridControlWithColumnData({
          srf_a:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{num_1}"
        })
        doc = {num_1: 42}
        path = "/0/test_task_1"

        result = formatter.evaluateFormula(gc, "srf_a", path, doc)
        expect(result.value).to.equal 42

        cache_key = "srf-eval::srf_a::#{path}"
        expect(JustdoHelpers.sameTickCacheExists(cache_key)).to.be.true

        # The sameTickCache auto-clear job is scheduled via setTimeout(0).
        # Using a 50ms delay ensures the clear job has fired before we assert.
        setTimeout ->
          expect(JustdoHelpers.sameTickCacheExists(cache_key)).to.be.false
          done()
          return
        , 50
        return

      it "should return fresh results in a new tick when doc values change", (done) ->
        @timeout 5000
        gc = mockGridControlWithColumnData({
          srf_a:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{num_1}"
        })
        path = "/0/test_task_1"

        # Tick 1: evaluate with original value
        result1 = formatter.evaluateFormula(gc, "srf_a", path, {num_1: 42})
        expect(result1.value).to.equal 42

        # Wait for auto-clear (setTimeout 0 fires before our 50ms timeout)
        setTimeout ->
          # Tick 2: evaluate with changed doc — should produce fresh result
          result2 = formatter.evaluateFormula(gc, "srf_a", path, {num_1: 99})
          expect(result2.value).to.equal 99
          # Must be a new object, not the stale cached reference
          expect(result2).to.not.equal result1
          done()
          return
        , 50
        return

      it "should reuse nested formula evaluation when referenced by two parent columns in the same tick", ->
        gc = mockGridControlWithColumnData({
          srf_parent_a:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{srf_child} + {num_1}"
          srf_parent_b:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{srf_child} * {num_2}"
          srf_child:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{num_3}"
        })
        doc = {num_1: 10, num_2: 5, num_3: 100}
        path = "/0/test_task_1"

        # Evaluate parent A — internally evaluates srf_child and caches it
        result_a = formatter.evaluateFormula(gc, "srf_parent_a", path, doc)
        expect(result_a.value).to.equal 110  # srf_child(100) + num_1(10)

        child_cache_key = "srf-eval::srf_child::#{path}"
        cached_child_ref = JustdoHelpers.sameTickCacheGet(child_cache_key)
        expect(cached_child_ref).to.exist
        expect(cached_child_ref.value).to.equal 100

        # Evaluate parent B — should reuse the cached srf_child result
        result_b = formatter.evaluateFormula(gc, "srf_parent_b", path, doc)
        expect(result_b.value).to.equal 500  # srf_child(100) * num_2(5)

        # Verify srf_child's cached object is the exact same reference (not re-evaluated)
        cached_child_ref_after = JustdoHelpers.sameTickCacheGet(child_cache_key)
        expect(cached_child_ref_after).to.equal cached_child_ref
        return

      it "should correctly handle diamond dependencies via cache (prevents false circular detection)", ->
        # Critical correctness test: _evaluating_fields accumulates all visited
        # field IDs without cleanup. In a diamond pattern (D -> A,B; A -> C; B -> C),
        # when A evaluates C, 'C' is added to _evaluating_fields. When B later
        # tries to evaluate C, 'C' is still in _evaluating_fields. Without the
        # sameTickCache returning C's cached result BEFORE the circular guard check,
        # this would incorrectly report a circular dependency.
        gc = mockGridControlWithColumnData({
          srf_d:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{srf_a} + {srf_b}"
          srf_a:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{srf_c}"
          srf_b:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{srf_c}"
          srf_c:
            grid_column_formatter: "smartRowFormulaFormatter"
            grid_column_formatter_options:
              formula: "{num_1}"
        })
        doc = {num_1: 42}
        path = "/0/test_task_1"

        result = formatter.evaluateFormula(gc, "srf_d", path, doc)
        # D = A + B = C + C = 42 + 42 = 84
        expect(result.value).to.equal 84
        expect(result.error).to.not.exist
        return
