# Reminder:
# 1. Dom events order: mousedown -> blur -> mouseup -> click
# 2. e.preventDefault() on mousedown will prevent blur.
# 3. A higher precedence event will trigger before a lower precedence
#    event even if defined for on a higher dom element.

_.extend PACK.FormattersInit,
  textWithTreeControls: ->
    @_grid.onClick.subscribe (e, args) =>
      # Event will be bind by slick.grid to $canvas

      # Important, this event won't be called if clicked on
      # active editor - event defined below under:
      # ['click', '.grid-tree-control-toggle'] will take
      # control in that case.
      if $(e.target).hasClass("grid-tree-control-toggle")
        save_and_exit_not_prevented = @saveAndExitActiveEditor()

        if save_and_exit_not_prevented
          # Note call to toggle will result in invalidation of the row
          # that will prvent other events from happening for that element
          @_grid_data.toggleItem args.row

        # If grid-tree-control-toggle clicked, stop propagation
        # to prevent activating the toggled item
        e.stopImmediatePropagation()

#
# grid-tree-control-toggle handling
#
recent_mousedown_event_row = null
PACK.jquery_events.push
  args: ['mousedown', '.grid-tree-control-toggle']
  handler: (e) ->
    if @eventCellIsActiveCell(e)
      # preventDefault in order to prevent blur event defined on destroy_editor_on_blur.coffee
      # from exiting edit mode. Exiting edit mode will destroy the current cell
      # and .grid-tree-control-toggle click event defined below will never trigger

      e.preventDefault()
    else
      # Else is kept for documentation purposes.
      #
      # [COMMENT 1]: Without this toggle won't work if there's an active editor that isn't
      # the toggle cell but on the same row it is assumed that changes to position
      # of elements between mousedown to mouseup when a cell gets invalidated
      # results in click event for .grid-tree-control-toggle to not trigger correctly
      e.preventDefault()

PACK.jquery_events.push
  args: ['click', '.grid-tree-control-toggle']
  handler: (e) ->
    # Important, this event handler will be triggered only
    # if .grid-tree-control-toggle clicked on an active editor
    # in any other case click on the toggle command issued on the
    # @_grid.onClick.subscribe handler defined above will result
    # in invalidation of the row and hence removal of this element
    # so this event will never be reached.
    clicked_row = @_grid.getCellFromEvent(e).row

    # Close the current editor so toggle won't be suspended by the
    # flush lock active during editing
    save_and_exit_not_prevented = @saveAndExitActiveEditor()

    if save_and_exit_not_prevented
      # Toggle only if managed to exit active editor
      @_grid_data.toggleItem clicked_row

#
# grid-tree-control-user handling
#
PACK.jquery_events.push
  args: ['mousedown', '.grid-tree-control-task-id']
  handler: (e) ->
    if @eventCellIsActiveCell(e)
      # If grid-tree-control-task-id is clicked on the active
      # item, exit editor, if exist
      @saveAndExitActiveEditor()

#
# grid-tree-control-user handling
#
PACK.jquery_events.push
  args: ['mousedown', '.grid-tree-control-user']
  handler: (e) ->
    if @eventCellIsActiveCell(e)
      # preventDefault in order to prevent blur event defined on destroy_editor_on_blur.coffee
      # from exiting edit mode. Exiting edit mode will destroy the current cell
      # and .grid-tree-control-user click event defined below will never trigger

      e.preventDefault()

#
# grid-tree-control-user handling
#
PACK.jquery_events.push
  args: ['mouseup', '.grid-tree-control-user']
  handler: (e) ->
    # For the reasone mouseup chosen instead of click, check [COMMENT 1]
    # above, it's assumed that same causes apply here, but 
    # e.preventDefault() for any case in .grid-tree-control-user mousedown
    # is not enough in that case.
    save_and_exit_not_prevented = @saveAndExitActiveEditor()

    if save_and_exit_not_prevented
      @emit "tree-control-user-image-clicked", e
    else
      @logger.debug "tree-control-user-image-clicked event didn't emit due to failure to close active editor"