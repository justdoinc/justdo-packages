_.extend JustdoDerivativesFormulasFields,
  pseudo_field_formatter_id: "derivativesFormulaFormatter"

  # Structure:
  #
  # {
  #   justdo_id: [
  #     {
  #       # field_id is required. It needs to be a unique id, to be consistent with other
  #       # fields, use under_scored_field_id.
  #       field_id: "total_units_to_units_received_delta"
  #       field_label: "Human Readable Field Label"
  #       dependencies_fields: ["title", "state", "custom_field_id"]
  #       formula: () -> return
  #     }
  #   ]
  # }
  # 
  # Example:
  #
  # deriviatives_formulas_fields:
  #   "pSGduYjq2g2rE8XTN": [
  #     {
  #       field_id: "total_units_to_units_received_delta"
  #       field_label: "Units Left"
  #       dependencies_fields: ["Rgu7aW6oB7Rf29AoB", "ELgk7g3Qy94So6Fi4"]
  #       formula: ->
  #         {doc, path} = @getFriendlyArgs()

  #         if not (total_units_res = @getItemCalculatedFieldValue(doc._id, "Rgu7aW6oB7Rf29AoB", path))?
  #           return ""

  #         if not (units_received_res = @getItemCalculatedFieldValue(doc._id, "ELgk7g3Qy94So6Fi4", path))?
  #           return ""

  #         # Get total_units
  #         if (err = total_units_res.err)?
  #           # If error received when calculating the value
  #           return "Error: Error in Total Units"

  #         if (cval = total_units_res.cval)?
  #           # If a valid calculated value returned
  #           total_units = cval
  #         else
  #           # Raw value
  #           total_units = total_units_res

  #         # Get units_received
  #         if (err = units_received_res.err)?
  #           # If error received when calculating the value
  #           return "Error: Error in Total Units"

  #         if (cval = units_received_res.cval)?
  #           # If a valid calculated value returned
  #           units_received = cval
  #         else
  #           # Raw value
  #           units_received = units_received_res

  #         result = total_units - units_received

  #         return """<div style="font-weight: bold; text-decoration: underline; text-align: right;">#{result}</div>"""
  #     }
  #   ]
