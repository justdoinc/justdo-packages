Package.describe({
  name: "justdoinc:justdo-site-admins",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-site-admins"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
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
  //   }, 'justdoinc:justdo-site-admins')
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
  api.use("justdoinc:justdo-tasks-collections-manager@1.0.0", both, {weak: true});
  api.use("justdoinc:justdo-accounts@1.0.0", both);
  api.use("justdoinc:jd-api", both);

  api.use("iron:router@1.1.2", both);
  api.use("random", both);

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("check", both);
  api.use("reactive-var", both);
  api.use("reactive-dict", both);
  api.use("tap:i18n", both);
  api.use("justdoinc:justdo-i18n", both);
  api.use("http", server);
  api.use("tracker", client);

  api.use("justdoinc:justdo-db-migrations@1.0.0", both);

  api.addFiles("lib/both/analytics.coffee", both);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/static.coffee", both);
  api.addFiles("lib/both/router.coffee", both);
  api.addFiles("lib/both/errors-types.coffee", both);
  api.addFiles("lib/both/api.coffee", both);
  api.addFiles("lib/both/schemas.coffee", both);

  api.addFiles("lib/server/db-migrations/clear-server-vitals-log.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);
  api.addFiles("lib/server/usage-stats.coffee", server);
  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);

  api.addFiles("lib/client/global-template-helpers.coffee", client);
  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);

  api.addFiles("lib/client/license-info/drawer-license-info/drawer-license-info.sass", client);
  api.addFiles("lib/client/license-info/drawer-license-info/drawer-license-info.html", client);
  api.addFiles("lib/client/license-info/drawer-license-info/drawer-license-info.coffee", client);

  api.addFiles("lib/client/license-info/license-info-modal/license-info-modal.sass", client);
  api.addFiles("lib/client/license-info/license-info-modal/license-info-modal.html", client);
  api.addFiles("lib/client/license-info/license-info-modal/license-info-modal.coffee", client);

  api.addFiles("lib/client/plugin-page/plugin-page.sass", client);
  api.addFiles("lib/client/plugin-page/plugin-page.html", client);
  api.addFiles("lib/client/plugin-page/plugin-page.coffee", client);

  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/menu-item/menu-item.sass", client);
  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/menu-item/menu-item.html", client);
  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/menu-item/menu-item.coffee", client);

  api.addFiles("lib/client/plugin-page/plugin-page-non-site-admin/plugin-page-non-site-admin.sass", client);
  api.addFiles("lib/client/plugin-page/plugin-page-non-site-admin/plugin-page-non-site-admin.html", client);
  api.addFiles("lib/client/plugin-page/plugin-page-non-site-admin/plugin-page-non-site-admin.coffee", client);

  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/plugin-page-site-admin.sass", client);
  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/plugin-page-site-admin.html", client);
  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/plugin-page-site-admin.coffee", client);

  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/plugin-page-site-admin-members/plugin-page-site-admin-members.sass", client);
  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/plugin-page-site-admin-members/plugin-page-site-admin-members.html", client);
  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/plugin-page-site-admin-members/plugin-page-site-admin-members.coffee", client);

  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/plugin-page-site-admin-members/plugin-page-site-admin-user-dropdown.sass", client);
  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/plugin-page-site-admin-members/plugin-page-site-admin-user-dropdown.html", client);
  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/plugin-page-site-admin-members/plugin-page-site-admin-user-dropdown.coffee", client);

  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/plugin-page-site-admin-server-vitals/plugin-page-site-admin-server-vitals.sass", client);
  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/plugin-page-site-admin-server-vitals/plugin-page-site-admin-server-vitals.html", client);
  api.addFiles("lib/client/plugin-page/plugin-page-site-admin/plugin-page-site-admin-server-vitals/plugin-page-site-admin-server-vitals.coffee", client);

  api.addFiles("lib/modules/admins-list-public/admins-list-public-both.coffee", both);
  api.addFiles("lib/modules/admins-list-public/admins-list-public-client.coffee", client);
  api.addFiles("lib/modules/admins-list-public/admins-list-public-server.coffee", server);

  api.addFiles("lib/modules/proxy-users/proxy-users-both.coffee", both);
  api.addFiles("lib/modules/proxy-users/proxy-users-client.coffee", client);
  api.addFiles("lib/modules/proxy-users/proxy-users-server.coffee", server);
  api.addFiles("lib/modules/proxy-users/members-page-dropdown-option/proxy-user-dropdown-option.html", client);
  api.addFiles("lib/modules/proxy-users/members-page-dropdown-option/proxy-user-dropdown-option.coffee", client);
  api.addFiles("lib/modules/proxy-users/members-page-edit-proxy-user-dropdown-option/members-page-edit-proxy-user-dropdown-option.html", client);
  api.addFiles("lib/modules/proxy-users/members-page-edit-proxy-user-dropdown-option/members-page-edit-proxy-user-dropdown-option.coffee", client);
  api.addFiles("lib/modules/proxy-users/members-page-edit-proxy-user-avatar-dropdown-option/members-page-edit-proxy-user-avatar-dropdown-option.html", client);
  api.addFiles("lib/modules/proxy-users/members-page-edit-proxy-user-avatar-dropdown-option/members-page-edit-proxy-user-avatar-dropdown-option.coffee", client);
  
  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/both/app-integration.coffee", both);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file.

  // Always after templates
  this.addI18nFiles(api, "i18n/license-info/{}.i18n.json");

  api.export("JustdoSiteAdmins", both);
});
