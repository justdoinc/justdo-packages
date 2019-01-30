Package.describe({
  name: 'amitli:generic-slider',
  version: '0.0.1',
  summary: ''
});

both = ['server', 'client'];
server = 'server';
client = 'client';

Package.onUse(function(api) {
  api.versionsFrom('1.1.0.2');

  api.use("justdoinc:justdo-color-gradient@1.0.0", client);

  api.addFiles('generic-slider.js', client);
  api.export('genericSlider', client);
});
