Package.describe({
  name: 'stem-capital:grid-data-seeder',
  summary: '',
  version: '0.1.0'
});

both = ['server', 'client'];
server = 'server';
client = 'client';

Package.onUse(function (api) {
  api.versionsFrom('0.9.4');

  api.use('coffeescript', both);
  api.use('underscore', both);
  api.use('tracker', both);
  api.use('mongo', both);
  api.use('accounts-password', both);

  api.add_files('lib/globals.js', both);
  api.add_files('lib/server.coffee', server);

  api.export('gridDataSeeder', server);
});

Package.onTest(function(api) {
  api.versionsFrom('METEOR@0.9.4');

  api.use('tinytest', both);
  api.use('coffeescript', both);

  api.use('mongo', both);
  api.use('accounts-password', both);

  api.use('stem-capital:grid-data-seeder', both);

  api.add_files('unittest/server.coffee', server);
});
