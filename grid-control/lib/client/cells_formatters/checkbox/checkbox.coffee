# GridControl.installFormatter "checkboxFormatter",
#   slick_grid: ->
#     {value} = @getFriendlyArgs()

#     input = '<input type="checkbox" class="checkbox-formatter" value="#{value}"'

#     if value
#       return input += ' checked />'

#     return input += ' />'

#   slick_grid_jquery_events:
#     [
#       {
#         # Save checkbox formatter on_change
#         args: ['change', '.checkbox-formatter']
#         handler: (e) ->
#           cell = @_grid.getCellFromEvent(e)
#           field = @getCellField cell.cell
#           item = @_grid_data.getItem(cell.row)
#           item_id = if item? then item._id else undefined

#           query = {}
#           query[field] = $(e.currentTarget).prop('checked')
#           @_grid_data.collection.update item_id, {$set: query}
#       }
#     ]

#   print: (doc, field) ->
#     {value} = @getFriendlyArgs()

#     return if value then "+" else "-"