_.extend JustdoCertMaintainer.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    fs = Npm.require "fs"
    https = Npm.require "https"
    util = Npm.require "util"
    path = Npm.require "path"

    pem_fetch_endpoint = "https://curl.se/ca/cacert.pem"
    cert = Assets.getText "lib/assets/cacert.pem"
    https.globalAgent.options.ca = [cert]

    last_updated_regex = /[A-Z][a-z]{2}\,.*GMT/ # Not strict, but works
    last_updated = cert.match(last_updated_regex)?[0]
    last_updated = new Date(last_updated).toGMTString()

    # If-Modified-Since prevents downloading the same file
    HTTP.get pem_fetch_endpoint, {headers: {"If-Modified-Since": last_updated}}, (e, r) ->
      if r.statusCode is 200
        {content} = r
        fs.writeFileSync "/plugins/justdo-cert-maintainer/lib/assets/cacert.pem", ("## Last updated: " + r.headers["last-modified"] + "\n" + content)
        https.globalAgent.options.ca = [content]

      return

    return
