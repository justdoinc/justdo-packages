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
  api.use("ecmascript", both);
  // api.use("tmeasday:check-npm-versions@0.3.1", both);

  // api.use("stevezhu:lodash@4.17.2", both);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("justdoinc:justdo-push-notifications@1.0.0", server);

  api.use('copleykj:jquery-autosize@1.17.8', client);

  api.use("aldeed:simple-schema@1.5.3", both);
  api.use('aldeed:collection2@2.3.2', both);
  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);
  api.use("tap:i18n", both);

  api.use("justdoinc:justdo-bottom-windows-wireframe@1.0.0", client);
  
  api.use("stem-capital:projects@0.1.0", both);

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.use("justdoinc:justdo-accounts@1.0.0", both);

  api.use("justdoinc:justdo-jobs-processor@1.0.0", server);

  api.use("matb33:collection-hooks@0.8.4", both);

  api.use("justdoinc:justdo-linkify", client);
  api.use("justdoinc:jd-api", both);

  api.use("reactive-var", both);
  api.use("tracker", both);

  api.use('justdoinc:justdo-emails@1.0.0', both); // client is needed for media files

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
  api.addFiles("lib/justdo-chat/server/static-unread-channels-notifications-managers-registrar.coffee", server);
  api.addFiles("lib/justdo-chat/server/api.coffee", server);
  api.addFiles("lib/justdo-chat/server/allow-deny.coffee", server);
  api.addFiles("lib/justdo-chat/server/collections-hooks.coffee", server);
  api.addFiles("lib/justdo-chat/server/collections-indexes.coffee", server);
  api.addFiles("lib/justdo-chat/server/methods.coffee", server);
  api.addFiles("lib/justdo-chat/server/publications.coffee", server);
  api.addFiles("lib/justdo-chat/server/jobs-definitions.coffee", server);

  // Client
  api.addFiles("lib/justdo-chat/client/api.coffee", client);
  api.addFiles("lib/justdo-chat/client/hash-requests.coffee", client);
  api.addFiles("lib/justdo-chat/client/methods.coffee", client);
  api.addFiles("lib/justdo-chat/client/pseudo-collections.coffee", client);
  api.addFiles("lib/justdo-chat/client/subscriptions.coffee", client);

  //
  // Unread notifications
  //

  // Email
  api.addFiles("lib/justdo-chat/server/unread-notifications/email-unread-notifications.coffee", server);

  // Firebase Mobile Push notifications
  api.addFiles("lib/justdo-chat/server/unread-notifications/firebase-mobile-push-notifications.coffee", server);

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


  // User
  api.addFiles("lib/channels/user/user-channel-both-register.coffee", both)
  api.addFiles("lib/channels/user/user-channel-client-constructor.coffee", client)
  api.addFiles("lib/channels/user/user-channel-server-constructor.coffee", server)
  
  // Group
  api.addFiles("lib/channels/group/group-channel-both-register.coffee", both)
  api.addFiles("lib/channels/group/group-channel-client-constructor.coffee", client)
  api.addFiles("lib/channels/group/group-channel-server-constructor.coffee", server)
  api.addFiles("lib/channels/group/group-channel-server-register.coffee", server);

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

  // User channel
  api.addFiles("lib/ui/channels/user/placeholder-items/placeholder-items.html", client); 
  api.addFiles("lib/ui/channels/user/placeholder-items/placeholder-items.coffee", client); 

  // Group channel
  api.addAssets("lib/ui/channels/group/assets/anonymous-users-profile-image.png", client);
  api.addFiles("lib/ui/channels/group/settings/group-channel-settings.sass", client); 
  api.addFiles("lib/ui/channels/group/settings/group-channel-settings.html", client); 
  api.addFiles("lib/ui/channels/group/settings/group-channel-settings.coffee", client); 

  api.addFiles("lib/ui/channels/group/placeholder-items/placeholder-items.html", client); 
  api.addFiles("lib/ui/channels/group/placeholder-items/placeholder-items.coffee", client); 

  // Recent channels activity
  api.addFiles("lib/ui/recent-activity-dropdown/recent-activity-dropdown/group-channels-items/group-channels-items.html", client);
  api.addFiles("lib/ui/recent-activity-dropdown/recent-activity-dropdown/group-channels-items/group-channels-items.coffee", client);
  api.addFiles("lib/ui/recent-activity-dropdown/recent-activity-dropdown/user-channels-items/user-channels-items.html", client);
  api.addFiles("lib/ui/recent-activity-dropdown/recent-activity-dropdown/user-channels-items/user-channels-items.coffee", client);
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

  api.addFiles("lib/ui/bottom-windows/group/bottom-window-header.sass", client);
  api.addFiles("lib/ui/bottom-windows/group/bottom-window-header.html", client);
  api.addFiles("lib/ui/bottom-windows/group/bottom-window-header.coffee", client);

  api.addFiles("lib/ui/bottom-windows/user/bottom-window-header.sass", client);
  api.addFiles("lib/ui/bottom-windows/user/bottom-window-header.html", client);
  api.addFiles("lib/ui/bottom-windows/user/bottom-window-header.coffee", client);

  api.addFiles("lib/ui/bottom-windows/task/common.coffee", client);
  api.addFiles("lib/ui/bottom-windows/task/bottom-window-header.html", client);
  api.addFiles("lib/ui/bottom-windows/task/bottom-window-header.coffee", client);
  api.addFiles("lib/ui/bottom-windows/task/task-minimized.sass", client);
  api.addFiles("lib/ui/bottom-windows/task/task-minimized.html", client);
  api.addFiles("lib/ui/bottom-windows/task/task-minimized.coffee", client);

  api.addFiles("lib/ui/bottom-windows/common/vars.scss", client);
  api.addFiles("lib/ui/bottom-windows/common/common.sass", client);
  api.addFiles("lib/ui/bottom-windows/common/bottom-window-open.sass", client);
  api.addFiles("lib/ui/bottom-windows/common/bottom-window-open.html", client);
  api.addFiles("lib/ui/bottom-windows/common/bottom-window-open.coffee", client);

  api.addFiles("lib/ui/bottom-windows/fix-unclickable-area-under-chat-windows.sass", client);

  //
  // User conf
  //
  api.addFiles("lib/user-conf/user-conf-involuntary-unread-chat-notifications.coffee", client);

  api.addFiles("lib/user-conf/involuntary-unread-email-chat-notifications/involuntary-unread-email-chat-notifications.html", client);
  api.addFiles("lib/user-conf/involuntary-unread-email-chat-notifications/involuntary-unread-email-chat-notifications.sass", client);
  api.addFiles("lib/user-conf/involuntary-unread-email-chat-notifications/involuntary-unread-email-chat-notifications.coffee", client);

  //
  // Project Conf
  //
  api.addFiles("lib/project-conf/justdo-chat-project-config.sass", client);
  api.addFiles("lib/project-conf/justdo-chat-project-config.html", client);
  api.addFiles("lib/project-conf/justdo-chat-project-config.coffee", client);
  
  // Always after templates
  this.addI18nFiles(api, "i18n/{}.i18n.json");

  // recent-activity-dropdown
  this.addI18nFiles(api, "i18n/recent-activity-dropdown/{}.i18n.json");

  // bottom-window
  this.addI18nFiles(api, "i18n/bottom-window/{}.i18n.json");

  // group-chat
  this.addI18nFiles(api, "i18n/group-chat/{}.i18n.json");

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
  api.addAssets("media/chat-sprite.png", client);

  // Built-in bots avatars
  api.addAssets("media/bots-avatars/your-assistant.png", client);

  api.export("JustdoChat", both);
});
