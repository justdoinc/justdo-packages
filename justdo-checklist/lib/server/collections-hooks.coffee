_.extend JustdoChecklist.prototype,
  _setupCollectionsHooks: ->
    self = @

    ifPluginEnabledForProject = (project_id, ifEnabled) =>
      query = 
        _id: project_id
        "conf.custom_features": JustdoChecklist.project_custom_feature_id

      # rawCollection() is used in the following calls to go with async calls to recalcImpliedChecklistFields()
      # to prevent any slowdown in the requests handling.
      APP.justdo_analytics.logMongoRawConnectionOp @tasks_collection._name, "findOne", query

      self.projects_collection.rawCollection().findOne query, Meteor.bindEnvironment (err, result) =>
        if err?
          console.error(err)

          return

        if result?
          JustdoHelpers.callCb ifEnabled

        return

      return

    self.tasks_collection.after.insert (user_id, doc) =>
      ifPluginEnabledForProject doc.project_id, ->
        self.recalcImpliedChecklistFields doc._id, doc

        return

      return

    self.tasks_collection.after.update (user_id, doc, field_names, modifier, options) =>
      ifPluginEnabledForProject doc.project_id, ->
        self.recalcImpliedChecklistFields doc._id, doc

        return

      return

    self.tasks_collection.after.pseudo_remove (user_id, doc) =>
      ifPluginEnabledForProject doc.project_id, ->
        self.recalcImpliedChecklistFields doc._id, doc

        return

      return
