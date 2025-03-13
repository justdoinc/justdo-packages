Template.registerHelper "isFilterChecked", (type) ->
    parent_tpl = Template.instance().data.parent_tpl
    return parent_tpl.isFilterChecked type

Template.site_admin_ai_requests_filter_dropdown.onCreated ->
  @parent_tpl = @data.parent_tpl

  JD.registerPlaceholderItem "site-admin-ai-request-filter-dropdown-toggle-anon_only",
    position: 10
    domain: "site-admins-ai-request-filter-dropdown"
    data:
      template: "site_admin_ai_requests_filter_dropdown_toggle_anon_only"

  JD.registerPlaceholderItem "site-admin-ai-request-filter-dropdown-toggle-accepted",
    position: 20
    domain: "site-admins-ai-request-filter-dropdown"
    data:
      template: "site_admin_ai_requests_filter_dropdown_toggle_accepted"

  JD.registerPlaceholderItem "site-admin-ai-request-filter-dropdown-toggle-partial-accepted",
    position: 30
    domain: "site-admins-ai-request-filter-dropdown"
    data:
      template: "site_admin_ai_requests_filter_dropdown_toggle_partial_accepted"

  JD.registerPlaceholderItem "site-admin-ai-request-filter-dropdown-toggle-declined",
    position: 40
    domain: "site-admins-ai-request-filter-dropdown"
    data:
      template: "site_admin_ai_requests_filter_dropdown_toggle_declined"

  JD.registerPlaceholderItem "site-admin-ai-request-filter-dropdown-toggle-aborted",
    position: 50
    domain: "site-admins-ai-request-filter-dropdown"
    data:
      template: "site_admin_ai_requests_filter_dropdown_toggle_aborted"

  JD.registerPlaceholderItem "site-admin-ai-request-filter-dropdown-toggle-has-error",
    position: 60
    domain: "site-admins-ai-request-filter-dropdown"
    data:
      template: "site_admin_ai_requests_filter_dropdown_toggle_has_error"

  return

Template.site_admin_ai_requests_filter_dropdown.helpers
  dropdownItems: -> JD.getPlaceholderItems "site-admins-ai-request-filter-dropdown"

  templateData: -> Template.instance().data

Template.site_admin_ai_requests_filter_dropdown.events
  "click .dropdown-item": (e, tpl) ->
    type = $(e.target).closest(".dropdown-item").data("type")
    parent_tpl = tpl.parent_tpl

    parent_tpl.toggleFilterCheckbox type
    return
