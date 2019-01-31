math = JustdoMathjs.math

#
# Rational single restricted expressions are numeric algebric expressions that involves real
# numbers, but not matrices, sets, units, etc.
#
# We restrict the use of operators and functions that might cause intense cpu usage.
#

#
# http://mathjs.org/docs/expressions/syntax.html
#
forbidden_chars = [
  # Note, new lines \n, \r, that we are not supporting are dealt with separately
  ";", # Don't support multiple expressions!
  "\\[", # Don't support matrices
  "\\]",
  "{", # Don't support objects
  "}", # Don't support objects
  ".", # Don't support Property accessor  
  "'", # Don't support transpose
  "!", # Don't support factorial
  "^", # Don't support power operation (might be too costly cpu wise)
  "=", # assignment not supported
  "?", # Don't support conditional expressions
  ":", # Don't support ranges
  "<",
  ">"
]

forbidden_chars_exists_regex = RegExp("[" + forbidden_chars.join("") + "]")

forbidden_words = [
  "not",
  "and",
  "or",
  "xor",
  "to",
  "in",
  # "==", # not supported since = not supported in forbidden_chars
  # "!=", # not supported since = not supported in forbidden_chars
  # "<=", # not supported since = not supported in forbidden_chars
  # ">=" # not supported since = not supported in forbidden_chars
]

forbidden_words_exists_regex = RegExp("(\\b" + forbidden_words.join("\\b|\\b") + "\\b)")

# Object is used for quick access, values are ignored!
# http://mathjs.org/docs/reference/functions.html
supported_functions = {
  abs: null
  add: null
  ceil: null
  fix: null
  floor: null
  mod: null
  round: null
  sign: null
  max: null
  mean: null
  median: null
  min: null
}

parseSingleRestrictedRationalExpression = (expression) ->
  if not _.isString expression
    throw new Meteor.Error "not-a-single-rational-expression", "Expression must be a string"

  if "\n" in expression or "\r" in expression
    throw new Meteor.Error "not-a-single-rational-expression", "New lines aren't allowed"

  if forbidden_chars_exists_regex.test(expression)
    throw new Meteor.Error "not-a-single-rational-expression", "The following aren't allowed: " + forbidden_chars.join(", ")

  if forbidden_words_exists_regex.test(expression)
    throw new Meteor.Error "not-a-single-rational-expression", "The following aren't allowed: " + forbidden_words.join(", ")

  try
    node = math.parse(expression)
  catch e
    throw new Meteor.Error "not-a-single-rational-expression", "Parsing failed", e

  node.traverse (node, path, parent) ->
    if node.type == "FunctionNode"
      if node.fn.name not of supported_functions
        throw new Meteor.Error "not-a-single-rational-expression", "The function '#{node.fn.name}' isn't supported. Only the following functions are supported: #{_.keys(supported_functions).join(", ")}."

  return node

JustdoMathjs.parseSingleRestrictedRationalExpression = parseSingleRestrictedRationalExpression
JustdoMathjs.parseSingleRestrictedRationalExpression_supported_functions = _.keys supported_functions # note, changes by others won't affect us!

