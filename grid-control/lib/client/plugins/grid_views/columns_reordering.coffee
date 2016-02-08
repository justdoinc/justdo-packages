_.extend GridControl.prototype,
  _setupColumnsReordering: ->
    # Implement columns reordering
    header_columns_container = $('.slick-header-columns', @container)
    header_columns_container.sortable
      items: '> .slick-header-reorderable'
      axis: "x"
      update: =>
        view = @getView()

        new_columns_order = []
        $('> :not(:first)', header_columns_container).each (index, item) =>
          new_columns_order.push $(item).data().column.field

        new_view = _.map new_columns_order, (field) ->
          for column_def in view
            if column_def.field == field
              return column_def

        @setView(new_view)