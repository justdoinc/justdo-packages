# Tests for JustdoFormulaFields dependency tracking methods:
# - getSmartRowFormulaDependencies
# - getFlattenedDependencies
# - getFieldsDependingOnField
# - updateDependenciesForField
# - updateDependentFieldsDependencies
#
# These methods are defined in lib/client/api.coffee, so we guard with Meteor.isClient.
# We stub getCurrentGridControlObject to avoid needing the actual grid control.

if Package["justdoinc:justdo-formula-fields"]? and Meteor.isClient
  {expect} = require "chai"

  describe "JustdoFormulaFields - Dependency Tracking", ->
    instance = null
    originalGetGridControl = null

    # Mock grid control that returns field definitions by field_id
    mockGridControl = (field_defs_map) ->
      return {
        getFieldDef: (field_id) ->
          return field_defs_map[field_id] or null
      }

    before (done) ->
      @timeout 30000
      APP.getEnv ->
        Meteor.defer ->
          instance = APP.justdo_formula_fields
          # Save the original method so we can restore it
          originalGetGridControl = instance.getCurrentGridControlObject
          done()
          return
        return
      return

    afterEach ->
      # Restore original method after each test
      instance.getCurrentGridControlObject = originalGetGridControl
      return

    # ========================================
    # getSmartRowFormulaDependencies
    # ========================================

    describe "getSmartRowFormulaDependencies", ->

      it "should return empty array for null formula", ->
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getSmartRowFormulaDependencies(null)
        expect(result).to.deep.equal []
        return

      it "should return empty array for empty string formula", ->
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getSmartRowFormulaDependencies("")
        expect(result).to.deep.equal []
        return

      it "should extract single field dependency", ->
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getSmartRowFormulaDependencies("{field_a} + 1")
        expect(result).to.include "field_a"
        expect(result).to.have.length 1
        return

      it "should extract multiple field dependencies", ->
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getSmartRowFormulaDependencies("{field_a} + {field_b}")
        expect(result).to.include "field_a"
        expect(result).to.include "field_b"
        expect(result).to.have.length 2
        return

      it "should deduplicate repeated field references", ->
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getSmartRowFormulaDependencies("{field_a} + {field_a}")
        expect(result).to.include "field_a"
        expect(result).to.have.length 1
        return

      it "should include grid_dependencies_fields from dependent fields", ->
        field_defs = {
          field_a:
            grid_dependencies_fields: ["dep_x", "dep_y"]
        }
        instance.getCurrentGridControlObject = -> mockGridControl(field_defs)
        result = instance.getSmartRowFormulaDependencies("{field_a}")
        expect(result).to.include "field_a"
        expect(result).to.include "dep_x"
        expect(result).to.include "dep_y"
        return

      it "should deduplicate when grid_dependencies overlap with direct deps", ->
        field_defs = {
          field_a:
            grid_dependencies_fields: ["field_b"]
        }
        instance.getCurrentGridControlObject = -> mockGridControl(field_defs)
        result = instance.getSmartRowFormulaDependencies("{field_a} + {field_b}")
        expect(result).to.include "field_a"
        expect(result).to.include "field_b"
        # No duplicates
        expect(result.filter((x) -> x == "field_b")).to.have.length 1
        return

      it "should not transitively chase grid_dependencies_fields of added dependencies", ->
        # field_a has grid_deps=[field_c], field_c has grid_deps=[field_d].
        # getSmartRowFormulaDependencies should only collect one level of
        # grid_dependencies_fields (from the formula's direct references),
        # NOT chase into field_c's own grid_dependencies_fields.
        # Transitive resolution is getFlattenedDependencies' responsibility.
        field_defs = {
          field_a:
            grid_dependencies_fields: ["field_c"]
          field_c:
            grid_dependencies_fields: ["field_d"]
        }
        instance.getCurrentGridControlObject = -> mockGridControl(field_defs)
        result = instance.getSmartRowFormulaDependencies("{field_a}")
        expect(result).to.include "field_a"
        expect(result).to.include "field_c"
        # field_d should NOT be included — it's a transitive dep of field_c,
        # not a direct grid_dependency of a formula reference
        expect(result).to.not.include "field_d"
        return

      it "should handle mutual grid_dependencies without infinite iteration", ->
        # field_a has grid_deps=[field_b], field_b has grid_deps=[field_a].
        # Before the two-pass fix, the array was mutated during iteration,
        # which could chase in circles. Now it only iterates over the
        # original formula references.
        field_defs = {
          field_a:
            grid_dependencies_fields: ["field_b"]
          field_b:
            grid_dependencies_fields: ["field_a"]
        }
        instance.getCurrentGridControlObject = -> mockGridControl(field_defs)
        result = instance.getSmartRowFormulaDependencies("{field_a} + {field_b}")
        expect(result).to.include "field_a"
        expect(result).to.include "field_b"
        # Should contain exactly 2 entries — no duplicates from circular grid_deps
        expect(result).to.have.length 2
        return

    # ========================================
    # getFlattenedDependencies
    # ========================================

    describe "getFlattenedDependencies", ->

      smart_row_type = JustdoFormulaFields.smart_row_formula_field_type_id

      makeSmartRowField = (field_id, formula, extra = {}) ->
        _.extend {
          field_id: field_id
          field_type: "number"
          custom_field_type_id: smart_row_type
          field_options:
            formula: formula
        }, extra

      makeNumberField = (field_id) ->
        {
          field_id: field_id
          field_type: "number"
          custom_field_type_id: "basic-number-decimal"
        }

      it "should return empty array for non-existent field", ->
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getFlattenedDependencies("nonexistent", [])
        expect(result).to.deep.equal []
        return

      it "should return empty array for field with no formula", ->
        custom_fields = [makeSmartRowField("srf_1", null)]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getFlattenedDependencies("srf_1", custom_fields)
        expect(result).to.deep.equal []
        return

      it "should return direct dependencies for simple formula", ->
        custom_fields = [
          makeSmartRowField("srf_1", "{num_1} + {num_2}")
          makeNumberField("num_1")
          makeNumberField("num_2")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getFlattenedDependencies("srf_1", custom_fields)
        expect(result).to.include "num_1"
        expect(result).to.include "num_2"
        return

      it "should recursively resolve nested smart row formula dependencies", ->
        # srf_1 depends on srf_2, srf_2 depends on num_1
        custom_fields = [
          makeSmartRowField("srf_1", "{srf_2} + 1")
          makeSmartRowField("srf_2", "{num_1}")
          makeNumberField("num_1")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getFlattenedDependencies("srf_1", custom_fields)
        expect(result).to.include "srf_2"
        expect(result).to.include "num_1"
        return

      it "should handle deep nesting (3 levels)", ->
        # srf_1 -> srf_2 -> srf_3 -> num_1
        custom_fields = [
          makeSmartRowField("srf_1", "{srf_2}")
          makeSmartRowField("srf_2", "{srf_3}")
          makeSmartRowField("srf_3", "{num_1}")
          makeNumberField("num_1")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getFlattenedDependencies("srf_1", custom_fields)
        expect(result).to.include "srf_2"
        expect(result).to.include "srf_3"
        expect(result).to.include "num_1"
        return

      it "should not include the field itself in its dependencies", ->
        custom_fields = [
          makeSmartRowField("srf_1", "{num_1}")
          makeNumberField("num_1")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getFlattenedDependencies("srf_1", custom_fields)
        expect(result).to.not.include "srf_1"
        return

      it "should handle circular dependencies without infinite loop", ->
        # srf_1 -> srf_2 -> srf_1 (circular)
        custom_fields = [
          makeSmartRowField("srf_1", "{srf_2}")
          makeSmartRowField("srf_2", "{srf_1}")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        # Should not throw or hang
        result = instance.getFlattenedDependencies("srf_1", custom_fields)
        expect(result).to.include "srf_2"
        # srf_1 should be excluded because it's the field itself
        expect(result).to.not.include "srf_1"
        return

      it "should handle diamond dependencies without duplicates", ->
        # srf_1 -> srf_2, srf_3
        # srf_2 -> num_1
        # srf_3 -> num_1
        custom_fields = [
          makeSmartRowField("srf_1", "{srf_2} + {srf_3}")
          makeSmartRowField("srf_2", "{num_1}")
          makeSmartRowField("srf_3", "{num_1}")
          makeNumberField("num_1")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getFlattenedDependencies("srf_1", custom_fields)
        expect(result).to.include "srf_2"
        expect(result).to.include "srf_3"
        expect(result).to.include "num_1"
        # num_1 should appear only once
        expect(result.filter((x) -> x == "num_1")).to.have.length 1
        return

      it "should not recurse into non-smart-row-formula dependencies", ->
        custom_fields = [
          makeSmartRowField("srf_1", "{num_1} + {num_2}")
          makeNumberField("num_1")
          makeNumberField("num_2")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getFlattenedDependencies("srf_1", custom_fields)
        # Only direct dependencies, no recursion for number fields
        expect(result).to.include "num_1"
        expect(result).to.include "num_2"
        expect(result).to.have.length 2
        return

    # ========================================
    # getFieldsDependingOnField
    # ========================================

    describe "getFieldsDependingOnField", ->

      smart_row_type = JustdoFormulaFields.smart_row_formula_field_type_id

      makeSmartRowField = (field_id, formula) ->
        {
          field_id: field_id
          field_type: "number"
          custom_field_type_id: smart_row_type
          field_options:
            formula: formula
        }

      makeNumberField = (field_id) ->
        {
          field_id: field_id
          field_type: "number"
          custom_field_type_id: "basic-number-decimal"
        }

      it "should return empty array when no fields depend on target", ->
        custom_fields = [
          makeSmartRowField("srf_1", "{num_1}")
          makeNumberField("num_1")
          makeNumberField("num_2")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getFieldsDependingOnField("num_2", custom_fields)
        expect(result).to.deep.equal []
        return

      it "should find direct dependents", ->
        custom_fields = [
          makeSmartRowField("srf_1", "{num_1}")
          makeSmartRowField("srf_2", "{num_1} + {num_2}")
          makeNumberField("num_1")
          makeNumberField("num_2")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getFieldsDependingOnField("num_1", custom_fields)
        expect(result).to.include "srf_1"
        expect(result).to.include "srf_2"
        return

      it "should find indirect dependents (transitive)", ->
        # srf_1 -> srf_2 -> num_1
        custom_fields = [
          makeSmartRowField("srf_1", "{srf_2}")
          makeSmartRowField("srf_2", "{num_1}")
          makeNumberField("num_1")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getFieldsDependingOnField("num_1", custom_fields)
        expect(result).to.include "srf_1"
        expect(result).to.include "srf_2"
        return

      it "should not include the target field itself", ->
        custom_fields = [
          makeSmartRowField("srf_1", "{num_1}")
          makeNumberField("num_1")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getFieldsDependingOnField("srf_1", custom_fields)
        expect(result).to.not.include "srf_1"
        return

      it "should not include non-smart-row-formula fields", ->
        custom_fields = [
          makeSmartRowField("srf_1", "{num_1}")
          makeNumberField("num_1")
          makeNumberField("num_2")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.getFieldsDependingOnField("num_1", custom_fields)
        # Only srf_1 depends on num_1, not num_2
        expect(result).to.deep.equal ["srf_1"]
        return

    # ========================================
    # updateDependenciesForField
    # ========================================

    describe "updateDependenciesForField", ->

      smart_row_type = JustdoFormulaFields.smart_row_formula_field_type_id

      makeSmartRowField = (field_id, formula) ->
        {
          field_id: field_id
          field_type: "number"
          custom_field_type_id: smart_row_type
          field_options:
            formula: formula
        }

      makeNumberField = (field_id) ->
        {
          field_id: field_id
          field_type: "number"
          custom_field_type_id: "basic-number-decimal"
        }

      it "should return false for non-existent field", ->
        result = instance.updateDependenciesForField("nonexistent", [])
        expect(result).to.be.false
        return

      it "should return false for non-smart-row-formula field", ->
        custom_fields = [makeNumberField("num_1")]
        result = instance.updateDependenciesForField("num_1", custom_fields)
        expect(result).to.be.false
        return

      it "should set grid_dependencies_fields on the field_def", ->
        custom_fields = [
          makeSmartRowField("srf_1", "{num_1} + {num_2}")
          makeNumberField("num_1")
          makeNumberField("num_2")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.updateDependenciesForField("srf_1", custom_fields)
        expect(result).to.be.true
        field_def = _.find custom_fields, (cf) -> cf.field_id is "srf_1"
        expect(field_def.grid_dependencies_fields).to.include "num_1"
        expect(field_def.grid_dependencies_fields).to.include "num_2"
        return

      it "should delete grid_dependencies_fields when formula has no dependencies", ->
        field_def = makeSmartRowField("srf_1", "")
        field_def.grid_dependencies_fields = ["old_dep"]
        custom_fields = [field_def]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.updateDependenciesForField("srf_1", custom_fields)
        expect(result).to.be.true
        expect(field_def).to.not.have.property "grid_dependencies_fields"
        return

      it "should include nested dependencies in grid_dependencies_fields", ->
        custom_fields = [
          makeSmartRowField("srf_1", "{srf_2}")
          makeSmartRowField("srf_2", "{num_1}")
          makeNumberField("num_1")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        instance.updateDependenciesForField("srf_1", custom_fields)
        field_def = _.find custom_fields, (cf) -> cf.field_id is "srf_1"
        expect(field_def.grid_dependencies_fields).to.include "srf_2"
        expect(field_def.grid_dependencies_fields).to.include "num_1"
        return

    # ========================================
    # updateDependentFieldsDependencies
    # ========================================

    describe "updateDependentFieldsDependencies", ->

      smart_row_type = JustdoFormulaFields.smart_row_formula_field_type_id

      makeSmartRowField = (field_id, formula) ->
        {
          field_id: field_id
          field_type: "number"
          custom_field_type_id: smart_row_type
          field_options:
            formula: formula
        }

      makeNumberField = (field_id) ->
        {
          field_id: field_id
          field_type: "number"
          custom_field_type_id: "basic-number-decimal"
        }

      it "should return empty array when no dependent fields exist", ->
        custom_fields = [
          makeSmartRowField("srf_1", "{num_1}")
          makeNumberField("num_1")
          makeNumberField("num_2")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.updateDependentFieldsDependencies("num_2", custom_fields)
        expect(result).to.deep.equal []
        return

      it "should update all directly dependent fields", ->
        custom_fields = [
          makeSmartRowField("srf_1", "{num_1}")
          makeSmartRowField("srf_2", "{num_1} + {num_2}")
          makeNumberField("num_1")
          makeNumberField("num_2")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.updateDependentFieldsDependencies("num_1", custom_fields)
        expect(result).to.include "srf_1"
        expect(result).to.include "srf_2"
        return

      it "should update transitively dependent fields", ->
        # srf_1 -> srf_2 -> num_1
        custom_fields = [
          makeSmartRowField("srf_1", "{srf_2}")
          makeSmartRowField("srf_2", "{num_1}")
          makeNumberField("num_1")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        result = instance.updateDependentFieldsDependencies("num_1", custom_fields)
        expect(result).to.include "srf_1"
        expect(result).to.include "srf_2"
        return

      it "should modify grid_dependencies_fields on dependent field_defs in place", ->
        custom_fields = [
          makeSmartRowField("srf_1", "{num_1}")
          makeNumberField("num_1")
        ]
        instance.getCurrentGridControlObject = -> mockGridControl({})
        instance.updateDependentFieldsDependencies("num_1", custom_fields)
        field_def = _.find custom_fields, (cf) -> cf.field_id is "srf_1"
        expect(field_def.grid_dependencies_fields).to.include "num_1"
        return
