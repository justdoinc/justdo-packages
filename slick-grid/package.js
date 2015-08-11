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
  api.use('fourseven:scss@=0.9.6', client);
  api.use('meteorspark:logger@0.3.0', both);
  api.use('underscore', both);

  api.add_files('slick.grid.scss', client);
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
