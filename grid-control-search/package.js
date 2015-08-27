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
  api.use('erasaur:meteor-lodash', both);
  api.use('check', both);

  api.use('raix:eventemitter@0.1.1', both);
  api.use('meteorspark:util@0.1.0', both);

  api.use('fourseven:scss@3.2.0', client);
  api.use('stem-capital:grid-control', client);

  api.add_files('lib/globals.js', both);

  api.add_files('lib/client/grid_control_search.coffee', client);
  api.add_files('lib/client/grid_control_search.sass', client);

  api.add_files('lib/client/media/search_ui_component.png', client);
  api.add_files('lib/client/media/clear_button.png', client);
  api.add_files('lib/client/media/next_result.png', client);
  api.add_files('lib/client/media/prev_result.png', client);
});
