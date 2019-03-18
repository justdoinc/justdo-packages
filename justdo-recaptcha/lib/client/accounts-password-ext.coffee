_.extend JustdoRecaptcha.prototype,
  addJustdoAccountsPasswordExtensions: ->
    # The following modifies Meteor's account-password package methods for
    # our needs.
    #
    # The code below was taken from Meteor v1.6.0.1
    #
    # meteor/meteor commit: 5533aa7ce86f8cbeb8e770ebeb9fb5909b399b1f
    #
    # The places where we diverted from the original code is enclosed with
    #
    # #### <JUSTDO CHANGES>
    # #### </JUSTDO CHANGES>

    ```
    // Used in the various functions below to handle errors consistently
    function reportError(error, callback) {
       if (callback) {
         callback(error);
       } else {
         throw error;
       }
    };

    // XXX COMPAT WITH 0.8.1.3
    // The server requested an upgrade from the old SRP password format,
    // so supply the needed SRP identity to login. Options:
    //   - upgradeError: the error object that the server returned to tell
    //     us to upgrade from SRP to bcrypt.
    //   - userSelector: selector to retrieve the user object
    //   - plaintextPassword: the password as a string
    var srpUpgradePath = function (options, callback) {
      var details;
      try {
        details = EJSON.parse(options.upgradeError.details);
      } catch (e) {}
      if (!(details && details.format === 'srp')) {
        reportError(
          new Meteor.Error(400, "Password is old. Please reset your " +
                           "password."), callback);
      } else {
        Accounts.callLoginMethod({
          methodArguments: [{
            user: options.userSelector,
            srp: SHA256(details.identity + ":" + options.plaintextPassword),
            password: Accounts._hashPassword(options.plaintextPassword)
          }],
          userCallback: callback
        });
      }
    };

    /**
     * @summary Log the user in with a password.
     * @locus Client
     * @param {Object | String} user
     *   Either a string interpreted as a username or an email; or an object with a
     *   single key: `email`, `username` or `id`. Username or email match in a case
     *   insensitive manner.
     * @param {String} password The user's password.
     * @param {Function} [callback] Optional callback.
     *   Called with no arguments on success, or with a single `Error` argument
     *   on failure.
     * @importFromPackage meteor
     */
    Meteor.loginWithPassword = function (selector, password, callback) {
      if (typeof selector === 'string')
        if (selector.indexOf('@') === -1)
          selector = {username: selector};
        else
          selector = {email: selector};

      Accounts.callLoginMethod({
        methodArguments: [{
          user: selector,
          password: Accounts._hashPassword(password)
        }],
        userCallback: function (error, result) {
          if (error && error.error === 400 &&
              error.reason === 'old password format') {
            // The "reason" string should match the error thrown in the
            // password login handler in password_server.js.

            // XXX COMPAT WITH 0.8.1.3
            // If this user's last login was with a previous version of
            // Meteor that used SRP, then the server throws this error to
            // indicate that we should try again. The error includes the
            // user's SRP identity. We provide a value derived from the
            // identity and the password to prove to the server that we know
            // the password without requiring a full SRP flow, as well as
            // SHA256(password), which the server bcrypts and stores in
            // place of the old SRP information for this user.
            srpUpgradePath({
              upgradeError: error,
              userSelector: selector,
              plaintextPassword: password
            }, callback);
          }
          else if (error) {
            reportError(error, callback);
          } else {
            callback && callback();
          }
        }
      });
    };
    
    ```

    @logger.debug "Meteor.loginWithPassword replaced"

    return
