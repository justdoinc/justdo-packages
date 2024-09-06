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

  api.use("justdoinc:justdo-i18n@1.0.0", both);
  api.use("tap:i18n", both);

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

  api.addFiles("lib/client/edit-invited-member/edit-invited-member.html", client);
  api.addFiles("lib/client/edit-invited-member/edit-invited-member.coffee", client);
  api.addFiles("lib/client/edit-invited-member/edit-invited-member.sass", client);

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

  api.addFiles("lib/client/invite-members-failed.html", client);
  api.addFiles("lib/client/invite-members-failed.coffee", client);
  api.addFiles("lib/client/invite-members-failed.sass", client);

  // Always after templates
  // change-email-dialog
  api.addFiles([
    "i18n/change-email-dialog/en.i18n.json",
    "i18n/change-email-dialog/ar.i18n.json",
    "i18n/change-email-dialog/es.i18n.json",
    "i18n/change-email-dialog/fr.i18n.json",
    "i18n/change-email-dialog/he.i18n.json",
    "i18n/change-email-dialog/ja.i18n.json",
    "i18n/change-email-dialog/km.i18n.json",
    "i18n/change-email-dialog/ko.i18n.json",
    "i18n/change-email-dialog/pt-PT.i18n.json",
    "i18n/change-email-dialog/pt-BR.i18n.json",
    "i18n/change-email-dialog/vi.i18n.json",
    "i18n/change-email-dialog/ru.i18n.json",
    "i18n/change-email-dialog/yi.i18n.json",
    "i18n/change-email-dialog/it.i18n.json",
    "i18n/change-email-dialog/de.i18n.json",
    "i18n/change-email-dialog/hi.i18n.json",
    "i18n/change-email-dialog/tr.i18n.json",
    "i18n/change-email-dialog/el.i18n.json",
    "i18n/change-email-dialog/da.i18n.json",
    "i18n/change-email-dialog/fi.i18n.json",
    "i18n/change-email-dialog/nl.i18n.json",
    "i18n/change-email-dialog/sv.i18n.json",
    "i18n/change-email-dialog/th.i18n.json",
    "i18n/change-email-dialog/id.i18n.json",
    "i18n/change-email-dialog/pl.i18n.json",
    "i18n/change-email-dialog/cs.i18n.json",
    "i18n/change-email-dialog/hu.i18n.json",
    "i18n/change-email-dialog/ro.i18n.json",
    "i18n/change-email-dialog/sk.i18n.json",
    "i18n/change-email-dialog/uk.i18n.json",
    "i18n/change-email-dialog/bg.i18n.json",
    "i18n/change-email-dialog/hr.i18n.json",
    "i18n/change-email-dialog/sr.i18n.json",
    "i18n/change-email-dialog/sl.i18n.json",
    "i18n/change-email-dialog/et.i18n.json",
    "i18n/change-email-dialog/lv.i18n.json",
    "i18n/change-email-dialog/lt.i18n.json",
    "i18n/change-email-dialog/am.i18n.json",
    "i18n/change-email-dialog/zh-CN.i18n.json",
    "i18n/change-email-dialog/zh-TW.i18n.json",
    "i18n/change-email-dialog/sw.i18n.json",
    "i18n/change-email-dialog/af.i18n.json",
    "i18n/change-email-dialog/az.i18n.json",
    "i18n/change-email-dialog/be.i18n.json",
    "i18n/change-email-dialog/bn.i18n.json",
    "i18n/change-email-dialog/bs.i18n.json",
    "i18n/change-email-dialog/ca.i18n.json",
    "i18n/change-email-dialog/eu.i18n.json",
    "i18n/change-email-dialog/lb.i18n.json",
    "i18n/change-email-dialog/mk.i18n.json",
    "i18n/change-email-dialog/ne.i18n.json",
    "i18n/change-email-dialog/nb.i18n.json",
    "i18n/change-email-dialog/sq.i18n.json",
    "i18n/change-email-dialog/ta.i18n.json",
    "i18n/change-email-dialog/uz.i18n.json",
    "i18n/change-email-dialog/hy.i18n.json",
    "i18n/change-email-dialog/kk.i18n.json",
    "i18n/change-email-dialog/ky.i18n.json",
    "i18n/change-email-dialog/ms.i18n.json",
    "i18n/change-email-dialog/tg.i18n.json"
  ], both);

  // members-management-dialog
  api.addFiles([
    "i18n/members-management-dialog/en.i18n.json",
    "i18n/members-management-dialog/ar.i18n.json",
    "i18n/members-management-dialog/es.i18n.json",
    "i18n/members-management-dialog/fr.i18n.json",
    "i18n/members-management-dialog/he.i18n.json",
    "i18n/members-management-dialog/ja.i18n.json",
    "i18n/members-management-dialog/km.i18n.json",
    "i18n/members-management-dialog/ko.i18n.json",
    "i18n/members-management-dialog/pt-PT.i18n.json",
    "i18n/members-management-dialog/pt-BR.i18n.json",
    "i18n/members-management-dialog/vi.i18n.json",
    "i18n/members-management-dialog/ru.i18n.json",
    "i18n/members-management-dialog/yi.i18n.json",
    "i18n/members-management-dialog/it.i18n.json",
    "i18n/members-management-dialog/de.i18n.json",
    "i18n/members-management-dialog/hi.i18n.json",
    "i18n/members-management-dialog/tr.i18n.json",
    "i18n/members-management-dialog/el.i18n.json",
    "i18n/members-management-dialog/da.i18n.json",
    "i18n/members-management-dialog/fi.i18n.json",
    "i18n/members-management-dialog/nl.i18n.json",
    "i18n/members-management-dialog/sv.i18n.json",
    "i18n/members-management-dialog/th.i18n.json",
    "i18n/members-management-dialog/id.i18n.json",
    "i18n/members-management-dialog/pl.i18n.json",
    "i18n/members-management-dialog/cs.i18n.json",
    "i18n/members-management-dialog/hu.i18n.json",
    "i18n/members-management-dialog/ro.i18n.json",
    "i18n/members-management-dialog/sk.i18n.json",
    "i18n/members-management-dialog/uk.i18n.json",
    "i18n/members-management-dialog/bg.i18n.json",
    "i18n/members-management-dialog/hr.i18n.json",
    "i18n/members-management-dialog/sr.i18n.json",
    "i18n/members-management-dialog/sl.i18n.json",
    "i18n/members-management-dialog/et.i18n.json",
    "i18n/members-management-dialog/lv.i18n.json",
    "i18n/members-management-dialog/lt.i18n.json",
    "i18n/members-management-dialog/am.i18n.json",
    "i18n/members-management-dialog/zh-CN.i18n.json",
    "i18n/members-management-dialog/zh-TW.i18n.json",
    "i18n/members-management-dialog/sw.i18n.json",
    "i18n/members-management-dialog/af.i18n.json",
    "i18n/members-management-dialog/az.i18n.json",
    "i18n/members-management-dialog/be.i18n.json",
    "i18n/members-management-dialog/bn.i18n.json",
    "i18n/members-management-dialog/bs.i18n.json",
    "i18n/members-management-dialog/ca.i18n.json",
    "i18n/members-management-dialog/eu.i18n.json",
    "i18n/members-management-dialog/lb.i18n.json",
    "i18n/members-management-dialog/mk.i18n.json",
    "i18n/members-management-dialog/ne.i18n.json",
    "i18n/members-management-dialog/nb.i18n.json",
    "i18n/members-management-dialog/sq.i18n.json",
    "i18n/members-management-dialog/ta.i18n.json",
    "i18n/members-management-dialog/uz.i18n.json",
    "i18n/members-management-dialog/hy.i18n.json",
    "i18n/members-management-dialog/kk.i18n.json",
    "i18n/members-management-dialog/ky.i18n.json",
    "i18n/members-management-dialog/ms.i18n.json",
    "i18n/members-management-dialog/tg.i18n.json"
  ], both);
  
  // confirm-edit-members-dialog
  api.addFiles([
    "i18n/confirm-edit-members-dialog/en.i18n.json",
    "i18n/confirm-edit-members-dialog/ar.i18n.json",
    "i18n/confirm-edit-members-dialog/es.i18n.json",
    "i18n/confirm-edit-members-dialog/fr.i18n.json",
    "i18n/confirm-edit-members-dialog/he.i18n.json",
    "i18n/confirm-edit-members-dialog/ja.i18n.json",
    "i18n/confirm-edit-members-dialog/km.i18n.json",
    "i18n/confirm-edit-members-dialog/ko.i18n.json",
    "i18n/confirm-edit-members-dialog/pt-PT.i18n.json",
    "i18n/confirm-edit-members-dialog/pt-BR.i18n.json",
    "i18n/confirm-edit-members-dialog/vi.i18n.json",
    "i18n/confirm-edit-members-dialog/ru.i18n.json",
    "i18n/confirm-edit-members-dialog/yi.i18n.json",
    "i18n/confirm-edit-members-dialog/it.i18n.json",
    "i18n/confirm-edit-members-dialog/de.i18n.json",
    "i18n/confirm-edit-members-dialog/hi.i18n.json",
    "i18n/confirm-edit-members-dialog/tr.i18n.json",
    "i18n/confirm-edit-members-dialog/el.i18n.json",
    "i18n/confirm-edit-members-dialog/da.i18n.json",
    "i18n/confirm-edit-members-dialog/fi.i18n.json",
    "i18n/confirm-edit-members-dialog/nl.i18n.json",
    "i18n/confirm-edit-members-dialog/sv.i18n.json",
    "i18n/confirm-edit-members-dialog/th.i18n.json",
    "i18n/confirm-edit-members-dialog/id.i18n.json",
    "i18n/confirm-edit-members-dialog/pl.i18n.json",
    "i18n/confirm-edit-members-dialog/cs.i18n.json",
    "i18n/confirm-edit-members-dialog/hu.i18n.json",
    "i18n/confirm-edit-members-dialog/ro.i18n.json",
    "i18n/confirm-edit-members-dialog/sk.i18n.json",
    "i18n/confirm-edit-members-dialog/uk.i18n.json",
    "i18n/confirm-edit-members-dialog/bg.i18n.json",
    "i18n/confirm-edit-members-dialog/hr.i18n.json",
    "i18n/confirm-edit-members-dialog/sr.i18n.json",
    "i18n/confirm-edit-members-dialog/sl.i18n.json",
    "i18n/confirm-edit-members-dialog/et.i18n.json",
    "i18n/confirm-edit-members-dialog/lv.i18n.json",
    "i18n/confirm-edit-members-dialog/lt.i18n.json",
    "i18n/confirm-edit-members-dialog/am.i18n.json",
    "i18n/confirm-edit-members-dialog/zh-CN.i18n.json",
    "i18n/confirm-edit-members-dialog/zh-TW.i18n.json",
    "i18n/confirm-edit-members-dialog/sw.i18n.json",
    "i18n/confirm-edit-members-dialog/af.i18n.json",
    "i18n/confirm-edit-members-dialog/az.i18n.json",
    "i18n/confirm-edit-members-dialog/be.i18n.json",
    "i18n/confirm-edit-members-dialog/bn.i18n.json",
    "i18n/confirm-edit-members-dialog/bs.i18n.json",
    "i18n/confirm-edit-members-dialog/ca.i18n.json",
    "i18n/confirm-edit-members-dialog/eu.i18n.json",
    "i18n/confirm-edit-members-dialog/lb.i18n.json",
    "i18n/confirm-edit-members-dialog/mk.i18n.json",
    "i18n/confirm-edit-members-dialog/ne.i18n.json",
    "i18n/confirm-edit-members-dialog/nb.i18n.json",
    "i18n/confirm-edit-members-dialog/sq.i18n.json",
    "i18n/confirm-edit-members-dialog/ta.i18n.json",
    "i18n/confirm-edit-members-dialog/uz.i18n.json",
    "i18n/confirm-edit-members-dialog/hy.i18n.json",
    "i18n/confirm-edit-members-dialog/kk.i18n.json",
    "i18n/confirm-edit-members-dialog/ky.i18n.json",
    "i18n/confirm-edit-members-dialog/ms.i18n.json",
    "i18n/confirm-edit-members-dialog/tg.i18n.json"
  ], both);

  // add-member-to-current-project
  api.addFiles([
    "i18n/add-member-to-current-project/en.i18n.json",
    "i18n/add-member-to-current-project/ar.i18n.json",
    "i18n/add-member-to-current-project/es.i18n.json",
    "i18n/add-member-to-current-project/fr.i18n.json",
    "i18n/add-member-to-current-project/he.i18n.json",
    "i18n/add-member-to-current-project/ja.i18n.json",
    "i18n/add-member-to-current-project/km.i18n.json",
    "i18n/add-member-to-current-project/ko.i18n.json",
    "i18n/add-member-to-current-project/pt-PT.i18n.json",
    "i18n/add-member-to-current-project/pt-BR.i18n.json",
    "i18n/add-member-to-current-project/vi.i18n.json",
    "i18n/add-member-to-current-project/ru.i18n.json",
    "i18n/add-member-to-current-project/yi.i18n.json",
    "i18n/add-member-to-current-project/it.i18n.json",
    "i18n/add-member-to-current-project/de.i18n.json",
    "i18n/add-member-to-current-project/hi.i18n.json",
    "i18n/add-member-to-current-project/tr.i18n.json",
    "i18n/add-member-to-current-project/el.i18n.json",
    "i18n/add-member-to-current-project/da.i18n.json",
    "i18n/add-member-to-current-project/fi.i18n.json",
    "i18n/add-member-to-current-project/nl.i18n.json",
    "i18n/add-member-to-current-project/sv.i18n.json",
    "i18n/add-member-to-current-project/th.i18n.json",
    "i18n/add-member-to-current-project/id.i18n.json",
    "i18n/add-member-to-current-project/pl.i18n.json",
    "i18n/add-member-to-current-project/cs.i18n.json",
    "i18n/add-member-to-current-project/hu.i18n.json",
    "i18n/add-member-to-current-project/ro.i18n.json",
    "i18n/add-member-to-current-project/sk.i18n.json",
    "i18n/add-member-to-current-project/uk.i18n.json",
    "i18n/add-member-to-current-project/bg.i18n.json",
    "i18n/add-member-to-current-project/hr.i18n.json",
    "i18n/add-member-to-current-project/sr.i18n.json",
    "i18n/add-member-to-current-project/sl.i18n.json",
    "i18n/add-member-to-current-project/et.i18n.json",
    "i18n/add-member-to-current-project/lv.i18n.json",
    "i18n/add-member-to-current-project/lt.i18n.json",
    "i18n/add-member-to-current-project/am.i18n.json",
    "i18n/add-member-to-current-project/zh-CN.i18n.json",
    "i18n/add-member-to-current-project/zh-TW.i18n.json",
    "i18n/add-member-to-current-project/sw.i18n.json",
    "i18n/add-member-to-current-project/af.i18n.json",
    "i18n/add-member-to-current-project/az.i18n.json",
    "i18n/add-member-to-current-project/be.i18n.json",
    "i18n/add-member-to-current-project/bn.i18n.json",
    "i18n/add-member-to-current-project/bs.i18n.json",
    "i18n/add-member-to-current-project/ca.i18n.json",
    "i18n/add-member-to-current-project/eu.i18n.json",
    "i18n/add-member-to-current-project/lb.i18n.json",
    "i18n/add-member-to-current-project/mk.i18n.json",
    "i18n/add-member-to-current-project/ne.i18n.json",
    "i18n/add-member-to-current-project/nb.i18n.json",
    "i18n/add-member-to-current-project/sq.i18n.json",
    "i18n/add-member-to-current-project/ta.i18n.json",
    "i18n/add-member-to-current-project/uz.i18n.json",
    "i18n/add-member-to-current-project/hy.i18n.json",
    "i18n/add-member-to-current-project/kk.i18n.json",
    "i18n/add-member-to-current-project/ky.i18n.json",
    "i18n/add-member-to-current-project/ms.i18n.json",
    "i18n/add-member-to-current-project/tg.i18n.json"
  ], both);

  // invite-members-failed
  api.addFiles([
    "i18n/invite-members-failed/en.i18n.json",
    "i18n/invite-members-failed/ar.i18n.json",
    "i18n/invite-members-failed/es.i18n.json",
    "i18n/invite-members-failed/fr.i18n.json",
    "i18n/invite-members-failed/he.i18n.json",
    "i18n/invite-members-failed/ja.i18n.json",
    "i18n/invite-members-failed/km.i18n.json",
    "i18n/invite-members-failed/ko.i18n.json",
    "i18n/invite-members-failed/pt-PT.i18n.json",
    "i18n/invite-members-failed/pt-BR.i18n.json",
    "i18n/invite-members-failed/vi.i18n.json",
    "i18n/invite-members-failed/ru.i18n.json",
    "i18n/invite-members-failed/yi.i18n.json",
    "i18n/invite-members-failed/it.i18n.json",
    "i18n/invite-members-failed/de.i18n.json",
    "i18n/invite-members-failed/hi.i18n.json",
    "i18n/invite-members-failed/tr.i18n.json",
    "i18n/invite-members-failed/el.i18n.json",
    "i18n/invite-members-failed/da.i18n.json",
    "i18n/invite-members-failed/fi.i18n.json",
    "i18n/invite-members-failed/nl.i18n.json",
    "i18n/invite-members-failed/sv.i18n.json",
    "i18n/invite-members-failed/th.i18n.json",
    "i18n/invite-members-failed/id.i18n.json",
    "i18n/invite-members-failed/pl.i18n.json",
    "i18n/invite-members-failed/cs.i18n.json",
    "i18n/invite-members-failed/hu.i18n.json",
    "i18n/invite-members-failed/ro.i18n.json",
    "i18n/invite-members-failed/sk.i18n.json",
    "i18n/invite-members-failed/uk.i18n.json",
    "i18n/invite-members-failed/bg.i18n.json",
    "i18n/invite-members-failed/hr.i18n.json",
    "i18n/invite-members-failed/sr.i18n.json",
    "i18n/invite-members-failed/sl.i18n.json",
    "i18n/invite-members-failed/et.i18n.json",
    "i18n/invite-members-failed/lv.i18n.json",
    "i18n/invite-members-failed/lt.i18n.json",
    "i18n/invite-members-failed/am.i18n.json",
    "i18n/invite-members-failed/zh-CN.i18n.json",
    "i18n/invite-members-failed/zh-TW.i18n.json",
    "i18n/invite-members-failed/sw.i18n.json",
    "i18n/invite-members-failed/af.i18n.json",
    "i18n/invite-members-failed/az.i18n.json",
    "i18n/invite-members-failed/be.i18n.json",
    "i18n/invite-members-failed/bn.i18n.json",
    "i18n/invite-members-failed/bs.i18n.json",
    "i18n/invite-members-failed/ca.i18n.json",
    "i18n/invite-members-failed/eu.i18n.json",
    "i18n/invite-members-failed/lb.i18n.json",
    "i18n/invite-members-failed/mk.i18n.json",
    "i18n/invite-members-failed/ne.i18n.json",
    "i18n/invite-members-failed/nb.i18n.json",
    "i18n/invite-members-failed/sq.i18n.json",
    "i18n/invite-members-failed/ta.i18n.json",
    "i18n/invite-members-failed/uz.i18n.json",
    "i18n/invite-members-failed/hy.i18n.json",
    "i18n/invite-members-failed/kk.i18n.json",
    "i18n/invite-members-failed/ky.i18n.json",
    "i18n/invite-members-failed/ms.i18n.json",
    "i18n/invite-members-failed/tg.i18n.json"
  ], both);
  
  api.export("ProjectPageDialogs", client);
});
