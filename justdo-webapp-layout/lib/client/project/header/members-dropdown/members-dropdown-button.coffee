APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  Template.members_dropdown_button.helpers module.template_helpers

  members_dropdown = null

  Template.members_dropdown_button.onRendered ->
    members_dropdown = new module.ProjectMembersDropdown(@firstNode)  # defined in ./members-dropdown-menu/members-dropdown-menu.coffee

  Template.members_dropdown_button.onDestroyed ->
    if members_dropdown?
      members_dropdown.destroy()
      members_dropdown = null
