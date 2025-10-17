Package.describe({
  name: "justdoinc:tasks-file-manager",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/tasks-file-manager"
});

client = "client"
server = "server"
both = [client, server]


// I believe that crypto is a core node package, when I add an Npm.depends
// call for crypto the package breaks with the error:
//
//   Error: Cannot find module .../node_modules/crypto

// Npm.depends({
//   "crypto": "0.0.3"
// });

Package.onUse(function (api) {
  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("check", both);

  api.use("aldeed:simple-schema@1.5.3", both);
  api.use('aldeed:collection2@2.3.2', both);
  api.use('raix:eventemitter@0.1.1', both);
  api.use('meteorspark:util@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);
  api.use('justdoinc:justdo-helpers@1.0.0', both);

  api.use('matb33:collection-hooks@0.8.4', both);

  api.use('justdoinc:filestack-base@1.0.0', both);
  api.use("justdoinc:tasks-changelog-manager@1.0.0", both);

  api.use("reactive-var", both);
  api.use("tracker", client);
  api.use("templating", client);
  api.use("jquery", client);
  api.use("random", client);

  api.use("http", server);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/static.coffee", both);
  api.addFiles('lib/both/errors-types.coffee', both);
  api.addFiles("lib/both/api.coffee", both);
  api.addFiles("lib/both/collections-schemas.coffee", both);

  api.addFiles("lib/server/init.coffee", server);
  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/allow-deny.coffee", server);
  api.addFiles("lib/server/collections-hooks.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);
  api.addFiles("lib/server/db-migrations.coffee", server);

  api.addFiles("lib/client/init.coffee", client);
  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);
  api.addFiles("lib/client/drop-pane.coffee", client);

  api.export("TasksFileManager", both);
});
