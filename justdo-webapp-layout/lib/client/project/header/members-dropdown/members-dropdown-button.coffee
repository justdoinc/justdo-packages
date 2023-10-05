APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.members_dropdown_button.helpers module.template_helpers
  Template.members_dropdown_button.onRendered ->
    share.members_dropdown = new share.MembersDropdown @find("#project-members-dropdown") # defined in ./members-dropdown-menu/members-dropdown-menu.coffee

    return

  Template.members_dropdown_button.onDestroyed ->
    share.members_dropdown?.destroy()

    return
