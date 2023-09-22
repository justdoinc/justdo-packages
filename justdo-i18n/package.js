Package.describe({
  name: "justdoinc:justdo-i18n",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-i18n"
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
  api.use("justdoinc:justdo-promoters-campaigns@1.0.0", both, {weak: true});
  api.use("tap:i18n@1.8.2", both);
  // Although we prefer tap:i18n, anti:i18n is used by other packages like meteor-accounts-ui-bootstrap-3
  api.use("anti:i18n@0.4.3", client, {weak: true}); 

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

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

  api.addFiles("lib/client/top-banner/top-banner.sass", client);
  api.addFiles("lib/client/top-banner/top-banner.html", client);
  api.addFiles("lib/client/top-banner/top-banner.coffee", client);

  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);

  // Always after templates
  api.add_files("i18n/en.i18n.json", both);
  api.add_files("i18n/vi.i18n.json", both);
  api.add_files("i18n/justdo-i18n.en.i18n.json", both);
  api.add_files("i18n/justdo-i18n.vi.i18n.json", both);
  api.add_files("i18n/errors/errors.en.i18n.json", both);
  api.add_files("i18n/errors/errors.vi.i18n.json", both);
  api.add_files("i18n/header/header.en.i18n.json", both);
  api.add_files("i18n/header/header.vi.i18n.json", both);
  api.add_files("i18n/loader/loader.en.i18n.json", both);
  api.add_files("i18n/loader/loader.vi.i18n.json", both);
  api.add_files("i18n/login-page/login-page.en.i18n.json", both);
  api.add_files("i18n/login-page/login-page.vi.i18n.json", both);
  api.add_files("i18n/menu/menu.en.i18n.json", both);
  api.add_files("i18n/menu/menu.vi.i18n.json", both);
  api.add_files("i18n/title/title.en.i18n.json", both);
  api.add_files("i18n/title/title.vi.i18n.json", both);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/both/app-integration.coffee", both);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file. 

  api.export("JustdoI18n", both);
});
