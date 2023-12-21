_.extend JustdoVimeoLoader.prototype,
  _immediateInit: ->
    @is_vimeo_player_loaded_rv = new ReactiveVar false
    return

  _deferredInit: ->
    if @destroyed
      return

    return
  
  loadVimeoPlayer: (retry=5, wait_seconds=1) ->
    if @is_vimeo_player_loaded_rv.get()
      return

    tryAgain = =>
      if retry > 0
        console.info "Retrying to load Vimeo player script in #{wait_seconds} seconds... (#{retry} retries left)"

        Meteor.setTimeout =>
          @loadVimeoPlayer retry - 1, wait_seconds * 2
          
          return
        , wait_seconds * 1000
      else
        console.warn "Vimeo player script failed to load."

      return

    # Load script from https://player.vimeo.com/api/player.js to load the Vimeo player.
    # If it fails, print a warning and don't set is_vimeo_player_loaded_rv to true.
    $.getScript("https://player.vimeo.com/api/player.js", =>
      if not window.Vimeo
        console.warn "Vimeo player script failed to load."

        tryAgain()

        return

      @is_vimeo_player_loaded_rv.set true
      return
    ).fail =>
      tryAgain()

      return

    return

  forceLoadVimeoPlayer: ->
    @is_vimeo_player_loaded_rv.set false
    @loadVimeoPlayer()
    return

  isVimeoPlayerLoaded: ->
    return @is_vimeo_player_loaded_rv.get()