APP.executeAfterAppLibCode ->
  module = APP.modules.project_page

  curProj = -> module.curProj()

  Template.justdo_roles_and_groups_manager.helpers
    getCurrentTab: ->
      return @roles_and_groups_manager_controller.getCurrentTab()

  Template.justdo_roles_and_groups_manager.events
    "click .nav-pills a": (e, tpl) ->
      @roles_and_groups_manager_controller.setCurrentTab($(e.target).attr("aria-controls"))

      return

  Template.justdo_roles_and_groups_manager_footer.helpers
    getCurrentTab: ->
      return @roles_and_groups_manager_controller.getCurrentTab()

  Template.justdo_roles_and_groups_manager_footer.events
    "click .modal-footer .btn": (e, tpl) ->
      # To prevent bootbox from handling
      e.stopPropagation()

      return

    "click .add-new-region": (e, tpl) ->
      default_value = "New region"
      bootbox.prompt
        title: "Pick a name for the new region"
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        closeButton: false
        value: ""

        callback: (result) =>
          if not result?
            # Cancel clicked
            return

          if _.isEmpty(result)
            result = default_value

          @roles_and_groups_manager_controller.addRegion({label: result})

          return

      return

    "click .add-new-role": (e, tpl) ->
      default_value = "New role"
      bootbox.prompt
        title: "Pick a name for the new role"
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        closeButton: false
        value: ""

        callback: (result) =>
          if not result?
            # Cancel clicked
            return

          if _.isEmpty(result)
            result = default_value

          @roles_and_groups_manager_controller.addRole({label: result})

          return

      return

    "click .add-new-group": (e, tpl) ->
      default_value = "New group"
      bootbox.prompt
        title: "Pick a name for the new group"
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        closeButton: false
        value: ""

        callback: (result) =>
          if not result?
            # Cancel clicked
            return

          if _.isEmpty(result)
            result = default_value

          @roles_and_groups_manager_controller.addGroup({label: result})

          return
      return

    "click .cancel": (e, tpl) ->
      @closeRolesAndGroupsManagerDialog()

      return


    "click .save-and-close, click .save": (e, tpl) ->
      if $(e.target).hasClass("save-and-close")
        close = true
      else
        close = false
      
      if @roles_and_groups_manager_controller.user_has_full_privileges
        APP.justdo_roles.setProjectRolesAndGroups curProj().id, @roles_and_groups_manager_controller.getObjForSetProjectRolesAndGroupsMethod(), (err) =>
          if err?
            alert(err)

            return

          if close
            @closeRolesAndGroupsManagerDialog()

          return

      else
        APP.justdo_roles.performRegionalManagerEdits curProj().id, @roles_and_groups_manager_controller.getEditsArrayForPerformRegionalManagerEditsMethod(), (err) =>
          if err?
            alert(err)

            return

          if close
            @closeRolesAndGroupsManagerDialog()

          return

      return

  Template.justdo_roles_and_groups_manager_table_regions_header.helpers
    getCurrentTab: ->
      return @roles_and_groups_manager_controller.getCurrentTab()

    getRegionManagersCount: -> @getManagers().length

  Template.justdo_roles_and_groups_manager_table_regions_header.events
    "click .remove-region": (e, tpl) ->
      bootbox.confirm
        message: "Are you sure you want to remove the region?"
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        closeButton: false

        callback: (result) =>
          if result
            @removeRegion()

          return

      return

    "click .edit-region-label": (e, tpl) ->
      bootbox.prompt
        title: "Pick a new name for the region"
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        closeButton: false
        value: @getLabel()

        callback: (result) =>
          if result? and not _.isEmpty(result)
            @setLabel(result)

          return

      return

    "click .regional-managers-controller-block": (e, tpl) ->
      managers_selector_options = 
        title: "Set the #{@getLabel()} region, regional managers"
        selected_users: @getManagers()
        submit_label: "Set managers"
        none_selected_text: "No regional managers"

      ProjectPageDialogs.selectMultipleProjectUsers managers_selector_options, (res) =>
        if _.isArray(res)
          @setManagers(res)

        return

      return

  Template.justdo_roles_and_groups_manager_roles.events
    "click .remove-role": (e, tpl) ->
      bootbox.confirm
        message: "Are you sure you want to remove this role?"
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        closeButton: false

        callback: (result) =>
          if result
            @removeRole()

          return

      return

    "click .edit-role-label": (e, tpl) ->
      bootbox.prompt
        title: "Pick a new name for the role"
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        closeButton: false
        value: @getLabel()

        callback: (result) =>
          if result? and not _.isEmpty(result)
            @setLabel(result)

          return

      return

    "click .edit-role-member": ->
      @setUser()

      return

    "click .set-role-member": ->
      @setUser()

      return

    "click .remove-role-member": ->
      @clearRegionValue()

      return


  Template.justdo_roles_and_groups_manager_groups.events
    "click .remove-group": (e, tpl) ->
      bootbox.confirm
        message: "Are you sure you want to remove this group?"
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        closeButton: false

        callback: (result) =>
          if result
            @removeGroup()

          return

      return

    "click .edit-group-label": (e, tpl) ->
      bootbox.prompt
        title: "Pick a new name for the group"
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        closeButton: false
        value: @getLabel()

        callback: (result) =>
          if result? and not _.isEmpty(result)
            @setLabel(result)

          return

      return

    "click .edit-group-member": ->
      @setUsers()

      return

    "click .set-group-members": ->
      @setUsers()

      return

    "click .clear-all-group-members": ->
      bootbox.confirm
        message: "Are you sure you want to remove all the members?"
        className: "bootbox-new-design bootbox-new-design-simple-dialogs-default"
        closeButton: false

        callback: (result) =>
          if result
            @clearRegionValue()

          return

      return

    "click .remove-group-member": ->
      @removeUser()

      return