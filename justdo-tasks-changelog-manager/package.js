Package.describe({
  name: "justdoinc:tasks-changelog-manager",
  version: "1.0.0",
  summary: "Maintains and provides a changelog for a justdo Tasks collection",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/tasks-changelog-manager"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("mongo", both);

  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("templating", client);

  api.use("meteorhacks:subs-manager",both);
  api.use("momentjs:moment",both);
  api.use("fourseven:scss@3.2.0", client);

  api.use('raix:eventemitter@0.1.1', both);
  api.use('meteorspark:util@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);
  api.use('justdoinc:justdo-helpers@1.0.0', both);

  api.use('justdoinc:grid-control-custom-fields@1.0.0', both);

  api.use('matb33:collection-hooks@0.8.4', both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  api.addFiles("lib/globals.js", both);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/static.coffee", both);
  api.addFiles("lib/both/static-api.coffee", both);
  api.addFiles('lib/both/errors-types.coffee', both);
  api.addFiles("lib/both/api.coffee", both);
  api.addFiles("lib/both/schemas.coffee", both);

  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/allow-deny.coffee", server);
  api.addFiles("lib/server/collections-hooks.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);

  // Builtin trackers
  api.addFiles("lib/server/builtin-trackers/new-task.coffee", server);
  api.addFiles("lib/server/builtin-trackers/parents-changes.coffee", server);
  api.addFiles("lib/server/builtin-trackers/priority-changes.coffee", server);
  api.addFiles("lib/server/builtin-trackers/redundant-logs.coffee", server);
  api.addFiles("lib/server/builtin-trackers/remove-task.coffee", server);
  api.addFiles("lib/server/builtin-trackers/simple-tasks-fields-changes.coffee", server);
  api.addFiles("lib/server/builtin-trackers/task-users-changes.coffee", server);
  api.addFiles("lib/server/builtin-trackers/pending-ownership-transfer.coffee", server);

  api.addFiles("lib/client/init.coffee", client);
  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);

  api.addFiles("lib/client/templates/task-pane-task-changelog.html", client);
  api.addFiles("lib/client/templates/task-pane-task-changelog.coffee", client);
  api.addFiles("lib/client/templates/task-pane-task-changelog.sass", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/both/app-integration.coffee", both);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file.

  api.export("TasksChangelogManager", both);
});
