_.extend JustdoVimeoLoader.prototype,
  _immediateInit: ->
    @is_vimeo_player_loaded_rv = new ReactiveVar false
    return

  _deferredInit: ->
    if @destroyed
      return

    return
  
  loadVimeoPlayer: ->
    if @is_vimeo_player_loaded_rv.get()
      return
    $("head").append """<script src="https://player.vimeo.com/api/player.js"></script>"""
    @is_vimeo_player_loaded_rv.set true
    return

  isVimeoPlayerLoaded: ->
    return @is_vimeo_player_loaded_rv.get()