_.extend PACK.modules,
  tickets_queues:
    published_fields:
      _id: 1
      seqId: 1
      title: 1
      owner_id: 1
      project_id: 1
      
    initBoth: ->
      @attachSchema()

    attachSchema: ->
      Schema =
        is_tickets_queue:
          label: "Is tickets queue"
          grid_editable_column: false
          grid_visible_column: false
          grid_default_grid_view: false
          type: Boolean
          optional: true

      @items_collection.attachSchema Schema