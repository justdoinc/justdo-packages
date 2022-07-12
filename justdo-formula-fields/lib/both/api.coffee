symbols_indexex = "abcdefghijklmnopqrstuvwxyz"

_.extend JustdoFormulaFields.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  isPluginInstalledOnProjectDoc: (project_doc) ->
    # XXX need to use APP.projects.isPluginInstalledOnProjectDoc() instead.
    if _.isArray(custom_features = project_doc?.conf?.custom_features)
      return JustdoFormulaFields.project_custom_feature_id in project_doc?.conf?.custom_features

    return false

  getCustomFieldsFromProjectDoc: (project_doc) ->
    if not (custom_fields = project_doc.custom_fields)?
      return null

    return custom_fields

  removeRedundantSpacesFormula: (formula) ->
    return formula.replace(/\s+/g, " ")

  processFormula: (formula, formula_field_id, project_custom_fields, options) ->
    # Gets the non-human readable version of the formula.
    #
    # Creates a new formula where the the {fields} placeholders are replaced 
    # with symbols.
    #
    # Throws a Meteor.Error if:
    # 
    #   * Formula field is disabled
    #   * Formula field is not a formula field
    #   * Failed to parse the formula.
    #   * Formula doesn't copmly with the restrictions of JustdoMathjs.parseSingleRestrictedRationalExpression()
    #   * Formula includes symbols that aren't fields placeholder: e.g. 'y + {x}' is not supported.
    #   * Formula doesn't have at least a single field place holder (we don't allow constant formulas
    #   to prevent setting the same value for the entire documents in a project, which we consider
    #   redundant and wasteful resources wise).
    #   * Formula involve private fields.
    #   * The formula with the placeholders replaced to symbols, is longer than
    #   JustdoFormulaFields.max_allowed_chars_in_processed_mathjs_formula .
    #   * The formula has a placeholder to its own field (recursive formula).
    #   * Formula has more than JustdoFormulaFields.max_allowed_fields_placeholders fields placeholders.
    #   * Formula refers to other disabled custom fields
    #   * Formula refers to custom fields we don't support as part of formulas
    #
    # Returns an object of the form:
    #
    # {
    #   mathjs_formula: , # The new formula with the fields replaced with symbols
    #   parsed_formula: , # The parsed new formula
    #   field_to_symbol: # an object of the form {field_name: symbol}
    # }
    #
    # Options:
    #
    # compile default=false
    #
    # If options.compile is set to true, we also add the following:
    #
    # {
    #   eval(document, options):
    #     # gets as a parameter a document and returns the evaluated mathjs formula
    #     # for its fields.
    #     #
    #     # Will return null if can't calculate args due to lack of args, or other reason.
    #     #
    #     # options:
    #     #   skip_if_fields_are_missing default=true
    #     #   
    #     #   When it is set to true, we skip calculation and return null
    #     #   if any field listed in the field_to_symbol is missing in the
    #     #   document.
    #     #
    #     #   IMPORTANT: FOR NOW WE SUPPORT ONLY skip_if_fields_are_missing=true !
    # }

    if _.isEmpty project_custom_fields or not _.isArray(project_custom_fields)
      throw new Meteor.Error "invalid-argument", "processFormula: project_custom_fields argument can't be empty"

    field_to_symbol = {}

    field_custom_field_def = _.find(project_custom_fields, (custom_field_def) -> custom_field_def.field_id == formula_field_id)

    if not field_custom_field_def?
      throw new Meteor.Error "unknown-field-id", "Unknown field id (#{field_custom_field_def}) provided to processFormula()"

    # Ensure formula_field_id isn't disabled
    if field_custom_field_def.disabled
      throw new Meteor.Error "disabled-field", "Formula field (#{formula_field_id}) is disabled and can't be processed."

    # Ensure formula_field_id is a Formula field
    if field_custom_field_def.custom_field_type_id != JustdoFormulaFields.custom_field_type_id
      throw new Meteor.Error "not-a-formula-field", "Formula field type id must be: '#{JustdoFormulaFields.custom_field_type_id}'. (received a field of type: '#{field_custom_field_def.custom_field_type_id}')."

    placeholders_found = 0
    mathjs_formula = formula.replace JustdoFormulaFields.formula_fields_components_matcher_regex, (all_match, field_name) =>
      if field_name of field_to_symbol
        return field_to_symbol[field_name]

      field_to_symbol[field_name] = symbols_indexex[placeholders_found]

      placeholders_found += 1

      if JustdoFormulaFields.forbidden_fields_suffixes_regex.test(field_name)
        throw new Meteor.Error "invalid-formula", "Formula can't refer to private fields."

      if field_name == formula_field_id
        throw new Meteor.Error "invalid-formula", "Formula can't refer to the field it is set on (#{field_name})."

      if field_name of JustdoFormulaFields.forbidden_fields
        throw new Meteor.Error "invalid-formula", "Formula refers to a forbidden field."

      if (field_name_custom_field_def = _.find(project_custom_fields, (custom_field_def) -> custom_field_def.field_id == field_name))?
        # Field is not necessarily a custom field, but, if it is a custom field
        # we have some extra checks to do.

        @throwErrorIfNotAllowedCustomFieldDef(field_name_custom_field_def)

      return field_to_symbol[field_name]

    if placeholders_found == 0
      throw new Meteor.Error "invalid-formula", "Formula must involve at least one field."

    if placeholders_found > JustdoFormulaFields.max_allowed_fields_placeholders
      throw new Meteor.Error "invalid-formula", "Formula can't have more than #{JustdoFormulaFields.max_allowed_fields_placeholders} placeholders."

    mathjs_formula = @removeRedundantSpacesFormula(mathjs_formula)

    if mathjs_formula.length > JustdoFormulaFields.max_allowed_chars_in_processed_mathjs_formula
      throw new Meteor.Error "invalid-formula", "Formula can't be longer than #{JustdoFormulaFields.max_allowed_chars_in_processed_mathjs_formula} characters (placeholders are counted as one character)."

    # Might throw Meteor.Error , we don't catch, the user of this method
    # should be prepared for these exceptions.
    parsed_formula = JustdoMathjs.parseSingleRestrictedRationalExpression(mathjs_formula)

    ret = {
      mathjs_formula: mathjs_formula
      parsed_formula: parsed_formula
      field_to_symbol: _.extend {}, field_to_symbol # we don't want changes from the user to affect us, so we create a shallow copy
    }

    allowed_symbols = _.values(field_to_symbol)
    parsed_formula.traverse (node, path, parent) ->
      if node.type == "SymbolNode" and node.name not in allowed_symbols
        # Use the name variable instead of symbol, assuming it is more understandable by humans.
        throw new Meteor.Error "invalid-formula", "Formulas can't have variables (found variable: #{node.name})."

    if options?.compile is true
      code = parsed_formula.compile()

      ret.eval = (doc, options) ->
        if options?.skip_if_fields_are_missing is false
          throw new Meteor.Error "option-not-supported", "At the moment we aren't supporting the false state of the option: skip_if_fields_are_missing"
        
        mathjs_eval_args = {}
        eval_needed = false
        for field, symbol of field_to_symbol
          if not (val = doc[field])?
            mathjs_eval_args[symbol] = 0
            continue

          if not _.isNumber(val)
            if _.isString(val)
              if _.isEmpty(val)
                  mathjs_eval_args[symbol] = 0
                  continue

              val = parseFloat(val)

              if _.isNaN(val)
                return null
            else
              return null # we don't support other cases

          eval_needed = true
          mathjs_eval_args[symbol] = val

        if eval_needed
          return code.eval(mathjs_eval_args)
        else
          return null

    return ret

  throwErrorIfNotAllowedCustomFieldDef: (custom_field_def) ->
    if custom_field_def.disabled is true
      throw new Meteor.Error "invalid-formula", "Field #{custom_field_def.field_id} is disabled and can't be used in a formula."

    if custom_field_def.field_type not in JustdoFormulaFields.supported_custom_fields_types
      throw new Meteor.Error "invalid-formula", "Custom fields of type: #{custom_field_def.field_type}, are not supported in formulas."

    if (custom_field_type_id = custom_field_def.custom_field_type_id)?
      # Note, at the past we didn't have custom_field_type_id set to custom fields, only field_type,
      # so, for backward compatibility, we can't rely on custom_field_type_id to exist.

      if custom_field_type_id not in JustdoFormulaFields.supported_custom_fields_types_ids
        throw new Meteor.Error "invalid-formula", "Custom fields of type: #{JustdoFormulaFields.custom_field_type_id}, are not supported in formulas."

    return