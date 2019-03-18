_.extend JustdoRecaptcha.prototype,
  _bothImmediateInit: ->
    # @_bothImmediateInit runs before the specific env's @_immediateInit()

    # Add here code that should run, in the Server and Client, during the JS
    # tick in which we create the object instance.

    delete @options # We manipulate the binded options, so, remove the originals to avoid taking the non-manipulated ones

    @v2_checkbox_site_key = String(@v2_checkbox_site_key or "").trim()
    @v2_android_site_key = String(@v2_android_site_key or "").trim()

    if @supported
      if _.isEmpty(@v2_checkbox_site_key) or _.isEmpty(@v2_android_site_key) 
        @_error "invalid-options", "If recaptcha is supported, you must provide all the keys for both the Android and the Web-app checkbox captchas"

        return

      if Meteor.isServer
        @v2_checkbox_server_key = String(@v2_checkbox_server_key or "").trim()
        @v2_android_server_key = String(@v2_android_server_key or "").trim()

        if _.isEmpty(@v2_checkbox_server_key) or _.isEmpty(@v2_android_server_key)
          @_error "invalid-options", "If recaptcha is supported, you must provide all the keys for both the Android and the Web-app checkbox captchas"

          return

    return

  _bothDeferredInit: ->
    # @_bothDeferredInit runs before the specific env's @_deferredInit()

    # Add here code that should run, in the Server and Client, after the JS
    # tick in which we created the object instance.

    if @destroyed
      return

    return

  isSupported: -> @supported
