Package.describe({
  name: "justdoinc:grid-control-mux",
  version: "1.0.0",
  summary: "Grid Controls Multiplexer",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/grid-control-mux"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.3");

  api.use("coffeescript", both);
  api.use("underscore", both);

  api.use('raix:eventemitter@0.1.1', both);
  api.use('meteorspark:util@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);
  api.use('justdoinc:justdo-helpers@1.0.0', both);

  api.use('fourseven:scss@3.2.0', client);
  api.use('stem-capital:grid-control', client);

  api.use("reactive-var", both);
  api.use("tracker", client);

  api.add_files("lib/both/init.coffee", both);
  api.add_files('lib/both/errors-types.coffee', both);
  api.add_files("lib/both/api.coffee", both);

  api.add_files("lib/server/init.coffee", server);
  api.add_files("lib/server/api.coffee", server);
  api.add_files("lib/server/allow-deny.coffee", server);
  api.add_files("lib/server/methods.coffee", server);

  api.add_files("lib/client/init.coffee", client);
  api.add_files("lib/client/api.coffee", client);
  api.add_files("lib/client/methods.coffee", client);
  api.add_files("lib/client/style.sass", client);

  api.export("GridControlMux", both);
});