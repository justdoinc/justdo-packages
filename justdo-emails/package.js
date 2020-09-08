Package.describe({
  name: "justdoinc:justdo-emails",
  version: "1.0.0",
  summary: "JustDo email package (Derived from Telescope)",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-emails"
});

server = "server";
client = "client";
both = [server, client];

Npm.depends({
  "html-to-text": "0.1.0"
});

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.3");

  api.use("underscore", server);
  api.use("coffeescript", server);
  api.use("email", server);
  api.use("sacha:juice@0.1.4", server);
  api.use("astrocoders:handlebars-server@1.0.3", server);
  api.use("aldeed:simple-schema@1.3.1", both);
  api.use("justdoinc:justdo-helpers", both);

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.add_files("lib/server/email.coffee", server);
  api.add_files("lib/server/templates/wrappers/email-wrapper.handlebars", server);

  api.add_files("lib/server/templates/admins/contact-request.handlebars", server);

  api.add_files("lib/server/templates/notifications/notifications-added-to-new-project.handlebars", server);

  api.add_files("lib/server/templates/project-notifications/ownership-transfer.handlebars", server);
  api.add_files("lib/server/templates/project-notifications/ownership-transfer-rejected.handlebars", server);

  api.add_files("lib/server/templates/email-verification.handlebars", server);
  api.add_files("lib/server/templates/password-recovery.handlebars", server);

  api.add_files("lib/server/templates/chat-notifications/notifications-iv-unread-chat.handlebars", server);

  api.addAssets("media/logo.png", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file.

  api.export("JustdoEmails", server);
});
