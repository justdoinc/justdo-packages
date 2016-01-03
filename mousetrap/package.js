Package.describe({
  name: 'justdo:mousetrap',
  summary: '',
  version: '0.1.0'
});

both = ['server', 'client'];
server = 'server';
client = 'client';

version = "1.5.3"

Package.onUse(function (api) {
  api.versionsFrom('1.1.0.2');

  api.use('meteorspark:logger@0.3.0', both);

  api.add_files('mousetrap-v' + version + '/mousetrap.js', client);

  api.export('Mousetrap');
});
