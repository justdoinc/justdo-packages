import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"

checkNpmVersions({
  "mathjs": "13.x.x"
}, "justdoinc:justdo-formula-fields")

mathjs = require "mathjs"

required_function_names = _.keys(share.supported_functions)
# These functions are used internally by us, so we need to include them without adding them to the share.supported_functions
additional_function_names = ["format", "parse", "subtract"]
required_function_names = required_function_names.concat additional_function_names

required_dependencies = _.map required_function_names, (function_name) -> "#{function_name}Dependencies"

math = mathjs.create _.pick mathjs, required_dependencies

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