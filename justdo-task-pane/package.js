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
  api.use("tap:i18n", both);
  api.use("justdoinc:justdo-i18n@1.0.0", both);

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

  // Always after templates
  // Activity
  api.addFiles([
    "i18n/activity/en.i18n.json",
    "i18n/activity/ar.i18n.json",
    "i18n/activity/es.i18n.json",
    "i18n/activity/fr.i18n.json",
    "i18n/activity/he.i18n.json",
    "i18n/activity/ja.i18n.json",
    "i18n/activity/km.i18n.json",
    "i18n/activity/ko.i18n.json",
    "i18n/activity/pt-PT.i18n.json",
    "i18n/activity/pt-BR.i18n.json",
    "i18n/activity/vi.i18n.json",
    "i18n/activity/ru.i18n.json",
    "i18n/activity/yi.i18n.json",
    "i18n/activity/it.i18n.json",
    "i18n/activity/de.i18n.json",
    "i18n/activity/hi.i18n.json",
    "i18n/activity/tr.i18n.json",
    "i18n/activity/el.i18n.json",
    "i18n/activity/da.i18n.json",
    "i18n/activity/fi.i18n.json",
    "i18n/activity/nl.i18n.json",
    "i18n/activity/sv.i18n.json",
    "i18n/activity/th.i18n.json",
    "i18n/activity/id.i18n.json",
    "i18n/activity/pl.i18n.json",
    "i18n/activity/cs.i18n.json",
    "i18n/activity/hu.i18n.json",
    "i18n/activity/ro.i18n.json",
    "i18n/activity/sk.i18n.json",
    "i18n/activity/uk.i18n.json",
    "i18n/activity/bg.i18n.json",
    "i18n/activity/hr.i18n.json",
    "i18n/activity/sr.i18n.json",
    "i18n/activity/sl.i18n.json",
    "i18n/activity/et.i18n.json",
    "i18n/activity/lv.i18n.json",
    "i18n/activity/lt.i18n.json",
    "i18n/activity/am.i18n.json",
    "i18n/activity/zh-CN.i18n.json",
    "i18n/activity/zh-TW.i18n.json",
    "i18n/activity/sw.i18n.json",
    "i18n/activity/af.i18n.json",
    "i18n/activity/az.i18n.json",
    "i18n/activity/be.i18n.json",
    "i18n/activity/bn.i18n.json",
    "i18n/activity/bs.i18n.json",
    "i18n/activity/ca.i18n.json",
    "i18n/activity/eu.i18n.json",
    "i18n/activity/lb.i18n.json",
    "i18n/activity/mk.i18n.json",
    "i18n/activity/ne.i18n.json",
    "i18n/activity/nb.i18n.json",
    "i18n/activity/sq.i18n.json",
    "i18n/activity/ta.i18n.json",
    "i18n/activity/uz.i18n.json",
    "i18n/activity/hy.i18n.json",
    "i18n/activity/kk.i18n.json",
    "i18n/activity/ky.i18n.json",
    "i18n/activity/ms.i18n.json",
    "i18n/activity/tg.i18n.json"
  ], both);

  // Item details
  api.addFiles([
    "i18n/item-details/en.i18n.json",
    "i18n/item-details/ar.i18n.json",
    "i18n/item-details/es.i18n.json",
    "i18n/item-details/fr.i18n.json",
    "i18n/item-details/he.i18n.json",
    "i18n/item-details/ja.i18n.json",
    "i18n/item-details/km.i18n.json",
    "i18n/item-details/ko.i18n.json",
    "i18n/item-details/pt-PT.i18n.json",
    "i18n/item-details/pt-BR.i18n.json",
    "i18n/item-details/vi.i18n.json",
    "i18n/item-details/ru.i18n.json",
    "i18n/item-details/yi.i18n.json",
    "i18n/item-details/it.i18n.json",
    "i18n/item-details/de.i18n.json",
    "i18n/item-details/hi.i18n.json",
    "i18n/item-details/tr.i18n.json",
    "i18n/item-details/el.i18n.json",
    "i18n/item-details/da.i18n.json",
    "i18n/item-details/fi.i18n.json",
    "i18n/item-details/nl.i18n.json",
    "i18n/item-details/sv.i18n.json",
    "i18n/item-details/th.i18n.json",
    "i18n/item-details/id.i18n.json",
    "i18n/item-details/pl.i18n.json",
    "i18n/item-details/cs.i18n.json",
    "i18n/item-details/hu.i18n.json",
    "i18n/item-details/ro.i18n.json",
    "i18n/item-details/sk.i18n.json",
    "i18n/item-details/uk.i18n.json",
    "i18n/item-details/bg.i18n.json",
    "i18n/item-details/hr.i18n.json",
    "i18n/item-details/sr.i18n.json",
    "i18n/item-details/sl.i18n.json",
    "i18n/item-details/et.i18n.json",
    "i18n/item-details/lv.i18n.json",
    "i18n/item-details/lt.i18n.json",
    "i18n/item-details/am.i18n.json",
    "i18n/item-details/zh-CN.i18n.json",
    "i18n/item-details/zh-TW.i18n.json",
    "i18n/item-details/sw.i18n.json",
    "i18n/item-details/af.i18n.json",
    "i18n/item-details/az.i18n.json",
    "i18n/item-details/be.i18n.json",
    "i18n/item-details/bn.i18n.json",
    "i18n/item-details/bs.i18n.json",
    "i18n/item-details/ca.i18n.json",
    "i18n/item-details/eu.i18n.json",
    "i18n/item-details/lb.i18n.json",
    "i18n/item-details/mk.i18n.json",
    "i18n/item-details/ne.i18n.json",
    "i18n/item-details/nb.i18n.json",
    "i18n/item-details/sq.i18n.json",
    "i18n/item-details/ta.i18n.json",
    "i18n/item-details/uz.i18n.json",
    "i18n/item-details/hy.i18n.json",
    "i18n/item-details/kk.i18n.json",
    "i18n/item-details/ky.i18n.json",
    "i18n/item-details/ms.i18n.json",
    "i18n/item-details/tg.i18n.json"
  ], both);

  // Item details description
  api.addFiles([
    "i18n/item-details/item-details-description/en.i18n.json",
    "i18n/item-details/item-details-description/ar.i18n.json",
    "i18n/item-details/item-details-description/es.i18n.json",
    "i18n/item-details/item-details-description/fr.i18n.json",
    "i18n/item-details/item-details-description/he.i18n.json",
    "i18n/item-details/item-details-description/ja.i18n.json",
    "i18n/item-details/item-details-description/km.i18n.json",
    "i18n/item-details/item-details-description/ko.i18n.json",
    "i18n/item-details/item-details-description/pt-PT.i18n.json",
    "i18n/item-details/item-details-description/pt-BR.i18n.json",
    "i18n/item-details/item-details-description/vi.i18n.json",
    "i18n/item-details/item-details-description/ru.i18n.json",
    "i18n/item-details/item-details-description/yi.i18n.json",
    "i18n/item-details/item-details-description/it.i18n.json",
    "i18n/item-details/item-details-description/de.i18n.json",
    "i18n/item-details/item-details-description/hi.i18n.json",
    "i18n/item-details/item-details-description/tr.i18n.json",
    "i18n/item-details/item-details-description/el.i18n.json",
    "i18n/item-details/item-details-description/da.i18n.json",
    "i18n/item-details/item-details-description/fi.i18n.json",
    "i18n/item-details/item-details-description/nl.i18n.json",
    "i18n/item-details/item-details-description/sv.i18n.json",
    "i18n/item-details/item-details-description/th.i18n.json",
    "i18n/item-details/item-details-description/id.i18n.json",
    "i18n/item-details/item-details-description/pl.i18n.json",
    "i18n/item-details/item-details-description/cs.i18n.json",
    "i18n/item-details/item-details-description/hu.i18n.json",
    "i18n/item-details/item-details-description/ro.i18n.json",
    "i18n/item-details/item-details-description/sk.i18n.json",
    "i18n/item-details/item-details-description/uk.i18n.json",
    "i18n/item-details/item-details-description/bg.i18n.json",
    "i18n/item-details/item-details-description/hr.i18n.json",
    "i18n/item-details/item-details-description/sr.i18n.json",
    "i18n/item-details/item-details-description/sl.i18n.json",
    "i18n/item-details/item-details-description/et.i18n.json",
    "i18n/item-details/item-details-description/lv.i18n.json",
    "i18n/item-details/item-details-description/lt.i18n.json",
    "i18n/item-details/item-details-description/am.i18n.json",
    "i18n/item-details/item-details-description/zh-CN.i18n.json",
    "i18n/item-details/item-details-description/zh-TW.i18n.json",
    "i18n/item-details/item-details-description/sw.i18n.json",
    "i18n/item-details/item-details-description/af.i18n.json",
    "i18n/item-details/item-details-description/az.i18n.json",
    "i18n/item-details/item-details-description/be.i18n.json",
    "i18n/item-details/item-details-description/bn.i18n.json",
    "i18n/item-details/item-details-description/bs.i18n.json",
    "i18n/item-details/item-details-description/ca.i18n.json",
    "i18n/item-details/item-details-description/eu.i18n.json",
    "i18n/item-details/item-details-description/lb.i18n.json",
    "i18n/item-details/item-details-description/mk.i18n.json",
    "i18n/item-details/item-details-description/ne.i18n.json",
    "i18n/item-details/item-details-description/nb.i18n.json",
    "i18n/item-details/item-details-description/sq.i18n.json",
    "i18n/item-details/item-details-description/ta.i18n.json",
    "i18n/item-details/item-details-description/uz.i18n.json",
    "i18n/item-details/item-details-description/hy.i18n.json",
    "i18n/item-details/item-details-description/kk.i18n.json",
    "i18n/item-details/item-details-description/ky.i18n.json",
    "i18n/item-details/item-details-description/ms.i18n.json",
    "i18n/item-details/item-details-description/tg.i18n.json"
  ], both);

  api.use("meteorspark:app@0.3.0", client);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", client);

  api.export("JustdoTaskPane", both);
});
