Package.describe({
  name: "justdoinc:justdo-avatar",
  version: "1.0.0",
  summary: "Display profile picture with fallback to user initials + Blaze template",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-avatar"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.3");

  api.use("templating", client);
  api.use("underscore", both);
  api.use("coffeescript", both);
  api.use("fourseven:scss@3.2.0", client);

  api.use("justdoinc:justdo-helpers", both);

  api.addFiles("lib/settings.js", both);
  api.addFiles("lib/both.coffee", both);

  api.addFiles("lib/templates.html", client);
  api.addFiles("lib/client.coffee", client);
  api.addFiles("lib/styles.sass", client);
  api.addAssets("lib/img/anonymous-profile-image.png", client);

  // Avatars box
  api.addFiles("lib/avatars-box/avatars-box.html", client);
  api.addFiles("lib/avatars-box/avatars-box.sass", client);
  api.addFiles("lib/avatars-box/avatars-box.coffee", client);

  api.export("JustdoAvatar", both);
});
