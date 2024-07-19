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
  api.use("underscore", server);
  api.use("coffeescript", server);
  api.use("email", server);
  api.use("sacha:juice@0.1.4", server);
  api.use("astrocoders:handlebars-server@1.0.3", server);
  api.use("aldeed:simple-schema@1.3.1", both);
  api.use("justdoinc:justdo-helpers", both);
  api.use("tap:i18n", both);

  api.use("justdoinc:justdo-analytics@1.0.0", both);

  api.addFiles("lib/server/email.coffee", server);
  api.addFiles("lib/server/templates/wrappers/email-wrapper.handlebars", server);

  api.addFiles("lib/server/templates/admins/contact-request.handlebars", server);

  api.addFiles("lib/server/templates/notifications/notifications-added-to-new-project.handlebars", server);

  api.addFiles("lib/server/templates/project-notifications/ownership-transfer.handlebars", server);
  api.addFiles("lib/server/templates/project-notifications/ownership-transfer-rejected.handlebars", server);

  api.addFiles("lib/server/templates/email-verification.handlebars", server);
  api.addFiles("lib/server/templates/password-recovery.handlebars", server);

  api.addFiles("lib/server/templates/chat-notifications/notifications-iv-unread-chat.handlebars", server);
  api.addFiles("lib/server/templates/chat-notifications/notifications-iv-unread-group-chat.handlebars", server);

  api.addAssets("media/logo.png", client);

  // Uncomment only in packages that integrate with the main applications
  // Pure logic packages should avoid any app specific integration.
  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);
  // Note: app-integration need to load last, so immediateInit procedures in
  // the server will have the access to the apis loaded after the init.coffee
  // file.

  // Always after templates
  api.addFiles([
    "i18n/en.i18n.json",
    "i18n/ar.i18n.json",
    "i18n/es.i18n.json",
    "i18n/fr.i18n.json",
    "i18n/he.i18n.json",
    "i18n/ja.i18n.json",
    "i18n/km.i18n.json",
    "i18n/ko.i18n.json",
    "i18n/pt-PT.i18n.json",
    "i18n/pt-BR.i18n.json",
    "i18n/vi.i18n.json",
    "i18n/ru.i18n.json",
    "i18n/yi.i18n.json",
    "i18n/it.i18n.json",
    "i18n/de.i18n.json",
    "i18n/hi.i18n.json",
    "i18n/tr.i18n.json",
    "i18n/el.i18n.json",
    "i18n/da.i18n.json",
    "i18n/fi.i18n.json",
    "i18n/nl.i18n.json",
    "i18n/sv.i18n.json",
    "i18n/th.i18n.json",
    "i18n/id.i18n.json",
    "i18n/pl.i18n.json",
    "i18n/cs.i18n.json",
    "i18n/hu.i18n.json",
    "i18n/ro.i18n.json",
    "i18n/sk.i18n.json",
    "i18n/uk.i18n.json",
    "i18n/bg.i18n.json",
    "i18n/hr.i18n.json",
    "i18n/sr.i18n.json",
    "i18n/sl.i18n.json",
    "i18n/et.i18n.json",
    "i18n/lv.i18n.json",
    "i18n/lt.i18n.json",
    "i18n/am.i18n.json",
    "i18n/zh-CN.i18n.json",
    "i18n/zh-TW.i18n.json",
    "i18n/sw.i18n.json",
    "i18n/af.i18n.json",
    "i18n/az.i18n.json",
    "i18n/be.i18n.json",
    "i18n/bn.i18n.json",
    "i18n/bs.i18n.json",
    "i18n/ca.i18n.json",
    "i18n/eu.i18n.json",
    "i18n/lb.i18n.json",
    "i18n/mk.i18n.json",
    "i18n/ne.i18n.json",
    "i18n/nb.i18n.json",
    "i18n/sq.i18n.json",
    "i18n/ta.i18n.json",
    "i18n/uz.i18n.json",
    "i18n/hy.i18n.json",
    "i18n/kk.i18n.json",
    "i18n/ky.i18n.json",
    "i18n/ms.i18n.json",
    "i18n/tg.i18n.json"
  ], both);

  api.export("JustdoEmails", server);
});
