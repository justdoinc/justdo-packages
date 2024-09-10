Package.describe({
  name: "justdoinc:justdo-projects-dashboard",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-projects-dashboard"
});

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
  //   }, 'justdoinc:justdo-projects-dashboard')
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

  api.use("matb33:collection-hooks@0.8.4", both);
  api.use("tap:i18n", both);
  api.use("justdoinc:justdo-i18n", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  api.addFiles("lib/both/analytics.coffee", both);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/static.coffee", both);
  api.addFiles("lib/both/errors-types.coffee", both);
  api.addFiles("lib/both/api.coffee", both);
  api.addFiles("lib/both/schemas.coffee", both);

  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/allow-deny.coffee", server);
  api.addFiles("lib/server/collections-hooks.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);

  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);

  api.addFiles("lib/client/project-conf/project-conf.sass", client);
  api.addFiles("lib/client/project-conf/project-conf.html", client);
  api.addFiles("lib/client/project-conf/project-conf.coffee", client);

  api.addFiles("lib/client/project-pane/dashboard.sass", client);
  api.addFiles("lib/client/project-pane/dashboard.html", client);
  api.addFiles("lib/client/project-pane/dashboard.coffee", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/both/app-integration.coffee", both);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file. 

  // Always after templates
  // project-pane
  api.addFiles([
    "i18n/project-pane/en.i18n.json",
    "i18n/project-pane/ar.i18n.json",
    "i18n/project-pane/es.i18n.json",
    "i18n/project-pane/fr.i18n.json",
    "i18n/project-pane/he.i18n.json",
    "i18n/project-pane/ja.i18n.json",
    "i18n/project-pane/km.i18n.json",
    "i18n/project-pane/ko.i18n.json",
    "i18n/project-pane/pt-PT.i18n.json",
    "i18n/project-pane/pt-BR.i18n.json",
    "i18n/project-pane/vi.i18n.json",
    "i18n/project-pane/ru.i18n.json",
    "i18n/project-pane/yi.i18n.json",
    "i18n/project-pane/it.i18n.json",
    "i18n/project-pane/de.i18n.json",
    "i18n/project-pane/hi.i18n.json",
    "i18n/project-pane/tr.i18n.json",
    "i18n/project-pane/el.i18n.json",
    "i18n/project-pane/da.i18n.json",
    "i18n/project-pane/fi.i18n.json",
    "i18n/project-pane/nl.i18n.json",
    "i18n/project-pane/sv.i18n.json",
    "i18n/project-pane/th.i18n.json",
    "i18n/project-pane/id.i18n.json",
    "i18n/project-pane/pl.i18n.json",
    "i18n/project-pane/cs.i18n.json",
    "i18n/project-pane/hu.i18n.json",
    "i18n/project-pane/ro.i18n.json",
    "i18n/project-pane/sk.i18n.json",
    "i18n/project-pane/uk.i18n.json",
    "i18n/project-pane/bg.i18n.json",
    "i18n/project-pane/hr.i18n.json",
    "i18n/project-pane/sr.i18n.json",
    "i18n/project-pane/sl.i18n.json",
    "i18n/project-pane/et.i18n.json",
    "i18n/project-pane/lv.i18n.json",
    "i18n/project-pane/lt.i18n.json",
    "i18n/project-pane/am.i18n.json",
    "i18n/project-pane/zh-CN.i18n.json",
    "i18n/project-pane/zh-TW.i18n.json",
    "i18n/project-pane/sw.i18n.json",
    "i18n/project-pane/af.i18n.json",
    "i18n/project-pane/az.i18n.json",
    "i18n/project-pane/be.i18n.json",
    "i18n/project-pane/bn.i18n.json",
    "i18n/project-pane/bs.i18n.json",
    "i18n/project-pane/ca.i18n.json",
    "i18n/project-pane/eu.i18n.json",
    "i18n/project-pane/lb.i18n.json",
    "i18n/project-pane/mk.i18n.json",
    "i18n/project-pane/ne.i18n.json",
    "i18n/project-pane/nb.i18n.json",
    "i18n/project-pane/sq.i18n.json",
    "i18n/project-pane/ta.i18n.json",
    "i18n/project-pane/uz.i18n.json",
    "i18n/project-pane/hy.i18n.json",
    "i18n/project-pane/kk.i18n.json",
    "i18n/project-pane/ky.i18n.json",
    "i18n/project-pane/ms.i18n.json",
    "i18n/project-pane/tg.i18n.json"
  ], both);

  api.export("JustdoProjectsDashboard", both);
});
