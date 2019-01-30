Package.describe({
  name: "justdoinc:justdo-tutorials",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-tutorials"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", client);
  api.use("underscore", client);
  api.use("mongo", client);

  // api.use("stevezhu:lodash@4.17.2", client);
  api.use("templating", client);
  // api.use('fourseven:scss@3.2.0', client);

  api.use("raix:eventemitter@0.1.1", client);
  api.use("meteorspark:util@0.2.0", client);
  api.use("meteorspark:logger@0.3.0", client);
  api.use("justdoinc:justdo-helpers@1.0.0", client);
  api.use("aldeed:simple-schema@1.5.3", both);
  api.use("matb33:collection-hooks@0.8.4", client);

  api.use("reactive-var", client);
  api.use("reactive-dict", client);
  api.use("tracker", client);

  api.use("mizzao:tutorials@0.6.7", client);

  api.addFiles("lib/client/init.coffee", client);
  api.addFiles("lib/client/tutorials-registrar.coffee", client);
  api.addFiles("lib/client/static-api.coffee", client);
  api.addFiles("lib/client/errors-types.coffee", client);
  api.addFiles("lib/client/api.coffee", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", client);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", client);
  api.addFiles("lib/client/app-integration.coffee", client);
  // // Note: app-integration need to load last, so immediateInit procedures in
  // // the server will have the access to the apis loaded after the init.coffee
  // // file.

  api.export("JustdoTutorials", client);
});
