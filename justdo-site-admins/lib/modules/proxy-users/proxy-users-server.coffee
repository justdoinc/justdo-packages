# Schema that defines what properties can be updated for proxy users
proxy_user_update_schema = new SimpleSchema
  profile:
    type: Object
    optional: true
  
  # Reuse the user profile schema by picking the fields we want to allow editing
  # First and last names
  "profile.first_name": JustdoAccounts.user_profile_schema._schema.first_name
  "profile.last_name": JustdoAccounts.user_profile_schema._schema.last_name
  
  # Avatar colors
  "profile.avatar_fg": JustdoAccounts.user_profile_schema._schema.avatar_fg
  "profile.avatar_bg": JustdoAccounts.user_profile_schema._schema.avatar_bg
  
  # Email field
  email:
    type: String
    optional: true
    regEx: JustdoHelpers.common_regexps.email

_.extend JustdoSiteAdmins.modules["proxy-users"],
  serverDeferredInit: ->
    self = @

    Meteor.methods
      saSetAsProxyUsers: (user_ids) ->
        check @userId, String
        if _.isString user_ids
          user_ids = [user_ids]
        check user_ids, [String]
        self.requireUserIsSiteAdmin @userId

        query =
          _id:
            $in: user_ids

        options =
          fields:
            deactivated: 1
            "site_admin.is_site_admin": 1

        users = Meteor.users.find(query, options).fetch()

        for user in users
          if user.site_admin?.is_site_admin
            throw self._error "not-supported", "Cannot set a site admin as a proxy user."

          if user.deactivated
            throw self._error "not-supported", "Cannot set a deactivated user as a proxy user."

        Meteor.users.update query, {$set: {is_proxy: true}}, {multi: true}
        APP.accounts.removeUserAvatar user_ids

        return

      saUnsetAsProxyUsers: (user_ids) ->
        check @userId, String
        if _.isString user_ids
          user_ids = [user_ids]
        check user_ids, [String]
        self.requireUserIsSiteAdmin @userId

        Meteor.users.update {_id: {$in: user_ids}}, {$unset: {is_proxy: 1}}, {multi: true}
        return
        
      # Update properties of a proxy user
      # This method allows site admins to modify proxy user details such as 
      # first name, last name, email, and avatar appearance. Only site admins can use this method,
      # and it can only be used on users that have the is_proxy flag set.
      saUpdateProxyUser: (proxy_user_id, properties) ->
        check @userId, String
        check proxy_user_id, String
        
        # Validate properties against schema
        {cleaned_val} = JustdoHelpers.simpleSchemaCleanAndValidate(
          proxy_user_update_schema,
          properties,
          {self: self, throw_on_error: true}
        )
        properties = cleaned_val
        
        # Verify the user is a site admin
        self.requireUserIsSiteAdmin @userId
        
        # Verify the target is a proxy user and fetch current profile and email
        proxy_user = Meteor.users.findOne {_id: proxy_user_id}, {fields: {is_proxy: 1, profile: 1, emails: 1}}
        unless proxy_user?.is_proxy
          throw self._error "not-supported", "Can only update properties for proxy users."
        
        # Track if we need to update the avatar
        need_avatar_update = false
        
        # Prepare the update object for profile properties
        update_obj = {}
        
        # Handle profile properties
        if properties.profile
          profile = properties.profile
          current_profile = proxy_user.profile or {}
          
          for key, value of profile
            if value? and value != current_profile[key]
              update_obj["profile.#{key}"] = value
              
              # Check if this change affects avatar
              if key in ["first_name", "last_name", "avatar_fg", "avatar_bg"]
                need_avatar_update = true
        
        # Handle email update
        if properties.email?
          current_email = proxy_user.emails?[0]?.address
          new_email = properties.email
          
          # Only update if email has changed
          if new_email != current_email
            # Check if email is already taken by another user
            existing_user = Accounts.findUserByEmail(new_email)
            if existing_user and existing_user._id != proxy_user_id
              throw self._error "email-exists", "Email is already in use by another user."
              
            # Add email update to our update object
            update_obj["emails.0.address"] = new_email
        
        # Return early if no properties to update
        return if _.isEmpty update_obj
          
        # Update all the proxy user's properties in one operation
        Meteor.users.update {_id: proxy_user_id}, {$set: update_obj}
        
        # Handle special cases that require additional processing
        
        # For proxy users, we know they use initials-based avatars
        # Just skip the avatar update check since these methods are client-only
        # The avatar will update automatically when users view the profile
          
        return

    return
