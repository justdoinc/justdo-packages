Package.describe({
  name: 'stem-capital:projects',
  summary: '',
  version: '0.1.0'
});

both = ['server', 'client'];
server = 'server';
client = 'client';

Package.onUse(function (api) {
  api.versionsFrom('1.1.0.2');

  api.use('coffeescript', both);
  api.use('underscore', both);
  api.use('templating', client);
  api.use('check', both);
  api.use('reactive-dict', both);
  api.use("tracker", client);

  api.use("amplify", client);

  api.use('peerlibrary:async@1.5.2_1', server);

  api.use('stevezhu:lodash@4.16.4', both);
  api.use('aldeed:simple-schema@1.3.1', both);
  api.use('aldeed:collection2@2.3.2', both);

  api.use('fourseven:scss@3.2.0', client);
  api.use("tap:i18n", both);
  api.use("justdoinc:justdo-i18n@1.0.0", both);

  api.use("justdoinc:justdo-push-notifications@1.0.0", server);

  api.use('justdoinc:hash-requests-handler@1.0.0', both);
  api.use('justdoinc:justdo-login-state@1.0.0', both);

  api.use('justdoinc:bootboxjs@4.4.0', client);

  api.use('matb33:collection-hooks@0.8.0', both);

  api.use('raix:eventemitter@0.1.1', both);
  api.use('meteorspark:util@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);

  api.use('stem-capital:grid-data', both);

  api.use('justdoinc:justdo-helpers@1.0.0', both);
  api.use('justdoinc:justdo-emails@1.0.0', both); // client is needed for media files

  api.use('justdoinc:justdo-tasks-collections-manager@1.0.0', both);
  api.use("stem-capital:grid-control@0.1.0", client);
  api.use('justdoinc:grid-control-custom-fields@1.0.0', both);

  api.use('justdoinc:justdo-projects-shared-components@1.0.0', both);

  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.use("justdoinc:justdo-ddp-extensions@1.0.0", both, {weak: true});

  api.addFiles('lib/globals.js', both);

  // both
  api.addFiles('lib/both/init.coffee', server);
  api.addFiles('lib/both/init.coffee', client, {bare: true});
  api.addFiles('lib/both/static.coffee', both);
  api.addFiles('lib/both/errors-types.coffee', both);
  api.addFiles('lib/both/defaults.coffee', both);
  api.addFiles('lib/both/helpers.coffee', both);
  api.addFiles('lib/both/schema.coffee', both);

  // client
  api.addFiles('lib/client/grid-sections/tickets-queue.coffee', client);
  api.addFiles('lib/client/grid-sections/my-direct-tasks.coffee', client);
  api.addFiles('lib/client/grid-sections/members-direct-tasks.coffee', client);
  api.addFiles('lib/client/grid-sections/project-toolbar-detached-data-subtrees.coffee', client);
  api.addFiles("lib/client/display-name-formatter.coffee", client);

  api.addFiles('lib/client/init.coffee', client);
  api.addFiles('lib/client/api.coffee', client);
  api.addFiles('lib/client/subscriptions.coffee', client);
  api.addFiles('lib/client/load-project.coffee', client);
  api.addFiles('lib/client/methods.coffee', client);
  api.addFiles('lib/client/hash-requests.coffee', client);
  api.addFiles('lib/client/drawer-menu-items.coffee', client);

  api.addFiles("lib/client/add-as-guest-toggle/add-as-guest-toggle.sass", client);
  api.addFiles("lib/client/add-as-guest-toggle/add-as-guest-toggle.html", client);
  api.addFiles("lib/client/add-as-guest-toggle/add-as-guest-toggle.coffee", client);

  // server
  api.addFiles('lib/server/init.coffee', server);
  api.addFiles('lib/server/api.coffee', server);
  api.addFiles('lib/server/methods.coffee', server);
  api.addFiles('lib/server/db-migrations.coffee', server);
  api.addFiles('lib/server/fast-render.coffee', server);
  api.addFiles('lib/server/collections-indices.coffee', server);
  api.addFiles('lib/server/hooks.coffee', server);
  api.addFiles('lib/server/projects-plugins-cache.coffee', server);
  api.addFiles('lib/server/publications.coffee', server);
  api.addFiles('lib/server/allow-deny.coffee', server);
  api.addFiles('lib/server/grid-control-middlewares.coffee', server);

  //
  // modules
  //

  // due-lists
  api.addFiles('lib/modules/due-lists/due-lists-both.coffee', both);
  api.addFiles('lib/modules/due-lists/due-lists-client.coffee', client);
  api.addFiles('lib/modules/due-lists/due-lists-server.coffee', server);

  // tickets queues
  api.addFiles('lib/modules/owners/owners-both.coffee', both);
  api.addFiles('lib/modules/owners/owners-server.coffee', server);
  api.addFiles('lib/modules/owners/templates/ownership-rejection-hash-request-bootbox.html', client);
  api.addFiles('lib/modules/owners/templates/ownership-rejection-hash-request-bootbox.sass', client);
  api.addFiles('lib/modules/owners/owners-client.coffee', client);

  // tickets queues
  api.addFiles('lib/modules/tickets-queues/tickets-queues-both.coffee', both);
  api.addFiles('lib/modules/tickets-queues/tickets-queues-client.coffee', client);
  api.addFiles('lib/modules/tickets-queues/tickets-queues-grid-section-styling.sass', client);
  api.addFiles('lib/modules/tickets-queues/tickets-queues-server.coffee', server);

  // required actions
  api.addFiles('lib/modules/required-actions/required-actions-both.coffee', both);
  api.addFiles('lib/modules/required-actions/required-actions-client.coffee', client);
  api.addFiles('lib/modules/required-actions/required-actions-common.sass', client);
  api.addFiles('lib/modules/required-actions/required-actions-server.coffee', server);

  //
  // required actions types definitions
  //

  // ownership transfer request
  api.addFiles('lib/modules/required-actions/types/transfer-request/transfer-request-server.coffee', server);
  api.addFiles('lib/modules/required-actions/types/transfer-request/transfer-request-card.html', client);
  api.addFiles('lib/modules/required-actions/types/transfer-request/transfer-request-card.sass', client);
  api.addFiles('lib/modules/required-actions/types/transfer-request/transfer-request-card.coffee', client);

  // ownership transfer rejected
  api.addFiles('lib/modules/required-actions/types/ownership-transfer-rejected/ownership-transfer-rejected-server.coffee', server);
  api.addFiles('lib/modules/required-actions/types/ownership-transfer-rejected/ownership-transfer-rejected-card.html', client);
  api.addFiles('lib/modules/required-actions/types/ownership-transfer-rejected/ownership-transfer-rejected-card.sass', client);
  api.addFiles('lib/modules/required-actions/types/ownership-transfer-rejected/ownership-transfer-rejected-card.coffee', client);

  // Personal tasks
  api.addFiles('lib/modules/direct-tasks/direct-tasks-both.coffee', both);
  api.addFiles('lib/modules/direct-tasks/direct-tasks-client.coffee', client);
  api.addFiles('lib/modules/direct-tasks/direct-tasks-server.coffee', server);

  api.addFiles('lib/both/app-integration.coffee', both);

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

  api.export('Projects');
});

Package.onTest(function(api) {
  api.versionsFrom('1.1.0.2');

  api.use('tinytest', both);
  api.use('coffeescript', both);
  api.use('mongo', both);
  api.use('meteorspark:test-helpers@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);

  api.use('stem-capital:projects', both);

  api.addFiles('unittest/both.coffee', server);
  api.addFiles('unittest/server.coffee', server);
  api.addFiles('unittest/client.coffee', client);

  // Just so we can use it from the console for debugging...
  api.export('Projects');
});
