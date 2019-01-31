Package.describe({
  name: "justdo:timesync",
  summary: "NTP-style time synchronization between server and client",
  version: "0.3.4",
  git: "https://github.com/mizzao/meteor-timesync.git"
});

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.2");

  api.use([
    'check',
    'templating',
    'tracker',
    'http',
    'jquery',
    'reactive-var'
  ], 'client');

  api.use('webapp', 'server');

  api.use('fourseven:scss@3.2.0', client);

  // Our files
  api.addFiles('timesync-server.js', 'server');
  api.addFiles('templates/timesync-status.sass', 'client');
  api.addFiles('templates/timesync-status.html', 'client');
  api.addFiles('timesync-client.js', 'client');

  api.export('TimeSync', 'client');
  api.export('SyncInternals', 'client', {testOnly: true} );
});

Package.onTest(function (api) {
  api.use([
    'tinytest',
    'test-helpers'
  ]);

  api.use(["tracker", "underscore"], 'client');

  api.use("mizzao:timesync");

  api.addFiles('tests/client.js', 'client');
});
