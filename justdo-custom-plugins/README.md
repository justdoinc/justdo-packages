## To install/remove a custom plugin from the browser console (as a JustDo admin):

*Ensure that you are inside the JustDo in which you want to perform the install/remove*.

### Install:

custom_plugin_id = "custom_start_date_end_date_auto_setter";
APP.modules.project_page.curProj().enableCustomFeatures(custom_plugin_id)

### Remove:


custom_plugin_id = "custom_start_date_end_date_auto_setter";
APP.modules.project_page.curProj().disableCustomFeatures(custom_plugin_id)