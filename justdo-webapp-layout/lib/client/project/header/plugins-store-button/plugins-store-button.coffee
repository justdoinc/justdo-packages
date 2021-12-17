plugins_store_dialog = "plugins-store-dialog"

removeActivePluginStore = ->
  $(".#{plugins_store_dialog}")?.data("bs.modal")?.hide()

  return

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.plugins_store_button.helpers module.template_helpers

  Template.plugins_store_button.helpers
    showStore: ->
      if (ui_customizations = APP.env_rv.get()?.UI_CUSTOMIZATIONS)?
        return ui_customizations.indexOf("no-store") == -1

      return true

  Template.plugins_store_button.events
    "click #project-plugins-store-button": ->
      data =
        store_manager: APP.justdo_plugin_store.getPluginsStoreManager()

      message_template =
        APP.helpers.renderTemplateInNewNode(Template.plugins_store_layout, data)

      bootbox.dialog
        title: "Plugins Store"
        message: message_template.node
        className: plugins_store_dialog

        onEscape: ->
          return true

      return

  Template.plugins_store_button.onDestroyed ->
    removeActivePluginStore()

    return