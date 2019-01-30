Package.describe({
  name: "justdoinc:meetings-manager-plugin",
  version: "1.0.0",
  summary: "Integrate meetings manager into justdo app",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/meetings-manager-plugin"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);

  api.use("stevezhu:lodash@4.17.2", both);
  api.use('fourseven:scss@3.2.0', client);
  api.use("templating", client);

  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("justdoinc:meetings-manager", both);

  api.use("reactive-var", both);
  api.use("tracker", client);
  api.use("jquery", client);
  api.use("useful:forms", client);
  api.use('copleykj:jquery-autosize@1.17.8', client);

  api.addFiles("lib/both/01_underscore.js", both);

  api.addFiles("lib/both/init.coffee", both);
  api.addFiles("lib/both/errors-types.coffee", both);
  api.addFiles("lib/both/api.coffee", both);
  api.addFiles("lib/both/schemas.coffee", both);

  api.addFiles("lib/server/init.coffee", server);
  api.addFiles("lib/server/api.coffee", server);
  api.addFiles("lib/server/allow-deny.coffee", server);
  api.addFiles("lib/server/collections-hooks.coffee", server);
  api.addFiles("lib/server/collections-indexes.coffee", server);
  api.addFiles("lib/server/methods.coffee", server);
  api.addFiles("lib/server/publications.coffee", server);


  api.addFiles("lib/client/templates/_shared.html", client);
  api.addFiles("lib/client/templates/_shared.coffee", client);

  api.addFiles("lib/client/templates/meetings-meeting-header.html", client);
  api.addFiles("lib/client/templates/meetings-meeting-header.sass", client);
  api.addFiles("lib/client/templates/meetings-meeting-header.coffee", client);

  api.addFiles("lib/client/templates/meetings-menu-template.html", client);
  api.addFiles("lib/client/templates/meetings-menu-template.sass", client);
  api.addFiles("lib/client/templates/meetings-menu-template.coffee", client);

  api.addFiles("lib/client/templates/meeting-dialog-template.html", client);
  api.addFiles("lib/client/templates/meeting-dialog-template.sass", client);
  api.addFiles("lib/client/templates/meeting-dialog-template.coffee", client);

  api.addFiles("lib/client/templates/meetings-dialog-task-template.html", client);
  api.addFiles("lib/client/templates/meetings-dialog-task-template.sass", client);
  api.addFiles("lib/client/templates/meetings-dialog-task-template.coffee", client);

  api.addFiles("lib/client/templates/meetings-meeting-members.html", client);
  // api.addFiles("lib/client/templates/meetings-meeting-members.css", client);
  api.addFiles("lib/client/templates/meetings-meeting-members.coffee", client);

  api.addFiles("lib/client/templates/section-container-template.html", client);
  api.addFiles("lib/client/templates/section-container-template.sass", client);
  api.addFiles("lib/client/templates/section-container-template.coffee", client);

  api.addFiles("lib/client/templates/section-template.html", client);
  api.addFiles("lib/client/templates/section-template.sass", client);
  api.addFiles("lib/client/templates/section-template.coffee", client);

  api.addFiles("lib/client/editor/editor.html", client);
  api.addFiles("lib/client/editor/editor.sass", client);
  api.addFiles("lib/client/editor/editor.coffee", client);

  api.addFiles("lib/client/task-pane-extensions.coffee", client);

  api.addFiles("lib/client/init.coffee", client);
  api.addFiles("lib/client/api.coffee", client);
  api.addFiles("lib/client/methods.coffee", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/both/app-integration.coffee", both);
  // // Note: app-integration need to load last, so immediateInit procedures in
  // // the server will have the access to the apis loaded after the init.coffee
  // // file.

  // for project configuration
  api.addFiles("lib/client/templates/meetings-config.html" , client);
  api.addFiles("lib/client/templates/meetings-config.sass" , client);
  api.addFiles("lib/client/templates/meetings-config.coffee" , client);

  // Media
  api.addAssets("media/icons.png", client);

  api.export("MeetingsManagerPlugin", both);
});
