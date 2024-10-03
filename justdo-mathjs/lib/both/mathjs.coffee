import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"

checkNpmVersions({
  "mathjs": "13.x.x"
}, "justdoinc:justdo-formula-fields")

{create, all} = require "mathjs"
math = create all

# Securing math, see: http://mathjs.org/docs/expressions/security.html

math.import
  import: -> throw new Error("Function import is disabled")
  createUnit: -> throw new Error("Function createUnit is disabled")
  # eval: -> throw new Error("Function eval is disabled")
  # parse: -> throw new Error("Function parse is disabled")
  # simplify: -> throw new Error("Function simplify is disabled")
  # derivative: -> throw new Error("Function derivative is disabled")
, {override: true}

JustdoMathjs = {
  math
}