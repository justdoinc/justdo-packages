ProjectPageDialogs.selectMultipleProjectUsers = (options, cb) ->
  default_options =
    title: "Select user"
    selected_users: [Meteor.userId()]
    submit_label: "Select member"
    none_selected_text: "Nothing selected2"

  options = _.extend default_options, options

  message_template =
    APP.helpers.renderTemplateInNewNode(Template.select_multiple_project_members_dialog, {title: options.title, none_selected_text: options.none_selected_text, selected_users: options.selected_users})

  bootbox.dialog
    title: options.title
    message: message_template.node
    animate: false
    className: "select-multiple-project-users-dialog bootbox-new-design"

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
          cb($("select.select-multiple-project-members-dialog-selector").val() or [])

          return true

  return

APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.select_multiple_project_members_dialog_selector.onCreated ->
    @selected_users = @data.selected_users
    @none_selected_text = @data.none_selected_text

    return

  # Add our common template helpers to your template
  Template.select_multiple_project_members_dialog_selector.helpers module.template_helpers

  Template.select_multiple_project_members_dialog_selector.helpers
    isSelectedUser: ->
      tpl = Template.instance()

      return @_id in tpl.selected_users

  Template.select_multiple_project_members_dialog_selector.onRendered ->
    $(".select-multiple-project-members-dialog-selector")
      .selectpicker
        container: "body"
        liveSearch: true
        dropupAuto: true
        size: 8
        noneSelectedText: @none_selected_text

    @autorun =>
      module.template_helpers.project_all_members_sorted_by_first_name()

      Meteor.defer =>
        # Refresh the selectpicker when members list or members values changes (need to defer to let blaze update the dom first)
        $(".select-multiple-project-members-dialog-selector").selectpicker("refresh")

      return

    return

  Template.select_multiple_project_members_dialog_selector.onDestroyed ->
    $("div.select-multiple-project-members-dialog-selector").selectpicker("destroy")

    # .selectpicker("destroy") won't if the original <select> removed, so remove the component
    # directly to make sure its removed.
    $("div.select-multiple-project-members-dialog-selector").remove()

    return