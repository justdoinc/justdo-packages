// This package introduces to the namespace of OTHER package.js the addI18nFiles api.
//
// IMPORTANT: THIS package.js SHOULD ALWAYS LOAD BEFORE ALL OTHER package.js.
// WE ACHIEVE THIS BY NAMING THE FOLDER OF THIS PACKAGE WITH A PREFIX OF 000-.
// BEFORE METEOR HAS THE DEPENDENCY TREE BUILT, IT SCANS PACKAGES IN ALPHABETICAL ORDER.
//
// IMPORTANT: Changing this file won't trigger a rebuild of the packages cache, as such
// you need to manually remove the .meteor/local/isopacks folder to force a rebuild and
// see the changes take effect.

var env = process.env
function csvToArray(csv) {
  return csv.replace(/\s/g, "").split(",");
}

var env_vars_fallback = "en"; // If we can't find the env vars we fallback to
                              // use the value here

var useEnvVarOrFallback = function (env_var_name) {
  if (typeof env[env_var_name] !== "string" || env[env_var_name].trim() == "") {
    console.error("000-package-js-i18n/package.js: Couldn't find env var: " + env_var_name + " falling back to: " + env_vars_fallback + ".");
    console.error("If you see this error message while running meteor procedures such as `$ meteor install;` you can ignore");
    console.error("");

    return env_vars_fallback;
  }

  return env[env_var_name].trim();
}

var DEFAULT_LANG = useEnvVarOrFallback("I18N_DEFAULT_LANGUAGE");
var SUPPORTED_LANG_GROUPS = {
  all: csvToArray(useEnvVarOrFallback("I18N_ALL_SUPPORTED_LANGUAGES")),
  core: csvToArray(useEnvVarOrFallback("I18N_CORE_SUPPORTED_LANGUAGES")),
  default_lang_only: [DEFAULT_LANG]
};
var DEFAULT_SUPPORTED_LANG_GROUP = "all";

// `this` is the global namespace.
// The following code is converted from the following CoffeeScript code:
// @addI18nFiles = (api, i18n_pattern, langs) ->
//   if not langs?
//     langs = DEFAULT_SUPPORTED_LANG_GROUP

//   if typeof langs is "string"
//     if not SUPPORTED_LANG_GROUPS[langs]?
//       throw new Error "Unsupported language group: #{langs}"

//     langs = SUPPORTED_LANG_GROUPS[langs]

//   if DEFAULT_LANG not in langs
//     throw new Error "DEFAULT_LANG not in langs, langs received", langs

//   files_to_add = []
//   for lang in langs
//     file_path = i18n_pattern.replace "{}", lang
//     files_to_add.push file_path

//   api.addFiles(files_to_add, ["client", "server"])
  
//   return

var indexOf = [].indexOf;

this.addI18nFiles = function(api, i18n_pattern, langs) {
  var file_path, files_to_add, i, lang, len;
  if (langs == null) {
    langs = DEFAULT_SUPPORTED_LANG_GROUP;
  }
  if (typeof langs === "string") {
    if (SUPPORTED_LANG_GROUPS[langs] == null) {
      throw new Error(`Unsupported language group: ${langs}`);
    }
    langs = SUPPORTED_LANG_GROUPS[langs];
  }
  if (indexOf.call(langs, DEFAULT_LANG) < 0) {
    throw new Error("DEFAULT_LANG not in langs, langs received", langs);
  }
  files_to_add = [];
  for (i = 0, len = langs.length; i < len; i++) {
    lang = langs[i];
    file_path = i18n_pattern.replace("{}", lang);
    files_to_add.push(file_path);
  }
  api.addFiles(files_to_add, ["client", "server"]);
};
  
Package.describe({
  name: "justdoinc:justdo-i18n-package-js-injector",
  summary: "Expose i18n variables into the global namespace of package.js for other packages to use.",
  version: "1.0.0",
});
