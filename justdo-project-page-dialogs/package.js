Package.describe({
  name: "justdoinc:justdo-project-page-dialogs",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-project-page-dialogs"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);

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

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", client);

  api.use("reactive-var", client);
  api.use("tracker", client);

  api.use('justdoinc:justdo-snackbar@1.0.0', client);

  api.addFiles("lib/both/analytics.coffee", both);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", client);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", client);
  // // Note: app-integration need to load last, so immediateInit procedures in
  // // the server will have the access to the apis loaded after the init.coffee
  // // file. 

  api.addFiles("lib/client/init.coffee", client);

  api.addFiles("lib/client/users-diff-confirmation.html", client);
  api.addFiles("lib/client/users-diff-confirmation.sass", client);
  api.addFiles("lib/client/users-diff-confirmation.coffee", client);

  api.addFiles("lib/client/members-management-dialog.html", client);
  api.addFiles("lib/client/members-management-dialog.coffee", client);
  api.addFiles("lib/client/members-management-dialog.sass", client);

  api.addFiles("lib/client/add-member-to-current-project.html", client);
  api.addFiles("lib/client/add-member-to-current-project.coffee", client);
  api.addFiles("lib/client/add-member-to-current-project.sass", client);

  api.addFiles("lib/client/change-email-dialog.html", client);
  api.addFiles("lib/client/change-email-dialog.sass", client);
  api.addFiles("lib/client/change-email-dialog.coffee", client);

  api.addFiles("lib/client/select-project-user.html", client);
  api.addFiles("lib/client/select-project-user.sass", client);
  api.addFiles("lib/client/select-project-user.coffee", client);

  api.addFiles("lib/client/select-multiple-project-users.html", client);
  api.addFiles("lib/client/select-multiple-project-users.sass", client);
  api.addFiles("lib/client/select-multiple-project-users.coffee", client);

  api.addFiles("lib/client/confirm-edit-members-dialog.html", client);
  api.addFiles("lib/client/confirm-edit-members-dialog.sass", client);
  api.addFiles("lib/client/confirm-edit-members-dialog.coffee", client);

  api.addFiles("lib/client/member-list-widget.html", client);
  api.addFiles("lib/client/member-list-widget.sass", client);
  api.addFiles("lib/client/member-list-widget.coffee", client);

  api.addFiles("lib/client/tasks-list-widget.html", client);
  api.addFiles("lib/client/tasks-list-widget.sass", client);
  api.addFiles("lib/client/tasks-list-widget.coffee", client);

  api.addFiles("lib/client/members-multi-selector-widget.html", client);
  api.addFiles("lib/client/members-multi-selector-widget.sass", client);
  api.addFiles("lib/client/members-multi-selector-widget.coffee", client);

  api.addFiles("lib/client/project-context-tooltip.html", client);
  api.addFiles("lib/client/project-context-tooltip.coffee", client);
  api.addFiles("lib/client/project-context-tooltip.sass", client);
  
  api.export("ProjectPageDialogs", client);
});
