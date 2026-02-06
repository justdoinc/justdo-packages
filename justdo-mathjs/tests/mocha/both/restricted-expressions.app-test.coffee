# Tests for JustdoMathjs.parseSingleRestrictedRationalExpression
# Covers: expression parsing, supported functions, security restrictions,
# decimal/fraction support, and property accessor prevention.

if Package["justdoinc:justdo-mathjs"]?
  {expect} = require "chai"

  parse = JustdoMathjs.parseSingleRestrictedRationalExpression

  expectToThrow = (expression, error_id="not-a-single-rational-expression") ->
    try
      parse(expression)
      throw new Error "Expected expression to throw: #{expression}"
    catch e
      expect(e.error).to.equal error_id
    return

  describe "JustdoMathjs - parseSingleRestrictedRationalExpression", ->

    describe "Valid expressions", ->

      it "should parse simple addition", ->
        node = parse("1 + 2")
        expect(node).to.exist
        return

      it "should parse compound arithmetic", ->
        node = parse("3 * 4 - 1 + 10 / 2")
        expect(node).to.exist
        return

      it "should parse expressions with variables", ->
        node = parse("a + b")
        expect(node).to.exist
        return

      it "should parse parenthesized expressions", ->
        node = parse("(a + b) * c")
        expect(node).to.exist
        return

      it "should parse decimal numbers", ->
        node = parse("0.01")
        expect(node).to.exist
        return

      it "should parse leading-dot decimals", ->
        node = parse(".5")
        expect(node).to.exist
        return

      it "should parse multi-digit decimals", ->
        node = parse("3.14159")
        expect(node).to.exist
        return

      it "should parse decimal arithmetic", ->
        node = parse("0.01 * 100 + 2.5")
        expect(node).to.exist
        return

      it "should parse negative numbers", ->
        node = parse("-5")
        expect(node).to.exist
        return

      it "should parse negative decimals", ->
        node = parse("-3.14")
        expect(node).to.exist
        return

      it "should parse trailing-dot decimals (e.g. 0. and 1.)", ->
        node = parse("0.")
        expect(node).to.exist
        node2 = parse("1.")
        expect(node2).to.exist
        return

      it "should parse scientific notation (e.g. 1e10)", ->
        node = parse("1e10")
        expect(node).to.exist
        result = node.compile().evaluate()
        expect(result).to.equal 1e10
        return

      it "should return a node that can be compiled and evaluated", ->
        node = parse("1 + 2")
        compiled = node.compile()
        result = compiled.evaluate()
        expect(result).to.equal 3
        return

    describe "Supported functions", ->

      it "should accept sqrt()", ->
        node = parse("sqrt(4)")
        expect(node).to.exist
        return

      it "should accept abs()", ->
        node = parse("abs(-1)")
        expect(node).to.exist
        return

      it "should accept ceil()", ->
        node = parse("ceil(1.3)")
        expect(node).to.exist
        return

      it "should accept floor()", ->
        node = parse("floor(1.9)")
        expect(node).to.exist
        return

      it "should accept round()", ->
        node = parse("round(1.5)")
        expect(node).to.exist
        return

      it "should accept fix()", ->
        node = parse("fix(1.7)")
        expect(node).to.exist
        return

      it "should accept mod()", ->
        node = parse("mod(5, 3)")
        expect(node).to.exist
        return

      it "should accept sign()", ->
        node = parse("sign(-5)")
        expect(node).to.exist
        return

      it "should accept max()", ->
        node = parse("max(1, 2, 3)")
        expect(node).to.exist
        return

      it "should accept min()", ->
        node = parse("min(1, 2, 3)")
        expect(node).to.exist
        return

      it "should accept mean()", ->
        node = parse("mean(1, 2, 3)")
        expect(node).to.exist
        return

      it "should accept median()", ->
        node = parse("median(1, 2, 3)")
        expect(node).to.exist
        return

      it "should accept nested function calls", ->
        node = parse("abs(round(a))")
        expect(node).to.exist
        return

      it "should accept functions combined with arithmetic", ->
        node = parse("sqrt(a) + abs(b) * 2")
        expect(node).to.exist
        return

    describe "Security - forbidden characters", ->

      it "should reject semicolons (multiple expressions)", ->
        expectToThrow("1 + 2; 3 + 4")
        return

      it "should reject matrix open bracket", ->
        expectToThrow("[1, 2]")
        return

      it "should reject matrix close bracket", ->
        expectToThrow("1]")
        return

      it "should reject object open brace", ->
        expectToThrow("{a: 1}")
        return

      it "should reject object close brace", ->
        expectToThrow("1}")
        return

      it "should reject transpose operator", ->
        expectToThrow("a'")
        return

      it "should reject factorial operator", ->
        expectToThrow("5!")
        return

      it "should reject power operator", ->
        expectToThrow("2^3")
        return

      it "should reject assignment", ->
        expectToThrow("a = 1")
        return

      it "should reject conditional operator", ->
        expectToThrow("a ? 1")
        return

      it "should reject range operator", ->
        expectToThrow("1:10")
        return

      it "should reject less-than", ->
        expectToThrow("a < b")
        return

      it "should reject greater-than", ->
        expectToThrow("a > b")
        return

      it "should reject newline \\n", ->
        expectToThrow("1 + 2\n3 + 4")
        return

      it "should reject carriage return \\r", ->
        expectToThrow("1 + 2\r3 + 4")
        return

    describe "Security - property accessor prevention", ->

      it "should reject identifier.identifier (e.g. abs.constructor)", ->
        expectToThrow("abs.constructor")
        return

      it "should reject paren.identifier (e.g. (1).constructor)", ->
        expectToThrow("(1).constructor")
        return

      it "should reject chained accessors", ->
        expectToThrow("a.b.c")
        return

      it "should reject variable.property", ->
        expectToThrow("x.toString")
        return

      it "should reject __proto__ access", ->
        expectToThrow("a.__proto__")
        return

      it "should safely handle digit-dot-identifier (e.g. 0.abc)", ->
        # The regex does not catch digit-dot-identifier (digit before dot),
        # but mathjs parses "0.abc" as implicit multiplication: 0 * abc,
        # NOT as property access. Verify it does not produce an AccessorNode.
        node = parse("0.abc")
        expect(node).to.exist
        # Evaluating with abc=5 should give 0 * 5 = 0 (implicit multiplication)
        result = node.compile().evaluate({abc: 5})
        expect(result).to.equal 0
        return

      it "should reject double-dot patterns", ->
        expectToThrow("..5")
        return

      it "should NOT reject decimal number 0.01", ->
        node = parse("0.01")
        expect(node).to.exist
        return

      it "should NOT reject leading-dot decimal .5", ->
        node = parse(".5")
        expect(node).to.exist
        return

      it "should NOT reject decimal in arithmetic 0.01 * a", ->
        node = parse("0.01 * a")
        expect(node).to.exist
        return

      it "should NOT reject multiple decimals in one expression", ->
        node = parse("0.5 + 1.25 - 0.01")
        expect(node).to.exist
        return

    describe "Security - forbidden words", ->

      it "should reject 'not'", ->
        expectToThrow("not a")
        return

      it "should reject 'and'", ->
        expectToThrow("a and b")
        return

      it "should reject 'or'", ->
        expectToThrow("a or b")
        return

      it "should reject 'xor'", ->
        expectToThrow("a xor b")
        return

      it "should reject 'to'", ->
        expectToThrow("a to b")
        return

      it "should reject 'in'", ->
        expectToThrow("a in b")
        return

    describe "Security - unsupported functions", ->

      it "should reject unsupported function names", ->
        expectToThrow("sin(1)")
        return

      it "should reject cos()", ->
        expectToThrow("cos(1)")
        return

      it "should reject exp()", ->
        expectToThrow("exp(1)")
        return

    describe "Input validation", ->

      it "should reject non-string input (number)", ->
        expectToThrow(123)
        return

      it "should reject non-string input (null)", ->
        expectToThrow(null)
        return

      it "should reject non-string input (undefined)", ->
        expectToThrow(undefined)
        return

      it "should reject non-string input (object)", ->
        expectToThrow({})
        return

    describe "End-to-end evaluation", ->

      it "should evaluate sqrt(4) to 2", ->
        node = parse("sqrt(4)")
        result = node.compile().evaluate()
        expect(result).to.equal 2
        return

      it "should evaluate abs(-7) to 7", ->
        node = parse("abs(-7)")
        result = node.compile().evaluate()
        expect(result).to.equal 7
        return

      it "should evaluate decimal arithmetic correctly", ->
        node = parse("0.1 + 0.2")
        result = node.compile().evaluate()
        # Floating point: use closeTo
        expect(result).to.be.closeTo(0.3, 0.0001)
        return

      it "should evaluate with variable substitution", ->
        node = parse("a + b * 2")
        result = node.compile().evaluate({a: 3, b: 5})
        expect(result).to.equal 13
        return

      it "should evaluate nested functions", ->
        node = parse("abs(min(-3, -1))")
        result = node.compile().evaluate()
        expect(result).to.equal 3
        return

      it "should evaluate complex expression with decimals and functions", ->
        node = parse("round(sqrt(a) + 0.5)")
        result = node.compile().evaluate({a: 9})
        expect(result).to.equal 4
        return
