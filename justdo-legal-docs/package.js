Package.describe({
  name: "justdoinc:justdo-legal-docs",
  version: "1.0.0",
  summary: "Templates of JustDo legal document content",
  git: "https://github.com/justdoinc/justdo-shared-packages/tree/master/justdo-legal-docs"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.1.0.3");

  api.use("templating", both);
  api.use("coffeescript", both);
  api.use("underscore", both);

  api.use("justdoinc:justdo-legal-docs-versions", both);

  api.add_files("docs/copyright.html", client);
  api.add_files("docs/privacy-policy.html", client);
  api.add_files("docs/terms-conditions.html", client);
  api.add_files("docs/privacy-shield.html", client);
  api.add_files("docs/common.coffee", client);
  api.addAssets("docs/data-subject-access-request.pdf", client);
});
