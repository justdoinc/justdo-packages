_.extend JustdoFormulaFields,
  project_custom_feature_id: "justdo_formula_fields" # Use underscores
  plugin_human_readable_name: "JustDo Formulas"
  custom_field_type_id: "formula-field"

  # The following is relevant to all fields (including client side pseudo fields,
  # and builtin), not only custom fields
  supported_fields_types: [Number]

  # The following 2 are extra checks specific to custom fields
  supported_custom_fields_types: ["number"]
  supported_custom_fields_types_ids: ["basic-number-decimal"]
  # Note 1: at the past we didn't have custom_field_type_id set to custom fields, only field_type, so we can't rely solely on custom_field_type_id
  # Note 2: at the moment one formula can't rely on another formula, more derived development
  #         is necessary to support all the cases involved to add that feature.

  max_allowed_chars_in_processed_mathjs_formula: 50

  max_allowed_fields_placeholders: 5

# Note, we don't support subdocuments, so . isn't part of the allowed symbols
# IMPORTANT!!! DO NOT INCLUDE {} in the pattern!
JustdoFormulaFields.allowed_field_names_chars_pattern = "[a-zA-Z0-9:\\-_]"

JustdoFormulaFields.field_component_pattern = "\{(#{JustdoFormulaFields.allowed_field_names_chars_pattern}+)\}"

JustdoFormulaFields.allowed_field_names_chars_pattern_regex =
  new RegExp("^" + JustdoFormulaFields.allowed_field_names_chars_pattern + "+$")

JustdoFormulaFields.formula_fields_components_matcher_regex =
  new RegExp(JustdoFormulaFields.field_component_pattern, "g")

JustdoFormulaFields.forbidden_fields_suffixes = ["priv:"]
JustdoFormulaFields.forbidden_fields_suffixes_regex = new RegExp("^(#{JustdoFormulaFields.forbidden_fields_suffixes.join("|")})")

JustdoFormulaFields.formula_human_readable_fields_components_matcher_regex =
  new RegExp("\{([^{}]+)\}", "g")

# The following fields *can't* in any case be included in a formula
# (we use object for quick access, values are completely ignored!)
JustdoFormulaFields.forbidden_fields = 
  "_id": null
  "_raw_updated_date": null
  "_raw_added_users_dates": null
  "_raw_removed_users_dates": null
  "_raw_removed_users": null
  "_raw_removed_date": null