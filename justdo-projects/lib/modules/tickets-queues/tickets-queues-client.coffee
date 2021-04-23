_.extend PACK.modules.tickets_queues,
  initClient: ->
    @collection = @options.local_tickets_queue_collection

    @_tickets_queues_cache = {}
    @_tickets_queues_cache_dep = new Tracker.Dependency()

    @maintainTicketsQueuesCache()

    return

  subscribe: (project_id) ->
    @logger.debug "Subscribe #{project_id} tickets queue"

    return @_setSubscriptionHandle("project_tickets_queues", Meteor.subscribe("projectsTicketsQueues", project_id))

  maintainTicketsQueuesCache: ->
    Tracker.autorun =>
      @_tickets_queues_cache = {}

      @collection.find({}, {fields: @published_fields}).forEach (ticket_queue_doc) =>
        @_tickets_queues_cache[ticket_queue_doc._id] = ticket_queue_doc

        return

      @_tickets_queues_cache_dep.changed()

      return

    return

  getTicketsQueues: ->
    @_tickets_queues_cache_dep.depend()

    return @_tickets_queues_cache

  opreqProjectHasTicketsQueues: (prereq) ->
    prereq = JustdoHelpers.prepareOpreqArgs(prereq)

    if @collection.find().count() == 0
      prereq.no_tickets_queue = "This project has no tickets queue"

    return prereq