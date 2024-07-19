Package.describe({
  name: "justdoinc:justdo-core-project-configurations",
  version: "1.0.0",
  summary: "In this package the core project configurations of the justdo Projects library are being defined - the pack started out of the need to demostrate how to use the project configuration APIs",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-core-project-configurations"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.use("coffeescript", both);
  api.use("underscore", both);
  api.use("templating", client);
  api.use('fourseven:scss@3.2.0', client);

  api.use("raix:eventemitter@0.1.1", both);
  api.use("meteorspark:util@0.2.0", both);
  api.use("meteorspark:logger@0.3.0", both);
  api.use("justdoinc:justdo-helpers@1.0.0", both);
  api.use("tap:i18n", both);

  api.use("reactive-var", both);
  api.use("tracker", client);

  api.use("aldeed:simple-schema@1.3.1", both);
  api.use("stem-capital:projects@0.1.0", both);

  api.use("meteorspark:app@0.3.0", both);
  api.use("justdoinc:justdo-webapp-boot@1.0.0", both);

  api.addFiles("lib/client/templates/project-uid.html", client);
  api.addFiles("lib/client/templates/project-uid.coffee", client);

  api.addFiles("lib/client/core-confs-ui-sections.coffee", client);
  api.addFiles("lib/client/core-confs-ui-templates.coffee", client);

  api.addFiles("lib/server/core-confs-definitions.coffee", server);

  api.addFiles("lib/client/templates/project-custom-states/project-custom-states.html", client);
  api.addFiles("lib/client/templates/project-custom-states/project-custom-states.coffee", client);
  api.addFiles("lib/client/templates/project-custom-states/project-custom-states.sass", client);

  api.addFiles("lib/client/templates/project-custom-states/project-custom-state-item.html", client);
  api.addFiles("lib/client/templates/project-custom-states/project-custom-state-item.coffee", client);
  api.addFiles("lib/client/templates/project-custom-states/project-custom-state-item.sass", client);

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

});
