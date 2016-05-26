Package.describe({
  name: 'stem-capital:grid-data',
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
  api.use('tracker', both);
  api.use('reactive-var', both);

  api.use('raix:eventemitter@0.1.1', both);
  api.use('matb33:collection-hooks@0.7.13', both);
  api.use('meteorspark:util@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);
  api.use('meteorspark:json-sortify@0.1.0', both);
  api.use('ovcharik:jsdiff@2.0.1', both);
  api.use('justdoinc:justdo-helpers@1.0.0', both);

  api.add_files('lib/globals.js', both);
  api.add_files('lib/helpers.coffee', both);

  // GridData
  api.add_files('lib/grid-data/grid-data.coffee', client);

  // GridDataCom
  api.add_files('lib/grid-data-com/grid-data-com-client.coffee', client);
  api.add_files('lib/grid-data-com/grid-data-com-server.coffee', server);

  api.add_files('lib/errors-types.coffee', both);

  // Core data structures
  api.add_files('lib/grid-data/data-structure-management/core-data-structures.coffee', client);

  // Load apis
  api.add_files('lib/grid-data/api/core-api.coffee', client);
  api.add_files('lib/grid-data/api/search.coffee', client);

  // Filters
  api.add_files('lib/grid-data/data-structure-management/filters/filters.coffee', client);
  api.add_files('lib/grid-data/data-structure-management/filters/filters-independent-items.coffee', client);

  // Items Types settings
  api.add_files('lib/grid-data/data-structure-management/items-types/items-types.coffee', client);
  api.add_files('lib/grid-data/data-structure-management/items-types/types-settings/section-item.coffee', client);

  // Grid Sections
  api.add_files('lib/grid-data/data-structure-management/grid-sections/grid-sections.coffee', client);
  api.add_files('lib/grid-data/data-structure-management/grid-sections/sections-managers/section-manager-proto.coffee', client);
  api.add_files('lib/grid-data/data-structure-management/grid-sections/sections-managers/natural-collection-subtree.coffee', client);
  api.add_files('lib/grid-data/data-structure-management/grid-sections/sections-managers/data-tree.coffee', client);
  api.add_files('lib/grid-data/data-structure-management/grid-sections/sections-managers/detached-data-subtrees.coffee', client);
  api.add_files('lib/grid-data/data-structure-management/grid-sections/sections-managers/tickets-queue.coffee', client);

  // Metadata management
  api.add_files('lib/grid-data/data-structure-management/metadata.coffee', client);

  // Collection operations
  api.add_files('lib/grid-data/collection-operations/collection-operations.coffee', client);
  api.add_files('lib/grid-data/collection-operations/hooks.coffee', client);

  api.export('GridData');
  api.export('GridDataCom');
  api.export('GridDataSectionManager');
});

Package.onTest(function(api) {
  api.versionsFrom('1.1.0.2');

  api.use('tinytest', both);
  api.use('coffeescript', both);
  api.use('mongo', both);
  api.use('minimongo', both);
  api.use('tracker', both);
  api.use('meteorspark:test-helpers@0.2.0', both);

  api.use('stem-capital:grid-data', both);
  api.use('stem-capital:grid-data-seeder', server);

  api.add_files('lib/helpers.coffee', both);

  api.addFiles('unittest/setup/both.coffee', client, {bare: true});
  api.addFiles('unittest/setup/both.coffee', server);
  api.addFiles('unittest/setup/server.coffee', server);
  api.addFiles('unittest/setup/client.coffee', client);
  api.addFiles('unittest/client.coffee', client);

  // Just so we can use it from the console for debugging...
  api.export('GridData');
  api.export('GridDataCom');
  api.export('TestCol');
});
