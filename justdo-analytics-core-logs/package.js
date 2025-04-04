Package.describe({
  name: "justdoinc:justdo-analytics-core-logs",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-analytics-core-logs"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("mongo", both);

  // api.use("stevezhu:lodash@4.17.2", both);
  // api.use("templating", client);
  // api.use('fourseven:scss@3.2.0', client);

  api.use("aldeed:simple-schema@1.5.3", both);
  api.use('aldeed:collection2@2.3.2', both);
  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.use("justdoinc:justdo-login-state@1.0.0", both);

  api.use("iron:router@1.1.2", both);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  api.addFiles("lib/both/analytics.coffee", both);

  api.addFiles("lib/client/init.coffee", client);
  api.addFiles("lib/client/errors-types.coffee", client);
  api.addFiles("lib/client/api.coffee", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/client/app-integration.coffee", client);

  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file. 

  api.addFiles("lib/server/core-logs.coffee", server);


  api.export("JustdoAnalyticsCoreLogs", both);
});
