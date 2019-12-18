APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  fontAwesomeIconTag = (icon_id) -> '<i class="fa ' + icon_id + '"></i>'
  svgIconTag = (icon_id) -> '<svg class="jd-icon jd-c-pointer text-dark"><use xlink:href="/layout/icons-feather-sprite.svg#' + icon_id + '/></svg>'

  Template.project_operations_tab_switcher.helpers
    ready: -> module.getCurrentTabId()?

    getCurrentTabIcon: ->
      unknown_tab_icon = fontAwesomeIconTag("fa-question-circle")
      loading_tab_icon = '<i class="fa fa-spinner fa-spin"></i>'

      if module.getCurrentTabState() == "loading"
        return loading_tab_icon

      tab_id = module.getCurrentTabId()

      sections_state = module.getCurrentTabSectionsState()

      if tab_id == "main"
        return fontAwesomeIconTag("fa-th-large")
      else if tab_id == "recent-updates"
        if not (tracked_field = sections_state?.global?["tracked-field"])?
          return unknown_tab_icon

        if tracked_field == "state_updated_at"
          return fontAwesomeIconTag("fa-check")
        else if tracked_field == "updatedAt"
          return fontAwesomeIconTag("fa-newspaper-o")
        else if tracked_field == "createdAt"
          return fontAwesomeIconTag("fa-plus")
        else
          return unknown_tab_icon
      else if tab_id == "sub-tree"
        return fontAwesomeIconTag("fa-briefcase")
      else if tab_id == "jdp-all-projects"
        return fontAwesomeIconTag("fa-briefcase")
      else if tab_id == "jwp-term"
        return fontAwesomeIconTag("fa-sliders")
      else if tab_id == "jwp-member"
        return fontAwesomeIconTag("fa-users")
      else if tab_id == "awaiting-transfer"
        return fontAwesomeIconTag("fa-exchange")
      else if tab_id == "tickets-queues"
        return fontAwesomeIconTag("fa-sticky-note-o")
      else if tab_id == "due-list"
        if not (owners = sections_state?.global?.owners)?
          return unknown_tab_icon

        if owners in ["*", ""]
          # In both cases, we fetch all owners
          return fontAwesomeIconTag("fa-users")

        owners = owners.split(",")

        if owners.length == 1
          owner = owners[0]

          if owner == Meteor.userId()
            return fontAwesomeIconTag("fa-calendar-check-o")
          else if (owner_doc = Meteor.users.findOne(owner))?
            rendered_user_avatar =
              JustdoHelpers.renderTemplateInNewNode("gtpl_user_profile_pic", owner_doc)

            rendered_user_avatar_node = rendered_user_avatar.node

            html = $(rendered_user_avatar_node).html()

            rendered_user_avatar.destroy()

            return html
          else
            return unknown_tab_icon
        else
          # For now we don't have different icon for all users and partial users
          return fontAwesomeIconTag("fa-users")
      else
        return unknown_tab_icon

      return
