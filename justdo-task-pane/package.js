// Do not use this package as example for how packages in
// JustDo should look like, refer to README.md to read more

Package.describe({
  name: "justdoinc:justdo-task-pane",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-task-pane"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.5.1");

  api.use("coffeescript", both);
  api.use("underscore", client);
  api.use("ecmascript", both);

  api.use("froala:editor@2.9.5", both);

  // api.use("stevezhu:lodash@4.17.2", client);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("raix:eventemitter@0.1.1", client);
  api.use("meteorspark:util@0.2.0", client);
  api.use("meteorspark:logger@0.3.0", client);
  api.use("justdoinc:justdo-helpers@1.0.0", client);

  api.use("matb33:collection-hooks@0.8.4", client);

  api.use("justdoinc:justdo-project-page-dialogs@1.0.0", client);

  api.use("reactive-var", client);
  api.use("tracker", client);
  api.use("iron:router@1.1.2", server);

  //
  // Core API
  //

  api.addFiles("lib/both/static.js", both);

  api.addFiles("lib/client/toolbar-sections-api.coffee", client);
  api.addFiles("lib/client/template-helpers.coffee", client);
  api.addFiles("lib/client/builtin-sections-to-item-types.coffee", client);

  //
  // task pane layout templates
  //

  api.addFiles("lib/client/templates/task-pane.html", client);
  api.addFiles("lib/client/templates/task-pane.coffee", client);
  api.addFiles("lib/client/templates/task-pane.sass", client);
  api.addFiles("lib/client/templates/task-pane-resize-token.sass", client);

  api.addFiles("lib/client/templates/task-pane-header/task-pane-header.html", client);
  api.addFiles("lib/client/templates/task-pane-header/task-pane-header.coffee", client);
  api.addFiles("lib/client/templates/task-pane-header/task-pane-header.sass", client);

  api.addFiles("lib/client/templates/task-pane-header/task-pane-header-settings/task-pane-header-settings.html", client);
  api.addFiles("lib/client/templates/task-pane-header/task-pane-header-settings/task-pane-header-settings.coffee", client);
  api.addFiles("lib/client/templates/task-pane-header/task-pane-header-settings/task-pane-header-settings.sass", client);

  api.addFiles("lib/client/templates/task-pane-section-content/task-pane-section-content.html", client);
  api.addFiles("lib/client/templates/task-pane-section-content/task-pane-section-content.coffee", client);
  api.addFiles("lib/client/templates/task-pane-section-content/task-pane-section-content.sass", client);

  //
  // Builtin sections
  //

  // Item details

  api.addFiles("lib/client/builtin-sections/item-details/item-details.html", client);
  api.addFiles("lib/client/builtin-sections/item-details/item-details.coffee", client);
  api.addFiles("lib/client/builtin-sections/item-details/item-details.sass", client);

  api.addFiles("lib/client/builtin-sections/item-details/item-details-members/item-details-members.html", client);
  api.addFiles("lib/client/builtin-sections/item-details/item-details-members/item-details-members.coffee", client);
  api.addFiles("lib/client/builtin-sections/item-details/item-details-members/item-details-members.sass", client);

  api.addFiles("lib/client/builtin-sections/item-details/item-details-description/item-details-description.html", client);
  api.addFiles("lib/client/builtin-sections/item-details/item-details-description/item-details-description.coffee", client);
  api.addFiles("lib/client/builtin-sections/item-details/item-details-description/item-details-description.sass", client);
 
  api.addFiles("lib/client/builtin-sections/item-details/item-details-context/item-details-context.html", client);
  api.addFiles("lib/client/builtin-sections/item-details/item-details-context/item-details-context.sass", client);
  api.addFiles("lib/client/builtin-sections/item-details/item-details-context/item-details-context.coffee", client);

  api.addFiles("lib/client/builtin-sections/item-details/item-details-additional-fields/item-details-additional-fields.html", client);
  api.addFiles("lib/client/builtin-sections/item-details/item-details-additional-fields/item-details-additional-fields.sass", client);
  api.addFiles("lib/client/builtin-sections/item-details/item-details-additional-fields/item-details-additional-fields.coffee", client);

  // Changelog

  api.addFiles("lib/client/builtin-sections/change-log/change-log.html", client);
  api.addFiles("lib/client/builtin-sections/change-log/change-log.coffee", client);

  // Item settings

  api.addFiles("lib/client/builtin-sections/item-settings/item-settings.html", client);
  api.addFiles("lib/client/builtin-sections/item-settings/item-settings.coffee", client);
  api.addFiles("lib/client/builtin-sections/item-settings/parent-tasks/parent-tasks.html", client);
  api.addFiles("lib/client/builtin-sections/item-settings/parent-tasks/parent-tasks.sass", client);
  api.addFiles("lib/client/builtin-sections/item-settings/parent-tasks/parent-tasks.coffee", client);
  api.addFiles("lib/client/builtin-sections/item-settings/tickets-queue/item-settings-tickets-queue.html", client);
  api.addFiles("lib/client/builtin-sections/item-settings/tickets-queue/item-settings-tickets-queue.coffee", client);
  api.addFiles("lib/client/builtin-sections/item-settings/notifications/item-settings-notifications.html", client);

  api.addFiles("lib/server/froala-file-upload.coffee", server);

  api.use("meteorspark:app@0.3.0", client);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", client);

  api.export("JustdoTaskPane", both);
});
