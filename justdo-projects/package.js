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

  api.use('peerlibrary:async@1.5.2_1', server);

  api.use('stevezhu:lodash@4.16.4', both);
  api.use('aldeed:simple-schema@1.3.1', both);
  api.use('aldeed:collection2@2.3.2', both);

  api.use('fourseven:scss@3.2.0', client);

  api.use("justdoinc:justdo-push-notifications@1.0.0", server);

  api.use('lbee:moment-helpers@1.2.1', client);
  api.use('justdoinc:hash-requests-handler@1.0.0', both);
  api.use('justdoinc:justdo-login-state@1.0.0', both);

  api.use('justdoinc:bootboxjs@4.4.0', client);

  api.use('matb33:collection-hooks@0.8.0', both);

  api.use('fongandrew:find-and-modify@0.2.1', both);

  api.use('raix:eventemitter@0.1.1', both);
  api.use('meteorspark:util@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);

  api.use('stem-capital:grid-data', both);

  api.use('justdoinc:justdo-helpers@1.0.0', both);
  api.use('justdoinc:justdo-emails@1.0.0', both); // client is needed for media files

  api.use('justdoinc:justdo-tasks-collections-manager@1.0.0', both);

  api.use('justdoinc:grid-control-custom-fields@1.0.0', both);

  api.use('justdoinc:justdo-projects-shared-components@1.0.0', both);

  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);

  api.add_files('lib/globals.js', both);

  // both
  api.add_files('lib/both/main.coffee', server);
  api.add_files('lib/both/main.coffee', client, {bare: true});
  api.add_files('lib/both/static.coffee', both);
  api.add_files('lib/both/errors-types.coffee', both);
  api.add_files('lib/both/defaults.coffee', both);
  api.add_files('lib/both/helpers.coffee', both);
  api.add_files('lib/both/schema.coffee', both);

  // client
  api.add_files('lib/client/grid-sections/tickets-queue.coffee', client);
  api.add_files('lib/client/grid-sections/my-direct-tasks.coffee', client);
  api.add_files('lib/client/grid-sections/members-direct-tasks.coffee', client);
  api.add_files('lib/client/grid-sections/project-toolbar-detached-data-subtrees.coffee', client);

  api.add_files('lib/client/init.coffee', client);
  api.add_files('lib/client/api.coffee', client);
  api.add_files('lib/client/subscriptions.coffee', client);
  api.add_files('lib/client/load-project.coffee', client);
  api.add_files('lib/client/methods.coffee', client);
  api.add_files('lib/client/hash-requests.coffee', client);

  api.addFiles("lib/client/add-as-guest-toggle/add-as-guest-toggle.sass", client);
  api.addFiles("lib/client/add-as-guest-toggle/add-as-guest-toggle.html", client);
  api.addFiles("lib/client/add-as-guest-toggle/add-as-guest-toggle.coffee", client);

  // server
  api.add_files('lib/server/init.coffee', server);
  api.add_files('lib/server/api.coffee', server);
  api.add_files('lib/server/methods.coffee', server);
  api.add_files('lib/server/db-migrations.coffee', server);
  api.add_files('lib/server/fast-render.coffee', server);
  api.add_files('lib/server/collections-indices.coffee', server);
  api.add_files('lib/server/hooks.coffee', server);
  api.add_files('lib/server/projects-plugins-cache.coffee', server);
  api.add_files('lib/server/publications.coffee', server);
  api.add_files('lib/server/allow-deny.coffee', server);
  api.add_files('lib/server/grid-control-middlewares.coffee', server);

  //
  // modules
  //

  // due-lists
  api.add_files('lib/modules/due-lists/due-lists-both.coffee', both);
  api.add_files('lib/modules/due-lists/due-lists-client.coffee', client);
  api.add_files('lib/modules/due-lists/due-lists-server.coffee', server);

  // tickets queues
  api.add_files('lib/modules/owners/owners-both.coffee', both);
  api.add_files('lib/modules/owners/owners-server.coffee', server);
  api.add_files('lib/modules/owners/templates/ownership-rejection-hash-request-bootbox.html', client);
  api.add_files('lib/modules/owners/templates/ownership-rejection-hash-request-bootbox.sass', client);
  api.add_files('lib/modules/owners/owners-client.coffee', client);

  // tickets queues
  api.add_files('lib/modules/tickets-queues/tickets-queues-both.coffee', both);
  api.add_files('lib/modules/tickets-queues/tickets-queues-client.coffee', client);
  api.add_files('lib/modules/tickets-queues/tickets-queues-grid-section-styling.sass', client);
  api.add_files('lib/modules/tickets-queues/tickets-queues-server.coffee', server);

  // required actions
  api.add_files('lib/modules/required-actions/required-actions-both.coffee', both);
  api.add_files('lib/modules/required-actions/required-actions-client.coffee', client);
  api.add_files('lib/modules/required-actions/required-actions-common.sass', client);
  api.add_files('lib/modules/required-actions/required-actions-server.coffee', server);

  //
  // required actions types definitions
  //

  // ownership transfer request
  api.add_files('lib/modules/required-actions/types/transfer-request/transfer-request-server.coffee', server);
  api.add_files('lib/modules/required-actions/types/transfer-request/transfer-request-card.html', client);
  api.add_files('lib/modules/required-actions/types/transfer-request/transfer-request-card.sass', client);
  api.add_files('lib/modules/required-actions/types/transfer-request/transfer-request-card.coffee', client);

  // ownership transfer rejected
  api.add_files('lib/modules/required-actions/types/ownership-transfer-rejected/ownership-transfer-rejected-server.coffee', server);
  api.add_files('lib/modules/required-actions/types/ownership-transfer-rejected/ownership-transfer-rejected-card.html', client);
  api.add_files('lib/modules/required-actions/types/ownership-transfer-rejected/ownership-transfer-rejected-card.sass', client);
  api.add_files('lib/modules/required-actions/types/ownership-transfer-rejected/ownership-transfer-rejected-card.coffee', client);

  // Personal tasks
  api.add_files('lib/modules/direct-tasks/direct-tasks-both.coffee', both);
  api.add_files('lib/modules/direct-tasks/direct-tasks-client.coffee', client);
  api.add_files('lib/modules/direct-tasks/direct-tasks-server.coffee', server);

  api.add_files('lib/both/app-integration.coffee', both);

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
