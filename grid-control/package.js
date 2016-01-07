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

  api.use('twbs:bootstrap@3.3.5', both);
  api.use('mizzao:jquery-ui@1.11.4', both);
  api.use('stemcapital:bootstrap3-select@1.1.0', both);

  api.use('aldeed:simple-schema@1.3.1', both);

  api.use('copleykj:jquery-autosize@1.17.8', client);

  api.use('momentjs:moment@2.10.3', both);

  api.use('stem-capital:slick-grid', client);
  api.use('stem-capital:grid-data', client);

  api.use('raix:eventemitter@0.1.1', both);
  api.use('meteorspark:util@0.1.0', both);
  api.use('meteorspark:logger@0.3.0', both);
  api.use('fourseven:scss@3.2.0', client);
  api.use('jchristman:context-menu@1.2.0', client);

  api.add_files('lib/globals.js', both);

  api.add_files('lib/both/helpers.coffee', both);
  api.add_files('lib/both/simple_schema_extensions.coffee', both);

  api.add_files('lib/client/grid_control.coffee', client, {bare: true});
  api.add_files('lib/client/errors_types.coffee', client);
  api.add_files('lib/client/grid_control.sass', client);

  api.add_files('lib/client/media/cell-handle.png', client);

  // Operations
  api.add_files('lib/client/grid_operations/init.coffee', client);
  api.add_files('lib/client/grid_operations/operations_lock.coffee', client);
  api.add_files('lib/client/grid_operations/operations_prereq.coffee', client);
  api.add_files('lib/client/grid_operations/operations/add.coffee', client);
  api.add_files('lib/client/grid_operations/operations/indent.coffee', client);
  api.add_files('lib/client/grid_operations/operations/move.coffee', client);
  api.add_files('lib/client/grid_operations/operations/remove.coffee', client);

  // Plugins
  api.add_files('lib/client/plugins/init.coffee', client);
  api.add_files('lib/client/plugins/items_sortable/items_sortable.sass', client);
  api.add_files('lib/client/plugins/items_sortable/sortable_ext.coffee', client);
  api.add_files('lib/client/plugins/items_sortable/items_sortable.coffee', client);
  api.add_files('lib/client/plugins/grid_views/main.coffee', client);
  api.add_files('lib/client/plugins/grid_views/filters/filters.coffee', client);
  api.add_files('lib/client/plugins/grid_views/filters/filters.sass', client);
  api.add_files('lib/client/plugins/grid_views/filters/filters_dom.coffee', client);
  api.add_files('lib/client/plugins/grid_views/filters/filters_dom.sass', client);
  api.add_files('lib/client/plugins/grid_views/filters/filters_controllers/whitelist.coffee', client);
  api.add_files('lib/client/plugins/grid_views/filters/filters_controllers/whitelist.sass', client);
  api.add_files('lib/client/plugins/grid_views/columns_reordering.coffee', client);
  api.add_files('lib/client/plugins/grid_views/columns_context_menu.coffee', client);

  // jquery_events
  api.add_files('lib/client/jquery_events/init.coffee', client, {bare: true});
  api.add_files('lib/client/jquery_events/destroy_editor_on_blur.coffee', client);
  api.add_files('lib/client/jquery_events/activate_row_on_click_on_row_handle.coffee', client);

  // Formatters
  api.add_files('lib/client/cells_formatters/tree_control_formatters.coffee', client, {bare: true});
  api.add_files('lib/client/cells_formatters/init.coffee', client, {bare: true});
  api.add_files('lib/client/cells_formatters/helpers.coffee', client);
  api.add_files('lib/client/cells_formatters/default/default.coffee', client);
  api.add_files('lib/client/cells_formatters/key_value/key_value.coffee', client);
  api.add_files('lib/client/cells_formatters/checkbox/checkbox.coffee', client);
  api.add_files('lib/client/cells_formatters/checkbox/checkbox-jquery_events.coffee', client);
  api.add_files('lib/client/cells_formatters/unicode_date/unicode_date.coffee', client);
  api.add_files('lib/client/cells_formatters/text_with_tree_controls/text_with_tree_controls.sass', client);
  api.add_files('lib/client/cells_formatters/text_with_tree_controls/text_with_tree_controls.coffee', client);
  api.add_files('lib/client/cells_formatters/text_with_tree_controls/text_with_tree_controls_init.coffee', client);
  api.add_files('lib/client/cells_formatters/text_with_tree_controls/text_with_tree_controls-jquery_events.coffee', client);
  api.add_files('lib/client/cells_formatters/text_with_tree_controls/media/collapse.gif', client);
  api.add_files('lib/client/cells_formatters/text_with_tree_controls/media/expand.gif', client);

  // Editors 
  api.add_files('lib/client/cells_editors/init.coffee', client, {bare: true});
  api.add_files('lib/client/cells_editors/helpers.coffee', client);
  api.add_files('lib/client/cells_editors/text_editor/text_editor.js', client);
  api.add_files('lib/client/cells_editors/text_editor/text_editor.sass', client);
  api.add_files('lib/client/cells_editors/checkbox_editor/checkbox_editor.js', client);
  api.add_files('lib/client/cells_editors/selector_editor/selector_editor.js', client);
  api.add_files('lib/client/cells_editors/selector_editor/selector_editor.sass', client);
  api.add_files('lib/client/cells_editors/text_with_tree_controls_editor/text_with_tree_controls_editor.sass', client);
  api.add_files('lib/client/cells_editors/text_with_tree_controls_editor/text_with_tree_controls_editor.js', client);
  api.add_files('lib/client/cells_editors/textarea_editor/textarea_editor.sass', client);
  api.add_files('lib/client/cells_editors/textarea_editor/textarea_editor.js', client);

  api.add_files('lib/client/cells_editors/textarea_with_tree_controls_editor/textarea_with_tree_controls_editor.sass', client);
  api.add_files('lib/client/cells_editors/textarea_with_tree_controls_editor/textarea_with_tree_controls_editor.js', client);

  api.add_files('lib/client/cells_editors/unicode_date/unicode_date.sass', client);
  api.add_files('lib/client/cells_editors/unicode_date/unicode_date.js', client);
  api.add_files('lib/client/cells_editors/unicode_date/media/calendar.gif', client);

  api.export('GridControl');
});

Package.onTest(function(api) {
  api.versionsFrom('1.1.0.2');

  api.use('tinytest', both);
  api.use('coffeescript', both);
  api.use('mongo', both);
  api.use('tracker', both);
  api.use('meteorspark:test-helpers@0.2.0', both);
  api.use('meteorspark:logger@0.3.0', both);

  api.use('aldeed:simple-schema@1.3.1', both);
  api.use('aldeed:collection2@2.3.2', both);

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
