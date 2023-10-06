Package.describe({
  name: "justdoinc:justdo-projects-templates",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-projects-templates"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("check", both);
  api.use("mongo", both);

  // api.use("stevezhu:lodash@4.17.2", both);
  // api.use("templating", client);
  // api.use('fourseven:scss@3.2.0', client);

  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("aldeed:simple-schema@1.5.3", both);
  api.use('aldeed:collection2@2.3.2', both);
  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);
  api.use("iron:router@1.1.2", both);
  api.use("justdoinc:jd-api@1.0.0", both);
  api.use("tap:i18n@1.8.2", both);
  api.use("justdoinc:justdo-i18n@1.0.0", both);

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/static.coffee", both);
  api.addFiles("lib/both/errors-types.coffee", both);
  api.addFiles("lib/both/api.coffee", both);
  api.addFiles("lib/both/schemas.coffee", both);

  api.addFiles("lib/server/init.coffee", server);
  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/collections-hooks.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);

  api.addFiles("lib/client/init.coffee", client);
  api.addFiles("lib/client/project-template-from-category-selector/project-template-from-category-selector.sass", client);
  api.addFiles("lib/client/project-template-from-category-selector/project-template-from-category-selector.html", client);
  api.addFiles("lib/client/project-template-from-category-selector/project-template-from-category-selector.coffee", client);
  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);

  api.addFiles("lib/client/project-template-from-category-selector/demo-html-template/demo-html-template.sass", client);
  api.addFiles("lib/client/project-template-from-category-selector/demo-html-template/demo-html-template.html", client);
  api.addFiles("lib/client/project-template-from-category-selector/demo-html-template/demo-html-template.coffee", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user1.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user2.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user3.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user4.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user5.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user6.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user7.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user8.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user9.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user10.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user11.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user12.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user13.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user14.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user15.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user16.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user17.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user18.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user19.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user20.jpg", client);
  api.addAssets("lib/client/project-template-from-category-selector/demo-html-template/assets/user21.jpg", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  // api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/both/app-integration.coffee", both);
  // // Note: app-integration need to load last, so immediateInit procedures in
  // // the server will have the access to the apis loaded after the init.coffee
  // // file.

  //
  // Core templates
  //

  // Blank
  api.addFiles("lib/core-templates-categories/blank/blank.coffee", both)

  // Always after templates
  api.add_files("i18n/en.i18n.json", both);
  api.add_files("i18n/vi.i18n.json", both);

  api.export("JustDoProjectsTemplates", both);
});
