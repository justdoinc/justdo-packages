# Tests for JustdoFormulaFields static utilities:
# - escapeFieldLabelForFormula / unescapeFieldLabelFromFormula
# - Regex patterns
# - isSmartRowFormulaField
# - Static constants

if Package["justdoinc:justdo-formula-fields"]?
  {expect} = require "chai"

  describe "JustdoFormulaFields - Static Utilities", ->

    describe "escapeFieldLabelForFormula", ->
      escape = JustdoFormulaFields.escapeFieldLabelForFormula

      it "should pass through label with no special characters", ->
        expect(escape("simple_field")).to.equal "simple_field"
        return

      it "should pass through label with math operators (not special)", ->
        expect(escape("a + b * 2")).to.equal "a + b * 2"
        return

      it "should escape backslash", ->
        expect(escape("a\\b")).to.equal "a\\\\b"
        return

      it "should escape opening brace", ->
        expect(escape("a{b")).to.equal "a\\{b"
        return

      it "should escape closing brace", ->
        expect(escape("a}b")).to.equal "a\\}b"
        return

      it "should escape all special characters together", ->
        expect(escape("{a\\b}")).to.equal "\\{a\\\\b\\}"
        return

      it "should handle empty string", ->
        expect(escape("")).to.equal ""
        return

      it "should escape backslash before braces to avoid double-escape", ->
        # If we have \{ in the input, backslash is escaped first to \\,
        # then { is escaped to \{, yielding \\\{
        expect(escape("\\{")).to.equal "\\\\\\{"
        return

      it "should handle multiple consecutive special characters", ->
        expect(escape("{}\\")).to.equal "\\{\\}\\\\"
        return

    describe "unescapeFieldLabelFromFormula", ->
      unescape = JustdoFormulaFields.unescapeFieldLabelFromFormula

      it "should pass through label with no escaped characters", ->
        expect(unescape("simple_field")).to.equal "simple_field"
        return

      it "should unescape backslash", ->
        expect(unescape("a\\\\b")).to.equal "a\\b"
        return

      it "should unescape opening brace", ->
        expect(unescape("a\\{b")).to.equal "a{b"
        return

      it "should unescape closing brace", ->
        expect(unescape("a\\}b")).to.equal "a}b"
        return

      it "should unescape all special characters together", ->
        expect(unescape("\\{a\\\\b\\}")).to.equal "{a\\b}"
        return

      it "should handle empty string", ->
        expect(unescape("")).to.equal ""
        return

    describe "escape/unescape round-trip", ->
      escape = JustdoFormulaFields.escapeFieldLabelForFormula
      unescape = JustdoFormulaFields.unescapeFieldLabelFromFormula

      roundTrip = (label) ->
        expect(unescape(escape(label))).to.equal label

      it "should round-trip plain label", ->
        roundTrip("simple_field")
        return

      it "should round-trip label with backslash", ->
        roundTrip("a\\b")
        return

      it "should round-trip label with braces", ->
        roundTrip("{hello}")
        return

      it "should round-trip label with all special chars", ->
        roundTrip("{a\\b}")
        return

      it "should round-trip label with math operators", ->
        roundTrip("price + tax * 1.5")
        return

      it "should round-trip label with mixed special and normal text", ->
        roundTrip("field_{v1}\\data")
        return

      it "should round-trip empty string", ->
        roundTrip("")
        return

    describe "formula_fields_components_matcher_regex", ->
      regex = JustdoFormulaFields.formula_fields_components_matcher_regex

      beforeEach ->
        # Reset regex lastIndex since it has the global flag
        regex.lastIndex = 0
        return

      it "should match a single field placeholder", ->
        matches = []
        "{field_a}".replace regex, (match, field_id) ->
          matches.push field_id
          return match
        expect(matches).to.deep.equal ["field_a"]
        return

      it "should match multiple field placeholders", ->
        matches = []
        "{field_a} + {field_b} * {field_c}".replace regex, (match, field_id) ->
          matches.push field_id
          return match
        expect(matches).to.deep.equal ["field_a", "field_b", "field_c"]
        return

      it "should capture field_id without braces", ->
        matches = []
        "{my-custom-field}".replace regex, (match, field_id) ->
          matches.push field_id
          return match
        expect(matches).to.deep.equal ["my-custom-field"]
        return

      it "should match fields with colons and hyphens in name", ->
        matches = []
        "{cf:my-field_1}".replace regex, (match, field_id) ->
          matches.push field_id
          return match
        expect(matches).to.deep.equal ["cf:my-field_1"]
        return

      it "should not match empty braces", ->
        matches = []
        "{}".replace regex, (match, field_id) ->
          matches.push field_id
          return match
        expect(matches).to.be.empty
        return

      it "should not match content outside braces", ->
        matches = []
        "plain_text + 42".replace regex, (match, field_id) ->
          matches.push field_id
          return match
        expect(matches).to.be.empty
        return

    describe "formula_human_readable_fields_components_matcher_regex", ->
      regex = JustdoFormulaFields.formula_human_readable_fields_components_matcher_regex

      beforeEach ->
        regex.lastIndex = 0
        return

      it "should match simple label", ->
        matches = []
        "{Simple Label}".replace regex, (match, content) ->
          matches.push content
          return match
        expect(matches).to.deep.equal ["Simple Label"]
        return

      it "should match label with escaped braces", ->
        matches = []
        "{field\\{1\\}}".replace regex, (match, content) ->
          matches.push content
          return match
        expect(matches).to.have.length 1
        expect(JustdoFormulaFields.unescapeFieldLabelFromFormula(matches[0])).to.equal "field{1}"
        return

      it "should match label with escaped backslash", ->
        matches = []
        "{field\\\\name}".replace regex, (match, content) ->
          matches.push content
          return match
        expect(matches).to.have.length 1
        expect(JustdoFormulaFields.unescapeFieldLabelFromFormula(matches[0])).to.equal "field\\name"
        return

      it "should not match empty braces", ->
        matches = []
        "{}".replace regex, (match, content) ->
          matches.push content
          return match
        expect(matches).to.be.empty
        return

      it "should match multiple labels in one formula", ->
        matches = []
        "{Hours} * {Rate}".replace regex, (match, content) ->
          matches.push content
          return match
        expect(matches).to.deep.equal ["Hours", "Rate"]
        return

    describe "isSmartRowFormulaField", ->
      # isSmartRowFormulaField is on the prototype, but it's a pure comparison.
      # We access it via APP.justdo_formula_fields when available, or call it
      # directly on the prototype with any context since it doesn't use `this`.
      isSmartRow = JustdoFormulaFields.prototype.isSmartRowFormulaField

      it "should return true for smart_row_formula_field_type_id", ->
        expect(isSmartRow(JustdoFormulaFields.smart_row_formula_field_type_id)).to.be.true
        return

      it "should return false for custom_field_type_id (regular formula)", ->
        expect(isSmartRow(JustdoFormulaFields.custom_field_type_id)).to.be.false
        return

      it "should return false for null", ->
        expect(isSmartRow(null)).to.be.false
        return

      it "should return false for undefined", ->
        expect(isSmartRow(undefined)).to.be.false
        return

      it "should return false for arbitrary string", ->
        expect(isSmartRow("some-other-type")).to.be.false
        return

    describe "Static constants", ->

      it "should have symbols_indexes as a string of lowercase letters", ->
        expect(JustdoFormulaFields.symbols_indexes).to.be.a "string"
        expect(JustdoFormulaFields.symbols_indexes).to.match /^[a-z]+$/
        return

      it "should have smart_row_formula_field_type_id defined", ->
        expect(JustdoFormulaFields.smart_row_formula_field_type_id).to.be.a "string"
        expect(JustdoFormulaFields.smart_row_formula_field_type_id).to.not.be.empty
        return

      it "should have custom_field_type_id defined", ->
        expect(JustdoFormulaFields.custom_field_type_id).to.be.a "string"
        expect(JustdoFormulaFields.custom_field_type_id).to.not.be.empty
        return

      it "should have distinct type IDs for regular and smart row formula", ->
        expect(JustdoFormulaFields.custom_field_type_id).to.not.equal JustdoFormulaFields.smart_row_formula_field_type_id
        return

      it "should include smart_row_formula_field_type_id in supported_custom_fields_types_ids_for_smart_row_formula", ->
        expect(JustdoFormulaFields.supported_custom_fields_types_ids_for_smart_row_formula).to.include JustdoFormulaFields.smart_row_formula_field_type_id
        return

      it "should include calculatedFieldFormatter in supported_formatters_for_smart_row_formula", ->
        expect(JustdoFormulaFields.supported_formatters_for_smart_row_formula).to.include "calculatedFieldFormatter"
        return

      it "should include smartRowFormulaFormatter in supported_formatters_for_smart_row_formula", ->
        expect(JustdoFormulaFields.supported_formatters_for_smart_row_formula).to.include "smartRowFormulaFormatter"
        return

      it "should have max_allowed_fields_placeholders as a positive number", ->
        expect(JustdoFormulaFields.max_allowed_fields_placeholders).to.be.a "number"
        expect(JustdoFormulaFields.max_allowed_fields_placeholders).to.be.above 0
        return

      it "should have max_allowed_chars_in_processed_mathjs_formula as a positive number", ->
        expect(JustdoFormulaFields.max_allowed_chars_in_processed_mathjs_formula).to.be.a "number"
        expect(JustdoFormulaFields.max_allowed_chars_in_processed_mathjs_formula).to.be.above 0
        return
