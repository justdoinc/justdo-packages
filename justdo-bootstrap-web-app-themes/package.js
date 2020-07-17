Package.describe({
  name: "justdoinc:bootstrap-themes",
  summary: "",
  version: "1.0.0"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  // Switch themes with: APP.bootstrap_themes_manager.setTheme("sketchy")

  api.addAssets("default/bootstrap.css", client);
  api.addAssets("cerulean/bootstrap.css", client);
  api.addAssets("minty/bootstrap.css", client);
  api.addAssets("sandstone/bootstrap.css", client);
  api.addAssets("sketchy/bootstrap.css", client);
  api.addAssets("superhero/bootstrap.css", client);

  api.addAssets("unicorn/bootstrap.css", client);
  api.addAssets("unicorn/unicorn-bg-1.jpg", client);
  api.addAssets("unicorn/unicorn-bg-2.jpg", client);
});
