APP.executeAfterAppLibCode ->
  bugmuncher_conf = null

  setupBugmuncherConfListener = _.once ->
    bugmuncher_conf = new ReactiveVar null

    APP.getEnv (env) ->
      bugmuncher_conf.set env.BUGMUNCHER_API_KEY

  getBugmucherApiKey = ->
    # Reactive resource, returns the bugmucher api key if it is set,
    # once it is ready (if isn't set, will always return null).
    setupBugmuncherConfListener()

    return bugmuncher_conf.get()

  Meteor.startup ->
    c = Tracker.autorun ->
      api_key = getBugmucherApiKey()

      if not (api_key? and api_key != "")
        APP.logger.debug "APP: env variable BUGMUNCHER_API_KEY undefined or empty, feedbacks by bugmuncher disabled"

        return

      c.stop() # no need to run again after we init for the first time

      window.bugmuncher_options = 
        api_key: api_key
        on_ready: ->
          return

      do ->
        node = document.createElement('script')

        node.setAttribute 'type', 'text/javascript'
        node.setAttribute 'src', '//cdn.bugmuncher.com/bugmuncher.js'
        document.getElementsByTagName('head')[0].appendChild node

        return 

  Template.tutorials_submenu_bugmuncher.helpers
    bugMuncherEnabled: -> getBugmucherApiKey()?

  Template.tutorials_submenu_bugmuncher.events
    "click .send-feedback": (e) ->
      e.preventDefault()

      tpl = Template.closestInstance("tutorials_submenu_dropdown")

      $(e.target).closest(".tutorials-menu").data().close()

      bugmuncher.open()

