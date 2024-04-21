Package.describe({
  summary: 'Automatically adjust textarea height based on user input.',
  version: '1.17.8',
  git: "https://github.com/copleykj/jquery-autosize.git"
});

Package.onUse(function (api) {
  api.versionsFrom("METEOR@0.9.0");
  api.use('jquery', 'client');
  api.addFiles(['lib/jquery.autosize.js'], 'client');
  
  api.export("autosize");
});
