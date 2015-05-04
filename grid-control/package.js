Package.describe({
  name: 'stem-capital:grid-control',
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
  api.use('check', both);
  api.use('meteor', both);

  api.use('aldeed:simple-schema@1.3.1', both);

  api.use('stem-capital:slick-grid', client);
  api.use('stem-capital:grid-data', client);

  api.use('raix:eventemitter@0.1.1', both);
  api.use('meteorspark:util@0.1.0', both);
  api.use('meteorspark:logger@0.3.0', both);
  api.use('fourseven:scss@=0.9.6', client);

  api.add_files('lib/globals.js', both);

  api.add_files('lib/both/simple_schema_extensions.coffee', both);

  api.add_files('lib/client/grid_control.coffee', client, {bare: true});
  api.add_files('lib/client/grid_control.sass', client);

  api.add_files('lib/client/media/cell-handle.png', client);

  // jquery_events
  api.add_files('lib/client/jquery_events/init.coffee', client, {bare: true});
  api.add_files('lib/client/jquery_events/destroy_editor_on_blur.coffee', client);
  api.add_files('lib/client/jquery_events/activate_row_on_click_on_row_handle.coffee', client);

  // Formatters
  api.add_files('lib/client/cells_formatters/init.coffee', client, {bare: true});
  api.add_files('lib/client/cells_formatters/default.coffee', client);
  api.add_files('lib/client/cells_formatters/text_with_tree_controls/text_with_tree_controls.sass', client);
  api.add_files('lib/client/cells_formatters/text_with_tree_controls/text_with_tree_controls.coffee', client);
  api.add_files('lib/client/cells_formatters/text_with_tree_controls/text_with_tree_controls_init.coffee', client);
  api.add_files('lib/client/cells_formatters/text_with_tree_controls/media/collapse.gif', client);
  api.add_files('lib/client/cells_formatters/text_with_tree_controls/media/expand.gif', client);

  // Editors 
  api.add_files('lib/client/cells_editors/init.coffee', client, {bare: true});
  api.add_files('lib/client/cells_editors/text_with_tree_controls_editor/text_with_tree_controls_editor.sass', client);
  api.add_files('lib/client/cells_editors/text_with_tree_controls_editor/text_with_tree_controls_editor.js', client);
  api.add_files('lib/client/cells_editors/text_with_tree_controls_editor/text_with_tree_controls_editor-jquery_events.coffee', client);

  // Operations Controllers 
  api.add_files('lib/client/operations_controllers/init.coffee', client, {bare: true});
  api.add_files('lib/client/operations_controllers/add_child/add_child.coffee', client);
  api.add_files('lib/client/operations_controllers/add_child/add_child.sass', client);
  api.add_files('lib/client/operations_controllers/add_sibling/add_sibling.coffee', client);
  api.add_files('lib/client/operations_controllers/add_sibling/add_sibling.sass', client);
  api.add_files('lib/client/operations_controllers/remove_parent/remove_parent.coffee', client);
  api.add_files('lib/client/operations_controllers/remove_parent/remove_parent.sass', client);

  api.export('GridControl');
});

Package.onTest(function(api) {
  api.versionsFrom('1.1.0.2');

  api.use('tinytest', both);
  api.use('coffeescript', both);
  api.use('mongo', both);
  api.use('tracker', both);
  api.use('meteorspark:test-helpers@0.2.0', both);

  api.use('stem-capital:slick-grid', client);
  api.use('stem-capital:grid-data-seeder', server);
  api.use('stem-capital:grid-data', client);
  api.use('stem-capital:grid-control', both);

  api.addFiles('unittest/setup/both.coffee', client, {bare: true});
  api.addFiles('unittest/setup/both.coffee', server);
  api.addFiles('unittest/setup/server.coffee', server);
  api.addFiles('unittest/setup/client.coffee', client);
  api.addFiles('unittest/client.coffee', client);

  // Just so we can use it from the console for debugging...
  api.export('GridControl');
  api.export('TestCol');
});
