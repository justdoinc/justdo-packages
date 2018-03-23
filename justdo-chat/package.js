Package.describe({
  name: "justdoinc:justdo-chat",
  version: "1.0.0",
  summary: "",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-chat"
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

  // api.use("stevezhu:lodash@4.17.2", both);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use('copleykj:jquery-autosize@1.17.8', client);

  api.use("aldeed:simple-schema@1.5.3", both);
  api.use('aldeed:collection2@2.3.2', both);
  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);

  api.use("justdoinc:justdo-bottom-windows-wireframe@1.0.0", client);
  
  api.use("stem-capital:projects@0.1.0", both);

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("lbee:moment-helpers", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  //
  // JustDo Chat Bottom windows
  //
  api.addFiles("lib/justdo-chat-bottom-windows-manager/justdo-chat-bottom-windows-manager.coffee", client);    

  //
  // JustDo Chat
  //

  // Both
  api.addFiles("lib/justdo-chat/both/analytics.coffee", both);

  api.addFiles("lib/justdo-chat/both/init.coffee", both);
  api.addFiles("lib/justdo-chat/both/static-settings.coffee", both);
  api.addFiles("lib/justdo-chat/both/static-channel-registrar.coffee", both);
  api.addFiles("lib/justdo-chat/both/schemas.coffee", both);
  api.addFiles("lib/justdo-chat/both/errors-types.coffee", both);
  api.addFiles("lib/justdo-chat/both/api.coffee", both);

  // Server
  api.addFiles("lib/justdo-chat/server/static-channel-registrar.coffee", server);
  api.addFiles("lib/justdo-chat/server/api.coffee", server);
  api.addFiles("lib/justdo-chat/server/allow-deny.coffee", server);
  api.addFiles("lib/justdo-chat/server/collections-hooks.coffee", server);
  api.addFiles("lib/justdo-chat/server/collections-indexes.coffee", server);
  api.addFiles("lib/justdo-chat/server/methods.coffee", server);
  api.addFiles("lib/justdo-chat/server/publications.coffee", server);


  // Client
  api.addFiles("lib/justdo-chat/client/api.coffee", client);
  api.addFiles("lib/justdo-chat/client/methods.coffee", client);
  api.addFiles("lib/justdo-chat/client/pseudo-collections.coffee", client);
  api.addFiles("lib/justdo-chat/client/subscriptions.coffee", client);

  //
  // Channels
  //

  // Base
  api.addFiles("lib/channels/channel-base-client.coffee", client);
  api.addFiles("lib/channels/channel-base-server.coffee", server);

  // Task
  api.addFiles("lib/channels/task/task-channel-both-register.coffee", both);
  api.addFiles("lib/channels/task/task-channel-client-constructor.coffee", client);
  api.addFiles("lib/channels/task/task-channel-server-constructor.coffee", server);
  api.addFiles("lib/channels/task/task-channel-server-register.coffee", server);

  //
  // UI
  //

  // Common components

  api.addFiles("lib/ui/common-components/vars.scss", client);

  // Message editor
  api.addFiles("lib/ui/common-components/message-editor/message-editor.sass", client);
  api.addFiles("lib/ui/common-components/message-editor/message-editor.html", client);
  api.addFiles("lib/ui/common-components/message-editor/message-editor.coffee", client);

  // Message board
  api.addFiles("lib/ui/common-components/messages-board/messages-board.sass", client);
  api.addFiles("lib/ui/common-components/messages-board/messages-board.html", client);
  api.addFiles("lib/ui/common-components/messages-board/messages-board.coffee", client);

  // Tasks channel
  api.addFiles("lib/ui/channels/task/tasks-channels-ui/task-pane-details-section/vars.scss", client);

  api.addFiles("lib/ui/channels/task/tasks-channels-ui/task-pane-details-section/chat-mode/chat-mode.sass", client);
  api.addFiles("lib/ui/channels/task/tasks-channels-ui/task-pane-details-section/chat-mode/chat-mode.html", client);
  api.addFiles("lib/ui/channels/task/tasks-channels-ui/task-pane-details-section/chat-mode/chat-mode.coffee", client);

  api.addFiles("lib/ui/channels/task/tasks-channels-ui/task-pane-details-section/subscribers-management-mode/subscribers-management-mode.sass", client);
  api.addFiles("lib/ui/channels/task/tasks-channels-ui/task-pane-details-section/subscribers-management-mode/subscribers-management-mode.html", client);
  api.addFiles("lib/ui/channels/task/tasks-channels-ui/task-pane-details-section/subscribers-management-mode/subscribers-management-mode.coffee", client);

  api.addFiles("lib/ui/channels/task/tasks-channels-ui/task-pane-details-section/chat-section.sass", client);
  api.addFiles("lib/ui/channels/task/tasks-channels-ui/task-pane-details-section/chat-section.html", client);
  api.addFiles("lib/ui/channels/task/tasks-channels-ui/task-pane-details-section/chat-section.coffee", client);

  // Recent channels activity
  api.addFiles("lib/ui/recent-activity-dropdown/recent-activity-dropdown/tasks-channels-items/tasks-channels-items.sass", client);
  api.addFiles("lib/ui/recent-activity-dropdown/recent-activity-dropdown/tasks-channels-items/tasks-channels-items.html", client);
  api.addFiles("lib/ui/recent-activity-dropdown/recent-activity-dropdown/tasks-channels-items/tasks-channels-items.coffee", client);
  api.addFiles("lib/ui/recent-activity-dropdown/recent-activity-dropdown/recent-activity-dropdown.sass", client);
  api.addFiles("lib/ui/recent-activity-dropdown/recent-activity-dropdown/recent-activity-dropdown.html", client);
  api.addFiles("lib/ui/recent-activity-dropdown/recent-activity-dropdown/recent-activity-dropdown.coffee", client);
  api.addFiles("lib/ui/recent-activity-dropdown/recent-activity-button.sass", client);
  api.addFiles("lib/ui/recent-activity-dropdown/recent-activity-button.html", client);
  api.addFiles("lib/ui/recent-activity-dropdown/recent-activity-button.coffee", client);

  // Bottom windows
  api.addFiles("lib/ui/bottom-windows/extra-windows-button.html", client);
  api.addFiles("lib/ui/bottom-windows/extra-windows-button.sass", client);
  api.addFiles("lib/ui/bottom-windows/extra-windows-button.coffee", client);

  api.addFiles("lib/ui/bottom-windows/task/vars.scss", client);
  api.addFiles("lib/ui/bottom-windows/task/common.sass", client);
  api.addFiles("lib/ui/bottom-windows/task/common.coffee", client);

  api.addFiles("lib/ui/bottom-windows/task/task-minimized.sass", client);
  api.addFiles("lib/ui/bottom-windows/task/task-minimized.html", client);
  api.addFiles("lib/ui/bottom-windows/task/task-minimized.coffee", client);

  api.addFiles("lib/ui/bottom-windows/task/task-open.sass", client);
  api.addFiles("lib/ui/bottom-windows/task/task-open.html", client);
  api.addFiles("lib/ui/bottom-windows/task/task-open.coffee", client);

  //
  // Project Conf
  //

  api.addFiles("lib/project-conf/justdo-chat-project-config.sass", client);
  api.addFiles("lib/project-conf/justdo-chat-project-config.html", client);
  api.addFiles("lib/project-conf/justdo-chat-project-config.coffee", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  api.addFiles("lib/justdo-chat/both/app-integration.coffee", both);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file. 

  //
  // Assets
  //

  api.addAssets("media/notification.ogg", client);

  api.export("JustdoChat", both);
});
