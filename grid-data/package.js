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
  api.use('meteorspark:util@0.1.0', both);
  api.use('meteorspark:logger@0.3.0', both);
  api.use('ovcharik:jsdiff@2.0.1', both);

  api.add_files('lib/globals.js', both);
  api.add_files('lib/helpers.coffee', both);
  api.add_files('lib/exceptions.coffee', both);
  api.add_files('lib/client.coffee', client, {bare: true});
  api.add_files('lib/hooks.coffee', client);
  api.add_files('lib/server.coffee', server);

  api.export('GridData');
  api.export('initDefaultGridServerSideConf');
  api.export('subscribeDefaultGridSubscription');
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
  api.export('TestCol');
});
