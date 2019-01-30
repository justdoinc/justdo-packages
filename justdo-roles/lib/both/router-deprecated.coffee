# Initial attempt was made to add roles as a separate page, it truned out to
# be more time consuming than expected, so the idea abandoned, in the future
# though it might turn out to be useful for organization-level roles/groups
# management, so code is left here.
#
# To bring back, add @setupRouter() to initImmediate() of both/init.coffee
#
# Also, add back the files under the client/plugin-page-deprecated to the package.js

_.extend JustdoRoles.prototype,
  setupRouter: ->
    Router.route '/p/:_id/roles', ->
      APP.page_title_manager.setPageName "JustDo Roles" # project template sets later page name according to proj title

      if APP.login_state.initial_user_state_ready_rv.get() == true
        try
          @project_id = @params._id
        catch e
          logger.error e
          return @redirect "/"

        @render 'justdo_roles_page'

        return

      @render 'loading'

      return
    ,
      name: 'justdo_roles_page'

    return