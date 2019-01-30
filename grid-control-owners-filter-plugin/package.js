Package.describe({
  name: "justdoinc:grid-control-owners-filter-plugin",
  version: "1.0.0",
  summary: "Adds to the task's subject column (title field) a filter that allows filtering by owner-id",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/grid-control-owners-filter-plugin"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", client);
  api.use("underscore", client);

  // api.use("stevezhu:lodash@4.17.2", client);
  // api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("raix:eventemitter@0.1.1", client);
  api.use("meteorspark:util@0.2.0", client);
  api.use("meteorspark:logger@0.3.0", client);
  api.use("justdoinc:justdo-helpers@1.0.0", client);

  api.use("justdoinc:justdo-avatar@1.0.0", client);

  api.use("matb33:collection-hooks@0.8.4", client);

  api.use("reactive-var", client);
  api.use("tracker", client);

  api.addFiles("lib/client/filter-controller.coffee", client);
  api.addFiles("lib/client/filter-controller.sass", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", client);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", client);

  api.use("stem-capital:grid-control@0.1.0", client);

  api.addFiles("lib/client/app-integration.coffee", client);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file. 

  api.export("GridControlOwnersFilterPlugin", client);
});
