Package.describe({
  name: 'stem-capital:grid-data-seeder',
  summary: '',
  version: '0.1.0'
});

both = ['server', 'client'];
server = 'server';
client = 'client';

Package.onUse(function (api) {
  api.use('coffeescript', both);
  api.use('underscore', both);
  api.use('tracker', both);
  api.use('mongo', both);
  api.use('accounts-password', both);

  api.addFiles('lib/globals.js', both);
  api.addFiles('lib/server.coffee', server);

  api.export('gridDataSeeder', server);
});

Package.onTest(function(api) {
  api.versionsFrom('1.1.0.2');

  api.use('tinytest', both);
  api.use('coffeescript', both);

  api.use('mongo', both);
  api.use('accounts-password', both);

  api.use('stem-capital:grid-data-seeder', both);

  api.addFiles('unittest/server.coffee', server);
});
