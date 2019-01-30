_.extend Projects.prototype,
  setAllRoutesFastRenderRules: ->
    this.subscribe "userProjects"