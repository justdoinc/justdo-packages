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

  api.export('GridControlSearch');
});
