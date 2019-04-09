_.extend JustdoChecklist.prototype,
  getOnGridCheckMarkHtml: (task, path) ->
    ancenstor_is_checklist = false

    for ancestor_id in path.split("/")
      if ancestor_id of @_all_checklists
        ancenstor_is_checklist = true

        break

    if not ancenstor_is_checklist
      return ""

    # if checked
    if task["p:checklist:is_checked"]
      return """<i class="fa fa-fw fa-check jdch-check jdch-checked slick-prevent-edit" aria-hidden="true" title="Click to uncheck"></i>"""

    # if implied as checked
    if task["p:checklist:total_count"] and (task["p:checklist:total_count"] == task["p:checklist:checked_count"])
      return """<i class="fa fa-fw fa-check-square jdch-check jdch-implied-checked slick-prevent-edit" aria-hidden="true" title="Implied as checked"></i>"""

    # if implied as partially checked
    if (task["p:checklist:checked_count"] and task["p:checklist:checked_count"] > 0) or task["p:checklist:has_partial"] == true
      return """<i class="fa fa-fw fa-check-square jdch-check jdch-partially-checked slick-prevent-edit" aria-hidden="true" title="Implied as partially checked"></i>"""

    # else empty square
    return """<i class="fa fa-fw fa-square-o jdch-check slick-prevent-edit" aria-hidden="true" title="Click to check"></i>"""
