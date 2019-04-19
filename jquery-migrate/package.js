Package.describe({
  name: "justdoinc:jquery-migrate",
  version: '1.0.0'
});

Package.onUse(function (api) {
  api.addFiles('mute.js', 'client');
  api.addFiles('jquery-migrate.js', 'client');
});
