_.extend JustdoGridVisualization.prototype,
  registerConfigTemplate: ->
    module = APP.modules.project_page
    module.project_config_ui.registerConfigTemplate "grid_visualization_config",
      section: "extensions"
      template: "grid_visualization_config"
      priority: 100

  showVisualizationButton: ->
    module_id = "grid-visualization"

    Template.project_header.onRendered () ->
      @autorun ->
        cur_project = APP.modules.project_page.curProj()
        if not cur_project?
          return

        is_enabled = cur_project.isCustomFeatureEnabled(module_id)

        if is_enabled
          JD.registerPlaceholderItem "grid-visualization",
            data:
              template: "grid_visualization_menu"
              template_data: {}

            domain: "project-right-navbar"
            position: 360
        else
          JD.unregisterPlaceholderItem "grid-visualization"

  showVisualization: ->
    selected_path = APP.modules.project_page.activeItemPath() or "/"
    selected_item = APP.modules.project_page.activeItemObj() or "/"
    project =  APP.modules.project_page.curProj()

    grid_data =  APP.modules.project_page.gridControl()._grid_data

    template_data =
      path: selected_path
      item: selected_item
      project: project
      grid: grid_data
      onClose: () => Blaze.remove(view)

    visualization_view =
      APP.helpers.renderTemplateInNewNode(Template.grid_visualization_modal, template_data)

    bootbox.dialog
      className: "grid-visualization-modal"
      message: visualization_view.node
      animate: false
      onEscape: ->
          return true

      buttons:
        download:
          label: """<i class="fa fa-download" aria-hidden="true"></i> Download Chart"""
          className: "btn-primary grid-visualization-show-on-ready"
          callback: (e) =>
            e.preventDefault()
            data = $('.grid-visualization-chart').attr("src")
            title = ($('.grid-visualization-header').text().replace(/[^a-zA-Z0-9\-_]/g, "_") or "Project_Timeline") + ".png"

            if window.navigator.msSaveBlob?
              # WORKAROUND for IE
              canvas = $(".grid-visualization-canvas")[0]
              blob = canvas.msToBlob()
              window.navigator.msSaveBlob(blob, title)
            else
              # Normal
              downloadURI = (uri, name) =>
                link = document.createElement("a")
                link.download = name
                link.href = uri
                document.body.appendChild(link)
                link.click()
                document.body.removeChild(link)
                # delete link
              downloadURI(data, title)

            return false
        close:
          label: "Close"
          className: "btn-primary"
          callback: () => return

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return
