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

  api.use("tap:i18n", both);
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

  // Always after templates
  api.addFiles([
    "i18n/en.i18n.json",
    "i18n/ar.i18n.json",
    "i18n/es.i18n.json",
    "i18n/fr.i18n.json",
    "i18n/he.i18n.json",
    "i18n/ja.i18n.json",
    "i18n/km.i18n.json",
    "i18n/ko.i18n.json",
    "i18n/pt-PT.i18n.json",
    "i18n/pt-BR.i18n.json",
    "i18n/vi.i18n.json",
    "i18n/ru.i18n.json",
    "i18n/yi.i18n.json",
    "i18n/it.i18n.json",
    "i18n/de.i18n.json",
    "i18n/hi.i18n.json",
    "i18n/tr.i18n.json",
    "i18n/el.i18n.json",
    "i18n/da.i18n.json",
    "i18n/fi.i18n.json",
    "i18n/nl.i18n.json",
    "i18n/sv.i18n.json",
    "i18n/th.i18n.json",
    "i18n/id.i18n.json",
    "i18n/pl.i18n.json",
    "i18n/cs.i18n.json",
    "i18n/hu.i18n.json",
    "i18n/ro.i18n.json",
    "i18n/sk.i18n.json",
    "i18n/uk.i18n.json",
    "i18n/bg.i18n.json",
    "i18n/hr.i18n.json",
    "i18n/sr.i18n.json",
    "i18n/sl.i18n.json",
    "i18n/et.i18n.json",
    "i18n/lv.i18n.json",
    "i18n/lt.i18n.json",
    "i18n/am.i18n.json",
    "i18n/zh-CN.i18n.json",
    "i18n/zh-TW.i18n.json",
    "i18n/sw.i18n.json",
    "i18n/af.i18n.json",
    "i18n/az.i18n.json",
    "i18n/be.i18n.json",
    "i18n/bn.i18n.json",
    "i18n/bs.i18n.json",
    "i18n/ca.i18n.json",
    "i18n/eu.i18n.json",
    "i18n/lb.i18n.json",
    "i18n/mk.i18n.json",
    "i18n/ne.i18n.json",
    "i18n/nb.i18n.json",
    "i18n/sq.i18n.json",
    "i18n/ta.i18n.json",
    "i18n/uz.i18n.json",
    "i18n/hy.i18n.json",
    "i18n/kk.i18n.json",
    "i18n/ky.i18n.json",
    "i18n/ms.i18n.json",
    "i18n/tg.i18n.json"
  ], both);

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
