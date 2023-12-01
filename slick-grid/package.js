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
  api.use('fourseven:scss@3.2.0', client);
  api.use('meteorspark:logger@0.3.0', both);
  api.use('meteorspark:json-sortify@0.1.0', both);
  api.use('underscore', both);

  api.addFiles('slick.grid.scss', client);
  api.addFiles('lib/jquery.event.drag-2.2.js', client);
  api.addFiles('slick.core.js', client);
  api.addFiles('plugins/slick.cellrangedecorator.js', client);
  api.addFiles('plugins/slick.cellrangeselector.js', client);
  api.addFiles('plugins/slick.cellselectionmodel.js', client);
  api.addFiles('plugins/slick.rowselectionmodel.js', client);
  api.addFiles('slick.formatters.js', client);
  api.addFiles('slick.editors.js', client);
  api.addFiles('slick.grid.js', client);

  api.export('SlickGrid');
});
