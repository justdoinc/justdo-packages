Package.describe({
  // forked from mizzao:bootboxjs, https://github.com/TimHeckel/meteor-bootboxjs.git
  name: "justdoinc:bootboxjs",
  summary: "Programmatic dialog boxes using Twitter's bootstrap modals",
  version: "4.4.0"
});

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");
  api.use('fourseven:scss@3.2.0', client);

  api.use("justdoinc:justdo-helpers@1.0.0", client);
  api.use("justdoinc:justdo-i18n@1.0.0", client, {weak: true});

  api.use('jquery', 'client');
  api.use('twbs:bootstrap@3.3.4', 'client', {weak: true});

  api.addFiles('bootbox/bootbox.js', "client"); // taken from cb75620 https://github.com/makeusabrew/bootbox.git
  api.addFiles('justdoinc-mods/new-design.sass', "client");
});
