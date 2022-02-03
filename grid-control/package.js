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
  api.use('tracker', both);
  api.use('minimongo', both);

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

  api.use("justdoinc:justdo-linkify", client);

  api.use('justdoinc:justdo-avatar@1.0.0', client);
  api.use('justdoinc:justdo-helpers@1.0.0', both);

  api.use('justdoinc:justdo-snackbar@1.0.0', client);

  api.use("justdoinc:justdo-mathjs@1.0.0", both);

  api.add_files('lib/globals.js', both);

  api.add_files('lib/both/helpers.coffee', both);
  api.add_files('lib/both/simple_schema_extensions.coffee', both);

  api.add_files('lib/client/grid_control.coffee', client);
  api.add_files('lib/client/grid_control-static-methods.coffee', client);
  api.add_files('lib/client/errors_types.coffee', client);
  api.add_files('lib/client/grid_control.sass', client);

  api.addAssets('lib/client/media/cell-handle.png', client);
  api.addAssets('lib/client/media/loader.gif', client);

  // Operations
  api.add_files('lib/client/grid_operations/init.coffee', client);
  api.add_files('lib/client/grid_operations/operations_lock.coffee', client);
  api.add_files('lib/client/grid_operations/operations_prereq.coffee', client);
  api.add_files('lib/client/grid_operations/operations/add.coffee', client);
  api.add_files('lib/client/grid_operations/operations/move.coffee', client);
  api.add_files('lib/client/grid_operations/operations/remove.coffee', client);
  api.add_files('lib/client/grid_operations/operations/sort.coffee', client);

  // Plugins
  api.add_files('lib/client/plugins/init.coffee', client);
  api.add_files('lib/client/plugins/items_sortable/items_sortable.sass', client);
  api.add_files('lib/client/plugins/items_sortable/sortable_ext.coffee', client);
  api.add_files('lib/client/plugins/items_sortable/items_sortable.coffee', client);
  api.add_files('lib/client/plugins/grid_bound_element/grid_bound_element.coffee', client);
  api.add_files('lib/client/plugins/grid_views/main.coffee', client);
  api.add_files('lib/client/plugins/grid_views/filters/filters.coffee', client);
  api.add_files('lib/client/plugins/grid_views/filters/filters.sass', client);
  api.add_files('lib/client/plugins/grid_views/filters/filters_dom.coffee', client);
  api.add_files('lib/client/plugins/grid_views/filters/filters_dom.sass', client);
  api.add_files('lib/client/plugins/grid_views/filters/filters_controllers/whitelist.coffee', client);
  api.add_files('lib/client/plugins/grid_views/filters/filters_controllers/whitelist.sass', client);
  api.add_files('lib/client/plugins/grid_views/filters/filters_controllers/numeric.coffee', client);
  api.add_files('lib/client/plugins/grid_views/filters/filters_controllers/numeric.sass', client);
  api.add_files('lib/client/plugins/grid_views/columns_reordering.coffee', client);
  api.add_files('lib/client/plugins/grid_views/columns_context_menu.coffee', client);
  api.add_files('lib/client/plugins/cell_editing_timeout/cell_editing_timeout.coffee', client);
  api.add_files('lib/client/plugins/collapse_all/collapse_all.sass', client);
  api.add_files('lib/client/plugins/collapse_all/collapse_all.coffee', client);
  api.add_files('lib/client/plugins/multi_select/multi_select.sass', client);
  api.add_files('lib/client/plugins/multi_select/multi_select.coffee', client);

  // jquery_events
  api.add_files('lib/client/jquery_events/init.coffee', client);
  api.add_files('lib/client/jquery_events/destroy_editor_on_blur.coffee', client);
  api.add_files('lib/client/jquery_events/activate_on_click.coffee', client);

  // Formatters & Editors
  api.add_files('lib/client/formatters-and-editors/common-fomatters-and-editors.sass', client);
  api.add_files('lib/client/formatters-and-editors/formatters-init.coffee', client);
  api.add_files('lib/client/formatters-and-editors/editors-init.coffee', client);

  api.add_files('lib/client/formatters-and-editors/tags-field/tags-field.coffee', client);
  api.add_files('lib/client/formatters-and-editors/tags-field/tags-field.sass', client);

  api.add_files('lib/client/formatters-and-editors/selector-editor/selector-editor.coffee', client);
  api.add_files('lib/client/formatters-and-editors/selector-editor/selector-editor.sass', client);

  api.add_files('lib/client/formatters-and-editors/textarea-editor/textarea-editor.coffee', client);
  api.add_files('lib/client/formatters-and-editors/textarea-editor/textarea-editor.sass', client);

  api.add_files('lib/client/formatters-and-editors/textarea-with-tree-controls/textarea-with-tree-controls-editor.coffee', client);
  api.add_files('lib/client/formatters-and-editors/textarea-with-tree-controls/textarea-with-tree-controls-editor.sass', client);
  api.add_files('lib/client/formatters-and-editors/textarea-with-tree-controls/text-with-tree-controls.coffee', client);
  api.add_files('lib/client/formatters-and-editors/textarea-with-tree-controls/text-with-tree-controls-events.coffee', client);
  api.add_files('lib/client/formatters-and-editors/textarea-with-tree-controls/text-with-tree-controls.sass', client);

  api.add_files('lib/client/formatters-and-editors/unicode-date/unicode-date.coffee', client);
  api.add_files('lib/client/formatters-and-editors/unicode-date/unicode-date.sass', client);
  api.addAssets('lib/client/formatters-and-editors/unicode-date/media/calendar.gif', client);

  api.add_files('lib/client/formatters-and-editors/calculated-field/calculated-field.coffee', client);
  api.add_files('lib/client/formatters-and-editors/calculated-field/calculated-field.sass', client);
  api.add_files('lib/client/formatters-and-editors/calculated-field/functions/common-filter-aware-tree-op-calculator-funcs.coffee', client);

  api.add_files('lib/client/formatters-and-editors/default-formatter/default-formatter.coffee', client);
  api.add_files('lib/client/formatters-and-editors/default-formatter/default-formatter.sass', client);
  api.add_files('lib/client/formatters-and-editors/default-formatter/extensions/status-field-formatter.coffee', client);

  api.add_files('lib/client/formatters-and-editors/key-value-formatter/key-value.coffee', client);

  api.add_files('lib/client/formatters-and-editors/datetime-formatter/datetime-formatter.coffee', client);
  api.add_files('lib/client/formatters-and-editors/datetime-formatter/datetime-formatter.sass', client);

  api.add_files('lib/client/formatters-and-editors/array-fields/array-fields.coffee', client);

  api.export('GridControl');
});
