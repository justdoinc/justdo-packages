_.extend JustdoResourcesAvailability.prototype,
  setupRouter: ->
    Router.route '/justdo-resources-availability', ->
      @render 'justdo_resources_availability_page'

      return
    ,
      name: 'justdo_resources_availability_page'

    return