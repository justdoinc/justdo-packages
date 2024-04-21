Package.describe({
    name: "stemcapital:bootstrap3-select",
    version: "1.1.0"
});

Package.onUse(function(api) {
    api.addFiles("bootstrap-select.css", "client");
    api.addFiles("bootstrap-select.js", "client");
});

