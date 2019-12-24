os = require("os")

_.extend JustdoHelpers,
  getNetworkInterfacesIps: ->
    interfaces = os.networkInterfaces()
    interfaces_ips = new Set()
    Object.keys(interfaces).forEach (ifname) ->
      interfaces[ifname].forEach (iface) ->
        if "IPv4" != iface.family or iface.internal != false
          return

        interfaces_ips.add(iface.address)

        return
      return

    return Array.from(interfaces_ips)