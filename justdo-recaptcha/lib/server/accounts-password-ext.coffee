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

    # Remove existing accounts password handlers

    # First find the existing ones
    accouns_password_indexes = []
    for handler, i in Accounts._loginHandlers
      if handler.name == "password"
        accouns_password_indexes.push i

    # If there is more than one "password" handler, we assume the ones other
    # than the first one are handling obsolete cases (srp like cases). We
    # remove them.
    while accouns_password_indexes.length > 1
      i = accouns_password_indexes.pop()

      Accounts._loginHandlers.splice(i, 1)

    # Perform the replacement

    ```
    ///
    /// ERROR HANDLER
    ///
    const handleError = (msg, throwError = true) => {
      const error = new Meteor.Error(
        403, 
        Accounts._options.ambiguousErrorMessages
          ? "Something went wrong. Please check your credentials."
          : msg
      );
      if (throwError) {
        throw error;
      }
      return error;
    };

    var userQueryValidator = Match.Where(function (user) {
      check(user, {
        id: Match.Optional(NonEmptyString),
        username: Match.Optional(NonEmptyString),
        email: Match.Optional(NonEmptyString)
      });
      if (_.keys(user).length !== 1)
        throw new Match.Error("User property must have exactly one field");
      return true;
    });

    var passwordValidator = Match.OneOf(
      String,
      { digest: String, algorithm: String }
    );

    // XXX maybe this belongs in the check package
    var NonEmptyString = Match.Where(function (x) {
      check(x, String);
      return x.length > 0;
    });

    // Handler to login with a password.
    //
    // The Meteor client sets options.password to an object with keys
    // 'digest' (set to SHA256(password)) and 'algorithm' ("sha-256").
    //
    // For other DDP clients which don't have access to SHA, the handler
    // also accepts the plaintext password in options.password as a string.
    //
    // (It might be nice if servers could turn the plaintext password
    // option off. Or maybe it should be opt-in, not opt-out?
    // Accounts.config option?)
    //
    // Note that neither password option is secure without SSL.
    //
    // #### <JUSTDO CHANGES>
    // # Removed: Accounts.registerLoginHandler("password", function (options) {
    Accounts._loginHandlers[accouns_password_indexes[0]] = {name: "password", handler: function (options) {
    // #### </JUSTDO CHANGES>
      if (! options.password || options.srp)
        return undefined; // don't handle

      check(options, {
        user: userQueryValidator,
        password: passwordValidator
      });


      var user = Accounts._findUserByQuery(options.user);
      if (!user) {
        handleError("User not found");
      }

      if (!user.services || !user.services.password ||
          !(user.services.password.bcrypt || user.services.password.srp)) {
        handleError("User has no password set");
      }

      if (!user.services.password.bcrypt) {
        if (typeof options.password === "string") {
          // The client has presented a plaintext password, and the user is
          // not upgraded to bcrypt yet. We don't attempt to tell the client
          // to upgrade to bcrypt, because it might be a standalone DDP
          // client doesn't know how to do such a thing.
          var verifier = user.services.password.srp;
          var newVerifier = SRP.generateVerifier(options.password, {
            identity: verifier.identity, salt: verifier.salt});

          if (verifier.verifier !== newVerifier.verifier) {
            return {
              userId: Accounts._options.ambiguousErrorMessages ? null : user._id,
              error: handleError("Incorrect password", false)
            };
          }

          return {userId: user._id};
        } else {
          // Tell the client to use the SRP upgrade process.
          throw new Meteor.Error(400, "old password format", EJSON.stringify({
            format: 'srp',
            identity: user.services.password.srp.identity
          }));
        }
      }

      return checkPassword(
        user,
        options.password
      );
    // #### <JUSTDO CHANGES>
    // # Removed: });
    }};
    // #### </JUSTDO CHANGES>

    var checkPassword = Accounts._checkPassword;

    ```

    @logger.debug "'password' login handler replaced; srp based 'password' handler removed."

    return
