Package.describe({
  name: "justdoinc:justdo-rollbar",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-rollbar"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);

  api.use('webapp', both);

  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("reactive-var", client);
  api.use("tracker", client);

  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);

  api.addFiles("lib/global.js", both);

  api.addFiles("lib/justdo-rollbar-client.coffee", client);
  api.addFiles("lib/justdo-rollbar-server.coffee", server);

  // inits are taken place here and rely on the environment
  // specific files, therefore loaded last
  api.addFiles("lib/justdo-rollbar-both.coffee", both);

  api.export("JustdoRollbar", both);
});
