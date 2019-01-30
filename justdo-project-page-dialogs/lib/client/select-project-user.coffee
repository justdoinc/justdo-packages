ProjectPageDialogs.selectProjectUser = (options, cb) ->
  default_options =
    title: "Select user"
    selected_user: Meteor.userId()
    submit_label: "Select member"

  options = _.extend default_options, options

  message_template =
    APP.helpers.renderTemplateInNewNode(Template.select_project_member_dialog, {title: options.title, selected_user: options.selected_user})

  bootbox.dialog
    title: options.title
    message: message_template.node
    animate: false
    className: "select-project-user-dialog bootbox-new-design"

    onEscape: ->
      return true

    buttons:
      cancel:
        label: "Cancel"

        className: "btn-default"

        callback: ->
          cb(null)

          return true

      submit:
        label: options.submit_label
        callback: =>
          cb($("select.select-project-member-dialog-selector").val())

          return true

  return

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.select_project_member_dialog_selector.onCreated ->
    @selected_user = @data.selected_user

    return

  # Add our common template helpers to your template
  Template.select_project_member_dialog_selector.helpers module.template_helpers

  Template.select_project_member_dialog_selector.helpers
    isSelectedUser: ->
      tpl = Template.instance()

      return tpl.selected_user == @_id

  Template.select_project_member_dialog_selector.onRendered ->
    $(".select-project-member-dialog-selector")
      .selectpicker
        container: "body"
        liveSearch: true
        dropupAuto: true
        size: 8

    @autorun =>
      module.template_helpers.project_all_members_sorted_by_first_name()

      Meteor.defer =>
        # Refresh the selectpicker when members list or members values changes (need to defer to let blaze update the dom first)
        $(".select-project-member-dialog-selector").selectpicker("refresh")

      return

    return

  Template.select_project_member_dialog_selector.onDestroyed ->
    $("div.select-project-member-dialog-selector").selectpicker("destroy")

    # .selectpicker("destroy") won't if the original <select> removed, so remove the component
    # directly to make sure its removed.
    $("div.select-project-member-dialog-selector").remove()

    return