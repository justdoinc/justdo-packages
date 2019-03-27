Package.describe({
  name: "twbs:bootstrap",
  summary: "A fork of Nemo64's meteor-bootstrap package disguised as twbs:bootstrap",
  // Note We desguided this pack as twbs:bootstrap so packages that depends on
  // it won't cause it to load and override our rules
  version: "3.3.5" // Should be same as the bootstrap version in use
});

client = "client"
server = "server"
both = [client, server]

Package.onUse(function (api) {
  api.versionsFrom("1.4.1.1");

  api.addFiles("bootstrap.js", client);
  api.addFiles("bootstrap.css", client);
});
