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
  
  api.use('fourseven:scss@3.2.0', client);

  api.use("justdoinc:justdo-legal-docs-versions", both);

  api.addFiles("common-legal-style.sass", client);

  api.addFiles("docs/copyright.html", client);
  api.addFiles("docs/privacy-policy.html", client);
  api.addFiles("docs/terms-conditions.html", client);
  api.addFiles("docs/source-available-terms.html", client);
  api.addFiles("docs/privacy-shield.html", client);
  api.addFiles("docs/on-premise.html", client);
  api.addFiles("docs/promoters-terms-conditions.html", client);
  api.addFiles("docs/cookie-policy.html", client);
  api.addFiles("docs/common.coffee", client);
  api.addAssets("docs/data-subject-access-request.pdf", client);
});
