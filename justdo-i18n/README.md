# JustDo i18n

JustDo i18n is built on top of [TAP I18n](https://github.com/TAPevents/tap-i18n). Their documentation is useful if you plan to extend or modify the core functionalities of JustDo i18n.
## Getting Started
Adding i18n suppport is consisted of two steps:
 - Defining a key and the text for display in different languages (i18n files)
 - Replace static text in code to use i18n function

### Defining key and translated text
Under justdo-i18n package, the *i18n/* directory is where all i18n files are stored. The i18n files are grouped by the packages that uses the i18n keys. 
>For example, the directory *i18n/justdo-orgs/* contains all the i18n files that are used by justdo-orgs. 

When attempting to add i18n support to a new package without existing i18n files, please create a folder with the package's name under *justdo-i18n/i18n/* and add your i18n files under it (instead of adding the i18n files directly to the package.)

You will also need to include those files to *justdo-i18n/package.js*. They should be included to both server and client, and always after the inclusion of template files.

### Using the i18n keys in code
The simplest way is to use ```TAPi18n.__(i18n_key, options, lang=null)``` (in Coffeescript/JS) or ```{{_ i18n_key}}``` (in Blaze Spacebar. Remember to wrap the i18n_key with quotes```"your_i18n_key"``` if the key isn't a variable.)

For places where placeholder concept is applied (e.g. schema, context menu items, etc),  a ```label``` (or ```title```/```txt```) property is defined for each item. When translating those components, please use ```APP.justdo_i18n.getI18nTextOrFallback({fallback_text, i18n_key})``` to ensure the UI will still show English text even if i18n breaks for any reason.

Pleaese also remember to add the following dependencies into the target package's (say justdo-orgs) *package.js*:
```
api.use("tap:i18n@1.8.2", both);
api.use("justdoinc:justdo-i18n", both);
```