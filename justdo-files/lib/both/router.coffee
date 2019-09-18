_.extend JustdoFiles.prototype,
  setupRouter: ->
    Router.route '/justdo-files', ->
      @render 'justdo_files_page'

      return
    ,
      name: 'justdo_files_page'

    return