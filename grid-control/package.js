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
  api.use("tap:i18n", both);
  api.use('justdoinc:justdo-i18n@1.0.0', both);

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

  api.addFiles('lib/globals.js', both);

  api.addFiles('lib/both/helpers.coffee', both);
  api.addFiles('lib/both/simple_schema_extensions.coffee', both);

  api.addFiles('lib/client/grid_control.coffee', client);
  api.addFiles('lib/client/grid_control-static-methods.coffee', client);
  api.addFiles('lib/client/errors_types.coffee', client);
  api.addFiles('lib/client/grid_control.sass', client);

  api.addAssets('lib/client/media/cell-handle.png', client);
  api.addAssets('lib/client/media/loader.gif', client);

  // Operations
  api.addFiles('lib/client/grid_operations/init.coffee', client);
  api.addFiles('lib/client/grid_operations/operations_lock.coffee', client);
  api.addFiles('lib/client/grid_operations/operations_prereq.coffee', client);
  api.addFiles('lib/client/grid_operations/operations/add.coffee', client);
  api.addFiles('lib/client/grid_operations/operations/move.coffee', client);
  api.addFiles('lib/client/grid_operations/operations/remove.coffee', client);
  api.addFiles('lib/client/grid_operations/operations/sort.coffee', client);

  // Plugins
  api.addFiles('lib/client/plugins/init.coffee', client);
  api.addFiles('lib/client/plugins/items_sortable/items_sortable.sass', client);
  api.addFiles('lib/client/plugins/items_sortable/sortable_ext.coffee', client);
  api.addFiles('lib/client/plugins/items_sortable/items_sortable.coffee', client);
  api.addFiles('lib/client/plugins/grid_bound_element/grid_bound_element.coffee', client);
  api.addFiles('lib/client/plugins/grid_views/init.coffee', client);
  api.addFiles('lib/client/plugins/grid_views/filters/filters.coffee', client);
  api.addFiles('lib/client/plugins/grid_views/filters/filters.sass', client);
  api.addFiles('lib/client/plugins/grid_views/filters/filters_dom.coffee', client);
  api.addFiles('lib/client/plugins/grid_views/filters/filters_dom.sass', client);
  api.addFiles('lib/client/plugins/grid_views/filters/filters_controllers/custom-where-clause-filter.coffee', client);
  api.addFiles('lib/client/plugins/grid_views/filters/filters_controllers/whitelist.coffee', client);
  api.addFiles('lib/client/plugins/grid_views/filters/filters_controllers/whitelist.sass', client);
  api.addFiles('lib/client/plugins/grid_views/filters/filters_controllers/numeric.coffee', client);
  api.addFiles('lib/client/plugins/grid_views/filters/filters_controllers/numeric.sass', client);
  api.addFiles('lib/client/plugins/grid_views/filters/filters_controllers/unicode-dates-filter.coffee', client);
  api.addFiles('lib/client/plugins/grid_views/filters/filters_controllers/unicode-dates-filter.sass', client);
  api.addFiles('lib/client/plugins/grid_views/filters/filters_controllers/unicode-dates-custom-where-clause-filter.coffee', client);
  api.addFiles('lib/client/plugins/grid_views/filters/filters_controllers/numeric-custom-where-clause-filter.coffee', client);

  api.addFiles('lib/client/plugins/grid_views/columns_reordering.coffee', client);
  api.addFiles('lib/client/plugins/grid_views/columns_context_menu.coffee', client);
  api.addFiles('lib/client/plugins/cell_editing_timeout/cell_editing_timeout.coffee', client);
  api.addFiles('lib/client/plugins/collapse_all/collapse_all.sass', client);
  api.addFiles('lib/client/plugins/collapse_all/collapse_all.coffee', client);
  api.addFiles('lib/client/plugins/multi_select/multi_select.sass', client);
  api.addFiles('lib/client/plugins/multi_select/multi_select.coffee', client);

  // jquery_events
  api.addFiles('lib/client/jquery_events/init.coffee', client);
  api.addFiles('lib/client/jquery_events/destroy_editor_on_blur.coffee', client);
  api.addFiles('lib/client/jquery_events/activate_on_click.coffee', client);

  // Formatters & Editors
  api.addFiles('lib/client/formatters-and-editors/common-fomatters-and-editors.sass', client);
  api.addFiles('lib/client/formatters-and-editors/formatters-init.coffee', client);
  api.addFiles('lib/client/formatters-and-editors/editors-init.coffee', client);

  api.addFiles('lib/client/formatters-and-editors/tags-field/tags-field.coffee', client);
  api.addFiles('lib/client/formatters-and-editors/tags-field/tags-field.sass', client);

  api.addFiles('lib/client/formatters-and-editors/selector-editor/selector-editor.coffee', client);
  api.addFiles('lib/client/formatters-and-editors/selector-editor/selector-editor.sass', client);
  api.addFiles('lib/client/formatters-and-editors/multi-select/multi-select-editor.coffee', client);
  api.addFiles('lib/client/formatters-and-editors/multi-select/multi-select-editor.sass', client);
  api.addFiles('lib/client/formatters-and-editors/multi-select/multi-select-formatter.coffee', client);

  api.addFiles('lib/client/formatters-and-editors/textarea-editor/textarea-editor.coffee', client);
  api.addFiles('lib/client/formatters-and-editors/textarea-editor/textarea-editor.sass', client);

  api.addFiles('lib/client/formatters-and-editors/textarea-with-tree-controls/textarea-with-tree-controls-editor.coffee', client);
  api.addFiles('lib/client/formatters-and-editors/textarea-with-tree-controls/textarea-with-tree-controls-editor.sass', client);
  api.addFiles('lib/client/formatters-and-editors/textarea-with-tree-controls/text-with-tree-controls.coffee', client);
  api.addFiles('lib/client/formatters-and-editors/textarea-with-tree-controls/text-with-tree-controls-events.coffee', client);
  api.addFiles('lib/client/formatters-and-editors/textarea-with-tree-controls/text-with-tree-controls.sass', client);

  api.addFiles('lib/client/formatters-and-editors/unicode-date/unicode-date.coffee', client);
  api.addFiles('lib/client/formatters-and-editors/unicode-date/unicode-date.sass', client);
  api.addAssets('lib/client/formatters-and-editors/unicode-date/media/calendar.gif', client);

  api.addFiles('lib/client/formatters-and-editors/calculated-field/calculated-field.coffee', client);
  api.addFiles('lib/client/formatters-and-editors/calculated-field/calculated-field.sass', client);
  api.addFiles('lib/client/formatters-and-editors/calculated-field/functions/common-filter-aware-tree-op-calculator-funcs.coffee', client);

  api.addFiles('lib/client/formatters-and-editors/default-formatter/default-formatter.coffee', client);
  api.addFiles('lib/client/formatters-and-editors/default-formatter/default-formatter.sass', client);
  api.addFiles('lib/client/formatters-and-editors/default-formatter/extensions/status-field-formatter.coffee', client);

  api.addFiles('lib/client/formatters-and-editors/key-value-formatter/key-value.coffee', client);

  api.addFiles('lib/client/formatters-and-editors/datetime-formatter/datetime-formatter.coffee', client);
  api.addFiles('lib/client/formatters-and-editors/datetime-formatter/datetime-formatter.sass', client);

  api.addFiles('lib/client/formatters-and-editors/array-fields/array-fields.coffee', client);

  // Always after templates
  api.addFiles([
    "i18n/en.i18n.json",
    "i18n/ar.i18n.json",
    "i18n/es.i18n.json",
    "i18n/fr.i18n.json",
    "i18n/he.i18n.json",
    "i18n/ja.i18n.json",
    "i18n/km.i18n.json",
    "i18n/ko.i18n.json",
    "i18n/pt-PT.i18n.json",
    "i18n/pt-BR.i18n.json",
    "i18n/vi.i18n.json",
    "i18n/ru.i18n.json",
    "i18n/yi.i18n.json",
    "i18n/it.i18n.json",
    "i18n/de.i18n.json",
    "i18n/hi.i18n.json",
    "i18n/tr.i18n.json",
    "i18n/el.i18n.json",
    "i18n/da.i18n.json",
    "i18n/fi.i18n.json",
    "i18n/nl.i18n.json",
    "i18n/sv.i18n.json",
    "i18n/th.i18n.json",
    "i18n/id.i18n.json",
    "i18n/pl.i18n.json",
    "i18n/cs.i18n.json",
    "i18n/hu.i18n.json",
    "i18n/ro.i18n.json",
    "i18n/sk.i18n.json",
    "i18n/uk.i18n.json",
    "i18n/bg.i18n.json",
    "i18n/hr.i18n.json",
    "i18n/sr.i18n.json",
    "i18n/sl.i18n.json",
    "i18n/et.i18n.json",
    "i18n/lv.i18n.json",
    "i18n/lt.i18n.json",
    "i18n/am.i18n.json",
    "i18n/zh-CN.i18n.json",
    "i18n/zh-TW.i18n.json",
    "i18n/sw.i18n.json",
    "i18n/af.i18n.json",
    "i18n/az.i18n.json",
    "i18n/be.i18n.json",
    "i18n/bn.i18n.json",
    "i18n/bs.i18n.json",
    "i18n/ca.i18n.json",
    "i18n/eu.i18n.json",
    "i18n/lb.i18n.json",
    "i18n/mk.i18n.json",
    "i18n/ne.i18n.json",
    "i18n/nb.i18n.json",
    "i18n/sq.i18n.json",
    "i18n/ta.i18n.json",
    "i18n/uz.i18n.json",
    "i18n/hy.i18n.json",
    "i18n/kk.i18n.json",
    "i18n/ky.i18n.json",
    "i18n/ms.i18n.json",
    "i18n/tg.i18n.json"
  ], both);

  api.export('GridControl');
});
