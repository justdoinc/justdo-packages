Package.describe({
  name: 'stem-capital:grid-control-search',
  summary: 'Search component for the stem-capital:grid-control package',
  version: '0.1.0'
});

both = ['server', 'client'];
server = 'server';
client = 'client';

Package.onUse(function (api) {
  api.versionsFrom('1.1.0.2');

  api.use('coffeescript', both);
  api.use('check', both);
  api.use('tracker', both);

  api.use('stevezhu:lodash@4.16.4', both);
  api.use('twbs:bootstrap@3.3.5', both);
  api.use('raix:eventemitter@0.1.1', both);
  api.use('meteorspark:util@0.1.0', both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);

  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);
  api.use('stem-capital:grid-control', client);
  api.use('mizzao:jquery-ui@1.11.4', client);
  api.use('fortawesome:fontawesome@4.4.0', client);
  api.use("tap:i18n", both);
  api.use('justdoinc:justdo-i18n@1.0.0', both);

  api.addFiles('lib/globals.js', both);

  api.addFiles('lib/client/grid_control_search.sass', client);
  api.addFiles('lib/client/grid_control_search.coffee', client);

  api.addFiles('lib/client/static.coffee', client);

  api.addFiles('lib/client/grid-control-search-dropdown.html', client);
  api.addFiles('lib/client/grid-control-search-dropdown.sass', client);
  api.addFiles('lib/client/grid-control-search-dropdown.coffee', client);

  // i18n
  this.addI18nFiles(api, "i18n/{}.i18n.json");

  api.export('GridControlSearch');
});
