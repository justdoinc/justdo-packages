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
  api.use('check', both);

  api.use("meteorspark:app@0.3.0", both);

  api.use("justdoinc:justdo-ddp-extensions@1.0.0", both, {weak: true});

  api.use('raix:eventemitter@0.1.1', both);
  api.use('matb33:collection-hooks@0.7.13', both);
  api.use('aldeed:collection2-core@1.2.0', both);
  api.use('meteorspark:util@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);
  api.use('meteorspark:json-sortify@0.1.0', both);
  api.use('ovcharik:jsdiff@2.0.1', both);
  api.use('justdoinc:justdo-helpers@1.0.0', both);

  api.addFiles('lib/globals.js', both);
  api.addFiles('lib/helpers.coffee', both);

  // GridDataCore
  api.addFiles('lib/grid-data-core/grid-data-core-client.coffee', client);
  api.addFiles('lib/grid-data-core/grid-data-core-errors.coffee', client);

  // GridData
  api.addFiles('lib/grid-data/grid-data.coffee', both);

  // GridDataCom
  api.addFiles('lib/grid-data-com/grid-data-com-client.coffee', client);
  api.addFiles('lib/grid-data-com/grid-data-com-server.coffee', server);
  api.addFiles('lib/grid-data-com/grid-data-com-server-api.coffee', server);

  api.addFiles('lib/errors-types.coffee', both);

  // Core data structures
  api.addFiles('lib/grid-data/data-structure-management/core-data-structures.coffee', client);

  // Load apis
  api.addFiles('lib/grid-data/api/core-api.coffee', client);
  api.addFiles('lib/grid-data/api/search.coffee', client);

  // Filters
  api.addFiles('lib/grid-data/data-structure-management/filters/filters.coffee', client);
  api.addFiles('lib/grid-data/data-structure-management/filters/filters-independent-items.coffee', client);

  // Items Types settings
  api.addFiles('lib/grid-data/data-structure-management/items-types/items-types.coffee', client);
  api.addFiles('lib/grid-data/data-structure-management/items-types/types-settings/section-item.coffee', client);

  // Grid Sections
  api.addFiles('lib/grid-data/data-structure-management/grid-sections/grid-sections.coffee', client);
  api.addFiles('lib/grid-data/data-structure-management/grid-sections/sections-managers/section-manager-proto.coffee', client);
  api.addFiles('lib/grid-data/data-structure-management/grid-sections/sections-managers/natural-collection-subtree.coffee', client);
  api.addFiles('lib/grid-data/data-structure-management/grid-sections/sections-managers/query.coffee', client);
  api.addFiles('lib/grid-data/data-structure-management/grid-sections/sections-managers/data-tree.coffee', client);
  api.addFiles('lib/grid-data/data-structure-management/grid-sections/sections-managers/detached-data-subtrees.coffee', client);

  // Metadata management
  api.addFiles('lib/grid-data/data-structure-management/metadata.coffee', client);

  // Collection operations
  api.addFiles('lib/grid-data/collection-operations/collection-operations.coffee', client);
  api.addFiles('lib/grid-data/collection-operations/hooks.coffee', client);

  api.export('GridDataCore');
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

  api.addFiles('lib/helpers.coffee', both);

  // Just so we can use it from the console for debugging...
  api.export('GridDataCore');
  api.export('GridData');
  api.export('GridDataCom');
  api.export('TestCol');
});
