Package.describe({
  name: "justdoinc:grid-control-custom-fields",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/grid-control-custom-fields"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.5.1");

  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("check", both);

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
  // Add to the peer dependencies checks to one of the JS files of your package,
  // Example:
  //
  //   import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"
  //
  //   checkNpmVersions({
  //     'colors': '1.1.x'
  //   }, 'justdoinc:justdo-analytics')
  // api.use("ecmascript", both);
  // api.use("tmeasday:check-npm-versions@0.3.1", both);

  // api.use("stevezhu:lodash@4.17.2", client);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("raix:eventemitter@0.1.1", client);
  api.use("meteorspark:util@0.2.0", client);
  api.use("meteorspark:logger@0.3.0", client);
  api.use("justdoinc:justdo-helpers@1.0.0", client);

  api.use("justdoinc:justdo-color-picker-dropdown@1.0.0", client);

  api.use("aldeed:simple-schema@1.3.1", both);

  api.use("matb33:collection-hooks@0.8.4", client);

  api.use("stem-capital:grid-control", client);
  api.use("tap:i18n", both);
  api.use("justdoinc:justdo-i18n", both);

  api.use("reactive-var", client);
  api.use("tracker", both);

  api.addFiles("lib/both/grid-control-custom-fields/grid-control-custom-fields.coffee", both);
  api.addFiles("lib/both/simple-schema-extensions.coffee", both);

  api.addFiles("lib/client/grid-control-custom-fields-manager/init.coffee", client);
  api.addFiles("lib/client/grid-control-custom-fields-manager/static.coffee", client);
  api.addFiles("lib/client/grid-control-custom-fields-manager/errors-types.coffee", client);
  api.addFiles("lib/client/grid-control-custom-fields-manager/api.coffee", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  // api.addFiles("lib/client/app-integration.coffee", client);
  // // Note: app-integration need to load last, so immediateInit procedures in
  // // the server will have the access to the apis loaded after the init.coffee
  // // file.

  api.addFiles("lib/client/project-config/select-options-editor/select-options-editor.coffee", client);
  api.addFiles("lib/client/project-config/select-options-editor/select-options-editor.sass", client);
  api.addFiles("lib/client/project-config/select-options-editor/select-options-editor.html", client);

  api.addFiles("lib/client/project-config/project-config.coffee", client);
  api.addFiles("lib/client/project-config/project-config.sass", client);
  api.addFiles("lib/client/project-config/project-config.html", client);

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

  api.export("GridControlCustomFields", both);
  api.export("GridControlCustomFieldsManager", client);
});
