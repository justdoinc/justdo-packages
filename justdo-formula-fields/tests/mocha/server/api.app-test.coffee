# Tests for JustdoFormulaFields prototype API methods:
# - replaceFieldsWithSymbols
# - processFormula
# - throwErrorIfNotAllowedCustomFieldDef
# - _isFieldAvailableForFormulas / _isFieldAvailableForSmartFormula / _isFieldAvailableForSmartRowFormula

if Package["justdoinc:justdo-formula-fields"]?
  {expect} = require "chai"

  describe "JustdoFormulaFields - API", ->
    instance = null

    before (done) ->
      @timeout 30000
      APP.getEnv ->
        # Wait for APP to be ready so APP.justdo_formula_fields is available
        Meteor.defer ->
          instance = APP.justdo_formula_fields
          done()
          return
        return
      return

    # --- Helper to build mock custom field definitions ---
    buildCustomField = (field_id, opts = {}) ->
      _.extend {
        field_id: field_id
        field_type: opts.field_type or "number"
        custom_field_type_id: opts.custom_field_type_id or "basic-number-decimal"
        disabled: opts.disabled or false
      }, opts

    buildFormulaField = (field_id, opts = {}) ->
      buildCustomField field_id, _.extend({
        custom_field_type_id: JustdoFormulaFields.custom_field_type_id
      }, opts)

    buildSmartRowFormulaField = (field_id, opts = {}) ->
      buildCustomField field_id, _.extend({
        custom_field_type_id: JustdoFormulaFields.smart_row_formula_field_type_id
      }, opts)

    # ========================================
    # replaceFieldsWithSymbols
    # ========================================

    describe "replaceFieldsWithSymbols", ->

      it "should replace a single field with first symbol", ->
        result = instance.replaceFieldsWithSymbols("{field_a} + 1")
        first_symbol = JustdoFormulaFields.symbols_indexes[0]
        expect(result.mathjs_formula).to.equal "#{first_symbol} + 1"
        expect(result.field_to_symbol).to.have.property "field_a", first_symbol
        return

      it "should replace two fields with sequential symbols", ->
        result = instance.replaceFieldsWithSymbols("{field_a} + {field_b}")
        sym_a = JustdoFormulaFields.symbols_indexes[0]
        sym_b = JustdoFormulaFields.symbols_indexes[1]
        expect(result.mathjs_formula).to.equal "#{sym_a} + #{sym_b}"
        expect(result.field_to_symbol.field_a).to.equal sym_a
        expect(result.field_to_symbol.field_b).to.equal sym_b
        return

      it "should reuse same symbol for repeated field reference", ->
        result = instance.replaceFieldsWithSymbols("{field_a} + {field_a}")
        sym_a = JustdoFormulaFields.symbols_indexes[0]
        expect(result.mathjs_formula).to.equal "#{sym_a} + #{sym_a}"
        expect(_.keys(result.field_to_symbol)).to.have.length 1
        return

      it "should preserve arithmetic operators and numbers", ->
        result = instance.replaceFieldsWithSymbols("{x} * 2 + {y} / 3")
        expect(result.mathjs_formula).to.contain "* 2 +"
        expect(result.mathjs_formula).to.contain "/ 3"
        return

      it "should handle formula with no field references", ->
        result = instance.replaceFieldsWithSymbols("1 + 2")
        expect(result.mathjs_formula).to.equal "1 + 2"
        expect(result.field_to_symbol).to.be.empty
        return

      it "should throw when formula has more unique fields than symbols_indexes length", ->
        # Build a formula with more unique fields than available symbols
        max_fields = JustdoFormulaFields.symbols_indexes.length
        fields = ("{field_#{i}}" for i in [0..max_fields]).join(" + ")
        expect(-> instance.replaceFieldsWithSymbols(fields)).to.throw()
        return

      it "should handle exactly symbols_indexes.length unique fields without error", ->
        max_fields = JustdoFormulaFields.symbols_indexes.length
        fields = ("{field_#{i}}" for i in [0...max_fields]).join(" + ")
        result = instance.replaceFieldsWithSymbols(fields)
        expect(_.keys(result.field_to_symbol)).to.have.length max_fields
        return

    # ========================================
    # throwErrorIfNotAllowedCustomFieldDef
    # ========================================

    describe "throwErrorIfNotAllowedCustomFieldDef", ->

      it "should throw for disabled custom field", ->
        field_def = buildCustomField "f1", disabled: true
        expect(-> instance.throwErrorIfNotAllowedCustomFieldDef(field_def)).to.throw()
        return

      it "for regular formula: should accept number type", ->
        field_def = buildCustomField "f1", field_type: "number", custom_field_type_id: "basic-number-decimal"
        expect(-> instance.throwErrorIfNotAllowedCustomFieldDef(field_def, JustdoFormulaFields.custom_field_type_id)).to.not.throw()
        return

      it "for regular formula: should reject text type", ->
        field_def = buildCustomField "f1", field_type: "text", custom_field_type_id: "basic-text"
        expect(-> instance.throwErrorIfNotAllowedCustomFieldDef(field_def, JustdoFormulaFields.custom_field_type_id)).to.throw()
        return

      it "for regular formula: should reject calc custom_field_type_id", ->
        field_def = buildCustomField "f1", field_type: "number", custom_field_type_id: "basic-calc"
        expect(-> instance.throwErrorIfNotAllowedCustomFieldDef(field_def, JustdoFormulaFields.custom_field_type_id)).to.throw()
        return

      it "for smart row formula: should accept number type", ->
        field_def = buildCustomField "f1", field_type: "number", custom_field_type_id: "basic-number-decimal"
        expect(-> instance.throwErrorIfNotAllowedCustomFieldDef(field_def, JustdoFormulaFields.smart_row_formula_field_type_id)).to.not.throw()
        return

      it "for smart row formula: should accept calc type", ->
        field_def = buildCustomField "f1", field_type: "calc", custom_field_type_id: "basic-calc"
        expect(-> instance.throwErrorIfNotAllowedCustomFieldDef(field_def, JustdoFormulaFields.smart_row_formula_field_type_id)).to.not.throw()
        return

      it "for smart row formula: should accept smart-row-formula type", ->
        field_def = buildCustomField "f1", field_type: "number", custom_field_type_id: JustdoFormulaFields.smart_row_formula_field_type_id
        expect(-> instance.throwErrorIfNotAllowedCustomFieldDef(field_def, JustdoFormulaFields.smart_row_formula_field_type_id)).to.not.throw()
        return

      it "for smart row formula: should reject text type", ->
        field_def = buildCustomField "f1", field_type: "text", custom_field_type_id: "basic-text"
        expect(-> instance.throwErrorIfNotAllowedCustomFieldDef(field_def, JustdoFormulaFields.smart_row_formula_field_type_id)).to.throw()
        return

      it "should handle missing custom_field_type_id (backward compat)", ->
        # Old fields may only have field_type without custom_field_type_id
        field_def = {field_id: "f1", field_type: "number", disabled: false}
        expect(-> instance.throwErrorIfNotAllowedCustomFieldDef(field_def, JustdoFormulaFields.custom_field_type_id)).to.not.throw()
        return

      it "should default formula_type to regular formula when not specified", ->
        # Without formula_type, calc should be rejected (regular formula rules)
        field_def = buildCustomField "f1", field_type: "calc", custom_field_type_id: "basic-calc"
        expect(-> instance.throwErrorIfNotAllowedCustomFieldDef(field_def)).to.throw()
        return

    # ========================================
    # _isFieldAvailableForFormulas
    # ========================================

    describe "_isFieldAvailableForFormulas", ->

      makeFieldDef = (overrides = {}) ->
        _.extend {
          _id: "test_field"
          type: Number
          grid_visible_column: true
          grid_column_formatter: null
        }, overrides

      it "should throw for non-string _id", ->
        field_def = makeFieldDef(_id: 123)
        expect(-> instance._isFieldAvailableForFormulas(field_def)).to.throw()
        return

      it "should return false for private fields (priv: prefix)", ->
        field_def = makeFieldDef(_id: "priv:secret")
        expect(instance._isFieldAvailableForFormulas(field_def)).to.be.false
        return

      it "should return false for hidden columns", ->
        field_def = makeFieldDef(grid_visible_column: false)
        expect(instance._isFieldAvailableForFormulas(field_def)).to.be.false
        return

      it "should return false for forbidden fields (_id)", ->
        field_def = makeFieldDef(_id: "_id")
        expect(instance._isFieldAvailableForFormulas(field_def)).to.be.false
        return

      it "for regular formula: should accept field with type Number", ->
        field_def = makeFieldDef(type: Number)
        expect(instance._isFieldAvailableForFormulas(field_def, JustdoFormulaFields.custom_field_type_id)).to.be.true
        return

      it "for regular formula: should reject field with type String", ->
        field_def = makeFieldDef(type: String)
        expect(instance._isFieldAvailableForFormulas(field_def, JustdoFormulaFields.custom_field_type_id)).to.be.false
        return

      it "for regular formula: should reject field with calculatedFieldFormatter (not Number type)", ->
        field_def = makeFieldDef(type: String, grid_column_formatter: "calculatedFieldFormatter")
        expect(instance._isFieldAvailableForFormulas(field_def, JustdoFormulaFields.custom_field_type_id)).to.be.false
        return

      it "for smart row formula: should accept field with type Number", ->
        field_def = makeFieldDef(type: Number)
        expect(instance._isFieldAvailableForFormulas(field_def, JustdoFormulaFields.smart_row_formula_field_type_id)).to.be.true
        return

      it "for smart row formula: should accept field with calculatedFieldFormatter", ->
        field_def = makeFieldDef(type: String, grid_column_formatter: "calculatedFieldFormatter")
        expect(instance._isFieldAvailableForFormulas(field_def, JustdoFormulaFields.smart_row_formula_field_type_id)).to.be.true
        return

      it "for smart row formula: should accept field with smartRowFormulaFormatter", ->
        field_def = makeFieldDef(type: String, grid_column_formatter: "smartRowFormulaFormatter")
        expect(instance._isFieldAvailableForFormulas(field_def, JustdoFormulaFields.smart_row_formula_field_type_id)).to.be.true
        return

      it "for smart row formula: should reject field with unsupported formatter and non-Number type", ->
        field_def = makeFieldDef(type: String, grid_column_formatter: "keyValueFormatter")
        expect(instance._isFieldAvailableForFormulas(field_def, JustdoFormulaFields.smart_row_formula_field_type_id)).to.be.false
        return

      it "should default to regular formula rules when formula_type not specified", ->
        # calculatedFieldFormatter with non-Number type should be rejected by default
        field_def = makeFieldDef(type: String, grid_column_formatter: "calculatedFieldFormatter")
        expect(instance._isFieldAvailableForFormulas(field_def)).to.be.false
        return

    # ========================================
    # processFormula
    # ========================================

    describe "processFormula", ->

      # Minimal custom fields set for testing
      makeCustomFields = ->
        [
          buildFormulaField("formula_field_1")
          buildSmartRowFormulaField("srf_field_1")
          buildCustomField("num_field_1", field_type: "number", custom_field_type_id: "basic-number-decimal")
          buildCustomField("num_field_2", field_type: "number", custom_field_type_id: "basic-number-decimal")
          buildCustomField("calc_field_1", field_type: "calc", custom_field_type_id: "basic-calc")
          buildCustomField("text_field_1", field_type: "text", custom_field_type_id: "basic-text")
          buildCustomField("disabled_field_1", field_type: "number", custom_field_type_id: "basic-number-decimal", disabled: true)
        ]

      it "should process a valid formula and return result object", ->
        custom_fields = makeCustomFields()
        result = instance.processFormula("{num_field_1} + {num_field_2}", "formula_field_1", custom_fields)
        expect(result).to.have.property "mathjs_formula"
        expect(result).to.have.property "parsed_formula"
        expect(result).to.have.property "field_to_symbol"
        expect(result.field_to_symbol).to.have.property "num_field_1"
        expect(result.field_to_symbol).to.have.property "num_field_2"
        return

      it "should map fields to sequential symbols", ->
        custom_fields = makeCustomFields()
        result = instance.processFormula("{num_field_1} + {num_field_2}", "formula_field_1", custom_fields)
        sym_a = JustdoFormulaFields.symbols_indexes[0]
        sym_b = JustdoFormulaFields.symbols_indexes[1]
        expect(result.field_to_symbol.num_field_1).to.equal sym_a
        expect(result.field_to_symbol.num_field_2).to.equal sym_b
        expect(result.mathjs_formula).to.equal "#{sym_a} + #{sym_b}"
        return

      it "should throw for empty project_custom_fields", ->
        expect(-> instance.processFormula("{x}", "f1", [])).to.throw()
        expect(-> instance.processFormula("{x}", "f1", null)).to.throw()
        return

      it "should throw for unknown formula_field_id", ->
        custom_fields = makeCustomFields()
        expect(-> instance.processFormula("{num_field_1}", "nonexistent", custom_fields)).to.throw()
        return

      it "should throw for disabled formula field", ->
        custom_fields = makeCustomFields()
        disabled_formula = buildFormulaField("disabled_formula", disabled: true)
        custom_fields.push disabled_formula
        expect(-> instance.processFormula("{num_field_1}", "disabled_formula", custom_fields)).to.throw()
        return

      it "should throw for field that is not a formula type", ->
        custom_fields = makeCustomFields()
        expect(-> instance.processFormula("{num_field_1}", "num_field_1", custom_fields)).to.throw()
        return

      it "should accept smart-row-formula type when formula_type option is set", ->
        custom_fields = makeCustomFields()
        result = instance.processFormula(
          "{num_field_1}", "srf_field_1", custom_fields,
          {formula_type: JustdoFormulaFields.smart_row_formula_field_type_id}
        )
        expect(result).to.have.property "mathjs_formula"
        return

      it "should throw for self-referencing formula", ->
        custom_fields = makeCustomFields()
        expect(-> instance.processFormula("{formula_field_1}", "formula_field_1", custom_fields)).to.throw()
        return

      it "should throw for formula with no field placeholders", ->
        custom_fields = makeCustomFields()
        expect(-> instance.processFormula("1 + 2", "formula_field_1", custom_fields)).to.throw()
        return

      it "should throw for formula exceeding max placeholders", ->
        custom_fields = makeCustomFields()
        max_placeholders = JustdoFormulaFields.max_allowed_fields_placeholders
        # Add enough number fields to exceed the limit
        for i in [3..max_placeholders + 1]
          custom_fields.push buildCustomField("num_field_#{i}", field_type: "number", custom_field_type_id: "basic-number-decimal")
        # Build formula with max+1 unique fields, using compact operator
        # to avoid hitting max_allowed_chars_in_processed_mathjs_formula
        fields = ("{num_field_#{i}}" for i in [1..max_placeholders + 1]).join("*")
        expect(-> instance.processFormula(fields, "formula_field_1", custom_fields)).to.throw()
        return

      it "should accept formula with exactly max placeholders", ->
        custom_fields = makeCustomFields()
        max_placeholders = JustdoFormulaFields.max_allowed_fields_placeholders
        for i in [3..max_placeholders]
          custom_fields.push buildCustomField("num_field_#{i}", field_type: "number", custom_field_type_id: "basic-number-decimal")
        # Use compact operator (*) to stay within max_allowed_chars_in_processed_mathjs_formula
        fields = ("{num_field_#{i}}" for i in [1..max_placeholders]).join("*")
        result = instance.processFormula(fields, "formula_field_1", custom_fields)
        expect(_.keys(result.field_to_symbol)).to.have.length max_placeholders
        return

      it "should throw for formula referencing disabled custom field", ->
        custom_fields = makeCustomFields()
        expect(-> instance.processFormula("{disabled_field_1}", "formula_field_1", custom_fields)).to.throw()
        return

      it "for regular formula: should throw for formula referencing calc-type field", ->
        custom_fields = makeCustomFields()
        expect(-> instance.processFormula("{calc_field_1}", "formula_field_1", custom_fields)).to.throw()
        return

      it "for smart row formula: should accept formula referencing calc-type field", ->
        custom_fields = makeCustomFields()
        result = instance.processFormula(
          "{calc_field_1}", "srf_field_1", custom_fields,
          {formula_type: JustdoFormulaFields.smart_row_formula_field_type_id}
        )
        expect(result).to.have.property "mathjs_formula"
        return

      it "should throw for formula containing free variables (not in field map)", ->
        custom_fields = makeCustomFields()
        # "y" is not a field placeholder, it's a free variable
        expect(-> instance.processFormula("y + {num_field_1}", "formula_field_1", custom_fields)).to.throw()
        return

      it "with compile=true: should return an evaluate function", ->
        custom_fields = makeCustomFields()
        result = instance.processFormula("{num_field_1} + {num_field_2}", "formula_field_1", custom_fields, {compile: true})
        expect(result.evaluate).to.be.a "function"
        return

      it "with compile=true: should evaluate correctly with document values", ->
        custom_fields = makeCustomFields()
        result = instance.processFormula("{num_field_1} + {num_field_2}", "formula_field_1", custom_fields, {compile: true})
        doc = {num_field_1: 10, num_field_2: 5}
        expect(result.evaluate(doc)).to.equal 15
        return

      it "with compile=true: should return null when all fields are missing", ->
        custom_fields = makeCustomFields()
        result = instance.processFormula("{num_field_1} + {num_field_2}", "formula_field_1", custom_fields, {compile: true})
        expect(result.evaluate({})).to.be.null
        return

      it "with compile=true: should treat missing fields as 0 when some fields have values", ->
        custom_fields = makeCustomFields()
        result = instance.processFormula("{num_field_1} + {num_field_2}", "formula_field_1", custom_fields, {compile: true})
        doc = {num_field_1: 7}
        expect(result.evaluate(doc)).to.equal 7
        return

      it "with compile=true: should parse string values as numbers", ->
        custom_fields = makeCustomFields()
        result = instance.processFormula("{num_field_1} + {num_field_2}", "formula_field_1", custom_fields, {compile: true})
        doc = {num_field_1: "10", num_field_2: "5.5"}
        expect(result.evaluate(doc)).to.equal 15.5
        return

      it "with compile=true: should return null for non-numeric string values", ->
        custom_fields = makeCustomFields()
        result = instance.processFormula("{num_field_1}", "formula_field_1", custom_fields, {compile: true})
        doc = {num_field_1: "not-a-number"}
        expect(result.evaluate(doc)).to.be.null
        return
