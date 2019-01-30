_.extend PACK.modules,
  tickets_queues:
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