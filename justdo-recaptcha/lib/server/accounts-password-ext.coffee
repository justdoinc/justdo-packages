_.extend JustdoRecaptcha.prototype,
  addJustdoAccountsPasswordExtensions: ->
    self = @

    # Note we don't call this method if recaptcha isn't supported for the environment,
    # leaving accounts-password code as-is

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
        password: passwordValidator,
        // #### <JUSTDO CHANGES> (and the comma in the end of the previous line)
        recaptcha: Match.Optional(self._verifyCaptchaCaptchaInputSchema)
        // #### </JUSTDO CHANGES>
      });

      var user = Accounts._findUserByQuery(options.user);
      if (!user) {
        handleError("User not found");
      }

      if (!user.services || !user.services.password ||
          !(user.services.password.bcrypt || user.services.password.srp)) {
        handleError("User has no password set");
      }

      // #### <JUSTDO CHANGES>

      ////////////////////////////////////////////////
      // COFFEE SCRIPT SOURCE FOR OUR MODIFICATIONS //
      ////////////////////////////////////////////////
      //
      // failed_login_attempts_field = "services.password.failed_login_attempts"

      // if not (failed_login_attempts = user.services?.password?.failed_login_attempts)?
      //   failed_login_attempts = 0
      // else
      //   # We got something in the db, get it and validate it
      //   if not _.isNumber(failed_login_attempts) or failed_login_attempts < 0
      //     # In the unlikely case where we encounter a non-number in the db, or a weird
      //     # number, we set the number to the max allowed number to show a captcha right
      //     # away.
      //     Meteor.users.update(user._id, {$set: {"#{failed_login_attempts_field}": self.max_attempts_without}})
        
      //     failed_login_attempts = self.max_attempts_without

      // recaptcha_passed = false
      // if options.recaptcha?
      //   # Note, if recaptcha provided, we test it regardless of whether we require
      //   # it or not, and fail if it is not required.
        
      //   # This allows clients provide us a captcha to test, in case a suspicous
      //   # activity is encountered by them.

      //   recaptcha_result = self.verifyCaptcha(this.connection.clientAddress, options.recaptcha)

      //   if not recaptcha_result.err?
      //     recaptcha_passed = true
          
      //     # Recaptcha passed, init failed_login_attempts_field
      //     Meteor.users.update(user._id, {$set: {"#{failed_login_attempts_field}": 0}})
      //   else
      //     handleError("Recaptcha failed: #{recaptcha_result.err.reason}");

      // if failed_login_attempts >= self.max_attempts_without and not recaptcha_passed
      //   handleError("recaptcha-required")

      // # Begin by adding 1 to the failed login attempts. No matter why we failed,
      // # we want a record that we failed.
      // Meteor.users.update(user._id, {$inc: {"#{failed_login_attempts_field}": 1}})

      var failed_login_attempts, failed_login_attempts_field, recaptcha_passed, recaptcha_result, ref, ref1;

      failed_login_attempts_field = "services.password.failed_login_attempts";

      if ((failed_login_attempts = (ref = user.services) != null ? (ref1 = ref.password) != null ? ref1.failed_login_attempts : void 0 : void 0) == null) {
        failed_login_attempts = 0;
      } else {
        // We got something in the db, get it and validate it
        if (!_.isNumber(failed_login_attempts) || failed_login_attempts < 0) {
          // In the unlikely case where we encounter a non-number in the db, or a weird
          // number, we set the number to the max allowed number to show a captcha right
          // away.
          Meteor.users.update(user._id, {
            $set: {
              [`${failed_login_attempts_field}`]: self.max_attempts_without
            }
          });
          failed_login_attempts = self.max_attempts_without;
        }
      }

      recaptcha_passed = false;

      if (options.recaptcha != null) {
        // Note, if recaptcha provided, we test it regardless of whether we require
        // it or not, and fail if it is not required.

        // This allows clients provide us a captcha to test, in case a suspicous
        // activity is encountered by them.
        recaptcha_result = self.verifyCaptcha(this.connection.clientAddress, options.recaptcha);
        if (recaptcha_result.err == null) {
          recaptcha_passed = true;
          
          // Recaptcha passed, init failed_login_attempts_field
          Meteor.users.update(user._id, {
            $set: {
              [`${failed_login_attempts_field}`]: 0
            }
          });
        } else {
          handleError(`Recaptcha failed: ${recaptcha_result.err.reason}`);
        }
      }

      if (failed_login_attempts >= self.max_attempts_without && !recaptcha_passed) {
        handleError("recaptcha-required");
      }

      // Begin by adding 1 to the failed login attempts. No matter why we failed,
      // we want a record that we failed.
      Meteor.users.update(user._id, {
        $inc: {
          [`${failed_login_attempts_field}`]: 1
        }
      });
      // #### </JUSTDO CHANGES>

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

      // #### <JUSTDO CHANGES>
      // return checkPassword(
      //   user,
      //   options.password
      // );

      var password_check_result = checkPassword(
        user,
        options.password
      );

      ////////////////////////////////////////////////
      // COFFEE SCRIPT SOURCE FOR OUR MODIFICATIONS //
      ////////////////////////////////////////////////
      //
      // if not password_check_result.error?
      //   # Successful login, remove failed login attempts count
      //   Meteor.users.update(user._id, {$unset: {"#{failed_login_attempts_field}": ""}})

      if (password_check_result.error == null) {
        // Successful login, remove failed login attempts count
        Meteor.users.update(user._id, {
          $unset: {
            [`${failed_login_attempts_field}`]: ""
          }
        });
      }

      return password_check_result;
    // # Removed: });
    }};
    // #### </JUSTDO CHANGES>

    var checkPassword = Accounts._checkPassword;

    ```

    @logger.debug "'password' login handler replaced; srp based 'password' handler removed."

    return
