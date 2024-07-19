Package.describe({
  name: "justdoinc:justdo-i18n",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-i18n"
});

Npm.depends({
  "excel4node": "1.8.2"
})

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("mongo", both);

  // Uncomment if you want to use NPM peer dependencies using
  // checkNpmVersions.
  //
  // Introducing new NPM packages procedure:
  //
  // * Uncomment the lines below.
  // * Add your packages to the main web-app package.json dependencies section.
  // * Call $ meteor npm install
  // * Call $ meteor npm shrinkwrap
  //
  // Add to the peer dependencies checks to one of the JS/Coffee files of your package,
  // Example:
  //
  //   import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"
  //
  //   checkNpmVersions({
  //     'colors': '1.1.x'
  //   }, 'justdoinc:justdo-i18n')
  // api.use("ecmascript", both);
  // api.use("tmeasday:check-npm-versions@0.3.1", both);

  // api.use("stevezhu:lodash@4.17.2", both);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("aldeed:simple-schema@1.5.3", both);
  api.use('aldeed:collection2@2.3.2', both);
  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);
  api.use("iron:router@1.1.2", both);

  api.use("justdoinc:justdo-analytics@1.0.0", both);
  api.use("tap:i18n", both);
  api.use("momentjs:moment", both);
  api.use("rzymek:moment-locales", both);
  // Although we prefer tap:i18n, anti:i18n is used by other packages like meteor-accounts-ui-bootstrap-3
  api.use("anti:i18n@0.4.3", client, {weak: true}); 

  api.use("matb33:collection-hooks@0.8.4", both);
  api.use("meteorspark:app@0.3.0", both);

  api.use("reactive-var", both);
  api.use("tracker", client);
  api.use("astrocoders:handlebars-server@1.0.3", server);
  api.use("webapp", server);
  api.use("check", server)

  api.addFiles("lib/both/analytics.coffee", both);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/static.coffee", both);
  api.addFiles("lib/both/router.coffee", both);
  api.addFiles("lib/both/errors-types.coffee", both);
  api.addFiles("lib/both/api.coffee", both);
  api.addFiles("lib/both/schemas.coffee", both);

  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/collections-hooks.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);

  api.addFiles("lib/client/modal-button-label/modal-button-label.html", client);

  api.addFiles("lib/client/lang-selector-dropdown/lang-selector-dropdown.sass", client);
  api.addFiles("lib/client/lang-selector-dropdown/lang-selector-dropdown.html", client);
  api.addFiles("lib/client/lang-selector-dropdown/lang-selector-dropdown.coffee", client);
  api.addFiles("lib/client/lang-selector-dropdown/user-preference-lang-selector.html", client);
  api.addFiles("lib/client/lang-selector-dropdown/user-preference-lang-selector.coffee", client);

  api.addFiles("lib/client/top-banner/top-banner.sass", client);
  api.addFiles("lib/client/top-banner/top-banner.html", client);
  api.addFiles("lib/client/top-banner/top-banner.coffee", client);

  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);
  
  // Always after templates
  // common
  api.addFiles([
    "i18n/common/en.i18n.json",
    "i18n/common/ar.i18n.json",
    "i18n/common/es.i18n.json",
    "i18n/common/fr.i18n.json",
    "i18n/common/he.i18n.json",
    "i18n/common/ja.i18n.json",
    "i18n/common/km.i18n.json",
    "i18n/common/ko.i18n.json",
    "i18n/common/pt-PT.i18n.json",
    "i18n/common/pt-BR.i18n.json",
    "i18n/common/vi.i18n.json",
    "i18n/common/ru.i18n.json",
    "i18n/common/yi.i18n.json",
    "i18n/common/it.i18n.json",
    "i18n/common/de.i18n.json",
    "i18n/common/hi.i18n.json",
    "i18n/common/tr.i18n.json",
    "i18n/common/el.i18n.json",
    "i18n/common/da.i18n.json",
    "i18n/common/fi.i18n.json",
    "i18n/common/nl.i18n.json",
    "i18n/common/sv.i18n.json",
    "i18n/common/th.i18n.json",
    "i18n/common/id.i18n.json",
    "i18n/common/pl.i18n.json",
    "i18n/common/cs.i18n.json",
    "i18n/common/hu.i18n.json",
    "i18n/common/ro.i18n.json",
    "i18n/common/sk.i18n.json",
    "i18n/common/uk.i18n.json",
    "i18n/common/bg.i18n.json",
    "i18n/common/hr.i18n.json",
    "i18n/common/sr.i18n.json",
    "i18n/common/sl.i18n.json",
    "i18n/common/et.i18n.json",
    "i18n/common/lv.i18n.json",
    "i18n/common/lt.i18n.json",
    "i18n/common/am.i18n.json",
    "i18n/common/zh-CN.i18n.json",
    "i18n/common/zh-TW.i18n.json",
    "i18n/common/sw.i18n.json",
    "i18n/common/af.i18n.json",
    "i18n/common/az.i18n.json",
    "i18n/common/be.i18n.json",
    "i18n/common/bn.i18n.json",
    "i18n/common/bs.i18n.json",
    "i18n/common/ca.i18n.json",
    "i18n/common/eu.i18n.json",
    "i18n/common/lb.i18n.json",
    "i18n/common/mk.i18n.json",
    "i18n/common/ne.i18n.json",
    "i18n/common/nb.i18n.json",
    "i18n/common/sq.i18n.json",
    "i18n/common/ta.i18n.json",
    "i18n/common/uz.i18n.json",
    "i18n/common/hy.i18n.json",
    "i18n/common/kk.i18n.json",
    "i18n/common/ky.i18n.json",
    "i18n/common/ms.i18n.json",
    "i18n/common/tg.i18n.json"
  ], both);

  // loader
  api.addFiles([
    "i18n/loader/loader.en.i18n.json",
    "i18n/loader/loader.ar.i18n.json",
    "i18n/loader/loader.es.i18n.json",
    "i18n/loader/loader.fr.i18n.json",
    "i18n/loader/loader.he.i18n.json",
    "i18n/loader/loader.ja.i18n.json",
    "i18n/loader/loader.km.i18n.json",
    "i18n/loader/loader.ko.i18n.json",
    "i18n/loader/loader.pt-PT.i18n.json",
    "i18n/loader/loader.pt-BR.i18n.json",
    "i18n/loader/loader.vi.i18n.json",
    "i18n/loader/loader.ru.i18n.json",
    "i18n/loader/loader.yi.i18n.json",
    "i18n/loader/loader.it.i18n.json",
    "i18n/loader/loader.de.i18n.json",
    "i18n/loader/loader.hi.i18n.json",
    "i18n/loader/loader.tr.i18n.json",
    "i18n/loader/loader.el.i18n.json",
    "i18n/loader/loader.da.i18n.json",
    "i18n/loader/loader.fi.i18n.json",
    "i18n/loader/loader.nl.i18n.json",
    "i18n/loader/loader.sv.i18n.json",
    "i18n/loader/loader.th.i18n.json",
    "i18n/loader/loader.id.i18n.json",
    "i18n/loader/loader.pl.i18n.json",
    "i18n/loader/loader.cs.i18n.json",
    "i18n/loader/loader.hu.i18n.json",
    "i18n/loader/loader.ro.i18n.json",
    "i18n/loader/loader.sk.i18n.json",
    "i18n/loader/loader.uk.i18n.json",
    "i18n/loader/loader.bg.i18n.json",
    "i18n/loader/loader.hr.i18n.json",
    "i18n/loader/loader.sr.i18n.json",
    "i18n/loader/loader.sl.i18n.json",
    "i18n/loader/loader.et.i18n.json",
    "i18n/loader/loader.lv.i18n.json",
    "i18n/loader/loader.lt.i18n.json",
    "i18n/loader/loader.am.i18n.json",
    "i18n/loader/loader.zh-CN.i18n.json",
    "i18n/loader/loader.zh-TW.i18n.json",
    "i18n/loader/loader.sw.i18n.json",
    "i18n/loader/loader.af.i18n.json",
    "i18n/loader/loader.az.i18n.json",
    "i18n/loader/loader.be.i18n.json",
    "i18n/loader/loader.bn.i18n.json",
    "i18n/loader/loader.bs.i18n.json",
    "i18n/loader/loader.ca.i18n.json",
    "i18n/loader/loader.eu.i18n.json",
    "i18n/loader/loader.lb.i18n.json",
    "i18n/loader/loader.mk.i18n.json",
    "i18n/loader/loader.ne.i18n.json",
    "i18n/loader/loader.nb.i18n.json",
    "i18n/loader/loader.sq.i18n.json",
    "i18n/loader/loader.ta.i18n.json",
    "i18n/loader/loader.uz.i18n.json",
    "i18n/loader/loader.hy.i18n.json",
    "i18n/loader/loader.kk.i18n.json",
    "i18n/loader/loader.ky.i18n.json",
    "i18n/loader/loader.ms.i18n.json",
    "i18n/loader/loader.tg.i18n.json"
  ], both);

  // title
  api.addFiles([
    "i18n/title/title.en.i18n.json",
    "i18n/title/title.ar.i18n.json",
    "i18n/title/title.es.i18n.json",
    "i18n/title/title.fr.i18n.json",
    "i18n/title/title.he.i18n.json",
    "i18n/title/title.ja.i18n.json",
    "i18n/title/title.km.i18n.json",
    "i18n/title/title.ko.i18n.json",
    "i18n/title/title.pt-PT.i18n.json",
    "i18n/title/title.pt-BR.i18n.json",
    "i18n/title/title.vi.i18n.json",
    "i18n/title/title.ru.i18n.json",
    "i18n/title/title.yi.i18n.json",
    "i18n/title/title.it.i18n.json",
    "i18n/title/title.de.i18n.json",
    "i18n/title/title.hi.i18n.json",
    "i18n/title/title.tr.i18n.json",
    "i18n/title/title.el.i18n.json",
    "i18n/title/title.da.i18n.json",
    "i18n/title/title.fi.i18n.json",
    "i18n/title/title.nl.i18n.json",
    "i18n/title/title.sv.i18n.json",
    "i18n/title/title.th.i18n.json",
    "i18n/title/title.id.i18n.json",
    "i18n/title/title.pl.i18n.json",
    "i18n/title/title.cs.i18n.json",
    "i18n/title/title.hu.i18n.json",
    "i18n/title/title.ro.i18n.json",
    "i18n/title/title.sk.i18n.json",
    "i18n/title/title.uk.i18n.json",
    "i18n/title/title.bg.i18n.json",
    "i18n/title/title.hr.i18n.json",
    "i18n/title/title.sr.i18n.json",
    "i18n/title/title.sl.i18n.json",
    "i18n/title/title.et.i18n.json",
    "i18n/title/title.lv.i18n.json",
    "i18n/title/title.lt.i18n.json",
    "i18n/title/title.am.i18n.json",
    "i18n/title/title.zh-CN.i18n.json",
    "i18n/title/title.zh-TW.i18n.json",
    "i18n/title/title.sw.i18n.json",
    "i18n/title/title.af.i18n.json",
    "i18n/title/title.az.i18n.json",
    "i18n/title/title.be.i18n.json",
    "i18n/title/title.bn.i18n.json",
    "i18n/title/title.bs.i18n.json",
    "i18n/title/title.ca.i18n.json",
    "i18n/title/title.eu.i18n.json",
    "i18n/title/title.lb.i18n.json",
    "i18n/title/title.mk.i18n.json",
    "i18n/title/title.ne.i18n.json",
    "i18n/title/title.nb.i18n.json",
    "i18n/title/title.sq.i18n.json",
    "i18n/title/title.ta.i18n.json",
    "i18n/title/title.uz.i18n.json",
    "i18n/title/title.hy.i18n.json",
    "i18n/title/title.kk.i18n.json",
    "i18n/title/title.ky.i18n.json",
    "i18n/title/title.ms.i18n.json",
    "i18n/title/title.tg.i18n.json"
  ], both);


  // justdo-i18n
  api.addFiles([
    "i18n/justdo-i18n/justdo-i18n.en.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ar.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.es.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.fr.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.he.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ja.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.km.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ko.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.pt-PT.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.pt-BR.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.vi.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ru.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.yi.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.it.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.de.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.hi.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.tr.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.el.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.da.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.fi.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.nl.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.sv.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.th.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.id.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.pl.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.cs.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.hu.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ro.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.sk.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.uk.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.bg.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.hr.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.sr.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.sl.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.et.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.lv.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.lt.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.am.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.zh-CN.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.zh-TW.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.sw.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.af.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.az.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.be.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.bn.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.bs.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ca.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.eu.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.lb.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.mk.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ne.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.nb.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.sq.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ta.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.uz.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.hy.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.kk.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ky.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.ms.i18n.json",
    "i18n/justdo-i18n/justdo-i18n.tg.i18n.json"
  ], both);

  api.addFiles("lib/both/app-integration.coffee", both);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file. 

  api.export("JustdoI18n", both);
});
