Package.describe({
  name: "justdoinc:justdo-color-gradient",
  version: "1.0.0",
  summary: "Get the color based on preset color values of the gradient",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-color-gradient"
});

client = "client"

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.3");

  api.use("underscore", client);
  api.use("coffeescript", client);

  api.add_files("lib/client.coffee", client);

  api.export("JustdoColorGradient", client);
});