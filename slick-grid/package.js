Package.describe({
  name: 'stem-capital:slick-grid',
  summary: '',
  version: '0.1.0'
});

both = ['server', 'client'];
server = 'server';
client = 'client';

Package.onUse(function (api) {
  api.versionsFrom('1.1.0.2');

  api.use('mizzao:jquery-ui', client);

  api.add_files('slick.grid.css', client);
  api.add_files('lib/jquery.event.drag-2.2.js', client);
  api.add_files('slick.core.js', client);
  api.add_files('plugins/slick.cellrangedecorator.js', client);
  api.add_files('plugins/slick.cellrangeselector.js', client);
  api.add_files('plugins/slick.cellselectionmodel.js', client);
  api.add_files('plugins/slick.rowselectionmodel.js', client);
  api.add_files('slick.formatters.js', client);
  api.add_files('slick.editors.js', client);
  api.add_files('slick.grid.js', client);

  api.export('SlickGrid');
});
