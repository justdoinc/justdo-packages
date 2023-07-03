_.extend JustdoLicensing.prototype,
  _immediateInit: ->
    @_license_rv = new ReactiveVar null

    return

  _deferredInit: ->
    if @destroyed
      return

    return

  getLicense: ->
    # Reactive resource
    @_loadLicense()

    return @_license_rv.get()

  _loadLicense: ->
    self = @

    if @_license_rv.get()?
      # Already loaded
      return

    @getLicenseFromServer (err, license_obj) ->
      if err?
        console.error err

        return

      self._license_rv.set(license_obj)

      return

    return
