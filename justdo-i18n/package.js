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
  this.addI18nFiles(api, "i18n/common/{}.i18n.json");

  // loader
  this.addI18nFiles(api, "i18n/loader/loader.{}.i18n.json");

  // title
  this.addI18nFiles(api, "i18n/title/title.{}.i18n.json");

  // files
  this.addI18nFiles(api, "i18n/files/{}.i18n.json");

  // justdo-i18n
  this.addI18nFiles(api, "i18n/justdo-i18n/justdo-i18n.{}.i18n.json");

  api.addFiles("lib/both/app-integration.coffee", both);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file. 

  api.export("JustdoI18n", both);
});
