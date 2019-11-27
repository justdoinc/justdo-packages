Projects.registerAllowedConfs
  custom_features:
    # Holds an array of custom features ids
    #
    # This field is in use by the client side methods of the current project obj:
    # current_project.enableCustomFeatures(features), current_project.disableCustomFeatures(features), current_project.isCustomFeatureEnabled(feature)
    require_admin_permission: true
    value_matcher: [String]
    allow_change: true
    allow_unset: true

  project_uid:
    require_admin_permission: true
    value_matcher: /^[0-9a-z-]+$/
    validator: (value) ->
      if (@projects_collection.findOne({"conf.project_uid": value}))?
        throw @_error "validation-error", "project_uid `#{value}` already taken by another project"

      return true
    allow_change: false
    allow_unset: false
