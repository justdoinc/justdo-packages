Package.describe({
  name: "justdoinc:justdo-moment",
  version: "1.0.0",
  summary: "JustDo Moment.js wrapper providing global access"
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");
  api.use("coffeescript", both);
  
  api.use("ecmascript", both);
  api.use("tmeasday:check-npm-versions@0.3.1", both);

  api.addFiles("lib/both/moment.coffee", both);

  // Export moment globally
  api.export("moment", both);
});