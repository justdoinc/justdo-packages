_.extend PACK.modules.due_lists,
  initServer: ->
    # @_setupPublication()

    @_setupIndices()

  # _getRestrictedPublicationOptionsConfiguration: (conf, pub_obj) ->
  #   # Here we look into the received conf for the below publications
  #   # and look for confs that affects the publication's restricted
  #   # options.
  #   #
  #   # Returns the restricted_options object to be called to customizedCursorPublish
  #   # with (or undefined if no restricted_options are necessary)

  #   self = @

  #   user_id = pub_obj.userId

  #   if conf.get_has_children == true
  #     return {
  #       data_maps:
  #         dependent_field: "_id"
  #         map: (id, data) ->
  #           return {_has_children: self.items_collection.getHasChildren(id, {}, {user_id: user_id})}
  #     }

  #   return undefined

  # _setupPublication: ->
  #   self = @

  #   Meteor.publish "getProjectsDueList", (conf, pub_options) ->
  #     conf = conf or {}

  #     JustdoHelpers.requireLogin(@, self) # helper's both/ddp-helpers.coffee

  #     restricted_pub_options =
  #       self._getRestrictedPublicationOptionsConfiguration(conf, @)

  #     # Note: full conf validations are taken care of by
  #     # self.getDueListQuery, don't worry about conf
  #     # related security
  #     {query, query_options, cleaned_conf} = self.getDueListQuery(conf, @userId)

  #     # Debug query:
  #     #
  #     #   Uncomment: 
  #     #   @added("JustdoSystem", "query", query)
  #     #   @added("JustdoSystem", "query-options", query_options)
  #     #   @added("JustdoSystem", "cleaned-conf", cleaned_conf)
  #     #   @ready()
  #     #   return
  #     #
  #     #   In the browser:
  #     #
  #     #   Tracker.autorun(() => {
  #     #     console.log("Query", JSON.stringify(
  #     #       APP.collections.JustdoSystem.findOne("query"), null, "\t"
  #     #     ));
  #     #     console.log("Query Options", JSON.stringify(
  #     #       APP.collections.JustdoSystem.findOne("query-options"), null, "\t"
  #     #     ));
  #     #     console.log("Clened conf", JSON.stringify(
  #     #       APP.collections.JustdoSystem.findOne("cleaned-conf"), null, "\t"
  #     #     ))
  #     #   });

  #     # Debug Due list:
  #     #
  #     #   In the browser:
  #     #
  #     #   if (typeof c !== "undefined") {c.stop()}
  #     #   c = Meteor.subscribe("getProjectsDueList", {})

  #     # Debug due list with custom collection:
  #     #
  #     #   // Run these two once:
  #     #   CustomCollection = new Mongo.Collection("CustomCollection")
  #     #   Tracker.autorun(() => {
  #     #     console.log(JSON.stringify(_.map(CustomCollection.find().fetch(), (i) => {
  #     #       return _.pick(i, "title", "state", "due_date", "follow_up", "project_id", "seqId", "priority");
  #     #     }), null, "\t"))
  #     #   });
  #     #
  #     #   // Run as much as needed:
  #     #   if (typeof c !== "undefined") {c.stop();}
  #     #   c = Meteor.subscribe("getProjectsDueList", {dates: ["2016-11-02", "2016-11-15"]}, {custom_col_name: "CustomCollection", label: "custom_label"});

  #     cursor = self.items_collection.find(query, query_options)

  #     return JustdoHelpers.customizedCursorPublish(@, cursor, pub_options, restricted_pub_options)

  #   Meteor.publish "getProjectsPrioritizedItems", (conf, pub_options) ->
  #     JustdoHelpers.requireLogin(@, self) # helper's both/ddp-helpers.coffee

  #     restricted_pub_options =
  #       self._getRestrictedPublicationOptionsConfiguration(conf, @)

  #     # Note: full conf validations are taken care of by
  #     # self.getPrioritizedItemsQuery, don't worry about conf
  #     # related security
  #     {query, query_options, cleaned_conf} = self.getPrioritizedItemsQuery(conf, @userId)

  #     # Debug query:
  #     #
  #     #   Uncomment: 
  #     #   @added("JustdoSystem", "query", query)
  #     #   @added("JustdoSystem", "query-options", query_options)
  #     #   @added("JustdoSystem", "cleaned-conf", cleaned_conf)
  #     #   @ready()
  #     #   return
  #     #
  #     #   In the browser:
  #     #
  #     #   Tracker.autorun(() => {
  #     #     console.log("Query", JSON.stringify(
  #     #       APP.collections.JustdoSystem.findOne("query"), null, "\t"
  #     #     ));
  #     #     console.log("Query Options", JSON.stringify(
  #     #       APP.collections.JustdoSystem.findOne("query-options"), null, "\t"
  #     #     ));
  #     #     console.log("Clened conf", JSON.stringify(
  #     #       APP.collections.JustdoSystem.findOne("cleaned-conf"), null, "\t"
  #     #     ))
  #     #   });

  #     # Debug prioritized items:
  #     #
  #     #   In the browser:
  #     #
  #     #   if (typeof c !== "undefined") {c.stop()}
  #     #   c = Meteor.subscribe("getProjectsPrioritizedItems", {})

  #     # Debug prioritized items with custom collection:
  #     #
  #     #
  #     #   // Run these two once:
  #     #   CustomCollection = new Mongo.Collection("CustomCollection")
  #     #   Tracker.autorun(() => {
  #     #     console.log(JSON.stringify(_.map(CustomCollection.find().fetch(), (i) => {
  #     #       return _.pick(i, "title", "state", "due_date", "follow_up", "project_id", "seqId", "priority");
  #     #     }), null, "\t"))
  #     #   });
  #     #
  #     #   // Run as much as needed:
  #     #   if (typeof c !== "undefined") {c.stop();}
  #     #   c = Meteor.subscribe("getProjectsPrioritizedItems", {limit: 100}, {custom_col_name: "CustomCollection", label: "custom_label"});


  #     cursor = self.items_collection.find(query, query_options)

  #     return JustdoHelpers.customizedCursorPublish(@, cursor, pub_options, restricted_pub_options)

  #   Meteor.publish "getProjectsAllInProgressItems", (conf, pub_options) ->
  #     JustdoHelpers.requireLogin(@, self) # helper's both/ddp-helpers.coffee

  #     restricted_pub_options =
  #       self._getRestrictedPublicationOptionsConfiguration(conf, @)

  #     # Note: full conf validations are taken care of by
  #     # self.getAllInProgressItemsQuery, don't worry about conf
  #     # related security
  #     {query, query_options, cleaned_conf} = self.getAllInProgressItemsQuery(conf, @userId)

  #     # Debug query:
  #     #
  #     #   Uncomment: 
  #     #   @added("JustdoSystem", "query", query)
  #     #   @added("JustdoSystem", "query-options", query_options)
  #     #   @added("JustdoSystem", "cleaned-conf", cleaned_conf)
  #     #   @ready()
  #     #   return
  #     #
  #     #   In the browser:
  #     #
  #     #   Tracker.autorun(() => {
  #     #     console.log("Query", JSON.stringify(
  #     #       APP.collections.JustdoSystem.findOne("query"), null, "\t"
  #     #     ));
  #     #     console.log("Query Options", JSON.stringify(
  #     #       APP.collections.JustdoSystem.findOne("query-options"), null, "\t"
  #     #     ));
  #     #     console.log("Clened conf", JSON.stringify(
  #     #       APP.collections.JustdoSystem.findOne("cleaned-conf"), null, "\t"
  #     #     ))
  #     #   });

  #     # Debug all in progress items:
  #     #
  #     #   In the browser:
  #     #
  #     #   if (typeof c !== "undefined") {c.stop()}
  #     #   c = Meteor.subscribe("getAllInItems", {})

  #     # Debug all in progress items with custom collection:
  #     #
  #     #   // Run these two once:
  #     #   CustomCollection = new Mongo.Collection("CustomCollection")
  #     #   Tracker.autorun(() => {
  #     #     console.log(JSON.stringify(_.map(CustomCollection.find().fetch(), (i) => {
  #     #       return _.pick(i, "title", "state", "due_date", "follow_up", "project_id", "seqId", "priority");
  #     #     }), null, "\t"))
  #     #   });
  #     #
  #     #   // Run as much as needed:
  #     #   if (typeof c !== "undefined") {c.stop();}
  #     #   c = Meteor.subscribe("getProjectsAllInProgressItems", {}, {custom_col_name: "CustomCollection", label: "custom_label"});


  #     cursor = self.items_collection.find(query, query_options)

  #     return JustdoHelpers.customizedCursorPublish(@, cursor, pub_options, restricted_pub_options)

  #   Meteor.publish "getProjectsStartDateItems", (conf, pub_options) ->
  #     JustdoHelpers.requireLogin(@, self) # helper's both/ddp-helpers.coffee

  #     restricted_pub_options =
  #       self._getRestrictedPublicationOptionsConfiguration(conf, @)

  #     # Note: full conf validations are taken care of by
  #     # self.getAllInProgressItemsQuery, don't worry about conf
  #     # related security
  #     {query, query_options, cleaned_conf} = self.getStartDateQuery(conf, @userId)

  #     # Debug query:
  #     #
  #     #   Uncomment: 
  #     #     @added("JustdoSystem", "query", query)
  #     #     @added("JustdoSystem", "query-options", query_options)
  #     #     @added("JustdoSystem", "cleaned-conf", cleaned_conf)
  #     #     @ready()
  #     #     return
  #     #
  #     #   In the browser:
  #     #
  #     #     Tracker.autorun(() => {
  #     #       console.log("Query", JSON.stringify(
  #     #         APP.collections.JustdoSystem.findOne("query"), null, "\t"
  #     #       ));
  #     #       console.log("Query Options", JSON.stringify(
  #     #         APP.collections.JustdoSystem.findOne("query-options"), null, "\t"
  #     #       ));
  #     #       console.log("Clened conf", JSON.stringify(
  #     #         APP.collections.JustdoSystem.findOne("cleaned-conf"), null, "\t"
  #     #       ))
  #     #     });

  #     # Debug start date items:
  #     #
  #     #   In the browser:
  #     #
  #     #     if (typeof c !== "undefined") {c.stop()}
  #     #     c = Meteor.subscribe("getProjectsStartDateItems", {dates: [null, null]})

  #     # Debug start date items with custom collection:
  #     #
  #     #   // Run these two once:
  #     #   CustomCollection = new Mongo.Collection("CustomCollection")
  #     #   Tracker.autorun(() => {
  #     #     console.log(JSON.stringify(_.map(CustomCollection.find().fetch(), (i) => {
  #     #       return _.pick(i, "title", "state", "start_date", "due_date", "follow_up", "project_id", "seqId", "priority");
  #     #     }), null, "\t"))
  #     #   });
  #     #
  #     #   // Run as much as needed:
  #     #   if (typeof c !== "undefined") {c.stop();}
  #     #   c = Meteor.subscribe("getProjectsStartDateItems", {dates: [null, null]}, {custom_col_name: "CustomCollection", label: "custom_label"});

  #     cursor = self.items_collection.find(query, query_options)

  #     return JustdoHelpers.customizedCursorPublish(@, cursor, pub_options, restricted_pub_options)

  _setupIndices: ->
    return