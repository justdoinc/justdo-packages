_.extend Projects.prototype,
  _setupAllowDenyRules: ->
    self = this

    @projects_collection.allow
      update: (user_id, doc) -> self.isAdminOfProjectDoc(doc, user_id) # defined in helpers

      remove: (userId) -> self.isAdminOfProjectDoc(doc, user_id)

    @_grid_data_com.initDefaultGridAllowDenyRules()