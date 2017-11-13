default_options = {
  expand_all_max: 1000
  expand_all_error_snackbar_text: "To many items to expand the entire tree"
  expand_all_error_snackbar_action_text: "Dismiss"
  expand_all_error_snackbar_on_action_click: -> JustdoSnackbar.close()
}

setupCollapseAllButton = (grid_control) ->
  # Options are passed to the standard grid_control options argument upon init of the constructor.

  options = _.extend {}, default_options, grid_control.options # apply actual options passed by the user

  $el = $("""<div class="grid-state-button collapse-grid-button" title="Collapse all tree" />""")
    .click =>
      grid_control._grid_data.collapseAllPaths()

  $(".slick-header-column:first", grid_control.container)
    .append($el)

  $el = $("""<div class="grid-state-button expand-grid-button" title="Exapand all tree" />""")
    .click =>
      i = 0

      failed = false
      grid_control._grid_data.each "/", {filtered_tree: true, expand_only: false}, =>
        i += 1

        if i > options.expand_all_max
          failed = true

          return -2

        return

      if failed
        JustdoSnackbar.show
          text: options.expand_all_error_snackbar_text
          actionText: options.expand_all_error_snackbar_action_text
          onActionClick: options.expand_all_error_snackbar_on_action_click

        return

      grid_control._grid_data.expandPassedFilterPaths()

      return

  $(".slick-header-column:first", grid_control.container)
    .append($el)

  return

_.extend PACK.Plugins,
  collapse_all:
    init: ->
      # Note: @ is the grid_control object

      setupCollapseAllButton(@)

      @on "columns-headers-dom-rebuilt", =>
        setupCollapseAllButton(@)

      return

    destroy: ->
      return