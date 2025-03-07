(function() {
  var justdoLabsFeaturesEnabled = function () {
    return APP.justdo_labs_features_enabled_rv.get();
  };

  // for convenience
  var loginButtonsSession = Accounts._loginButtonsSession;

  // events shared between loginButtonsLoggedOutDropdown and
  // loginButtonsLoggedInDropdown
  Template._loginButtons.events({
    'click .dropdown-menu, click input, click .radio, click .checkbox, click option, click select': function(event) {
      event.stopPropagation();
    },
    'click #login-name-link, click #login-sign-in-link': function(event) {
      event.stopPropagation();
      loginButtonsSession.set('dropdownVisible', true);
      Tracker.flush();
    },
    'click .login-close': function() {
      loginButtonsSession.closeDropdown();
    }
  });

  Template._loginButtons.onRendered(function () {
    $('#login-dropdown-list').on('hide.bs.dropdown', function () {
      Accounts._loginButtonsSession.closeDropdown();
    });
  });


  Template._loginButtons.toggleDropdown = function() {
    toggleDropdown();
    focusInput();
  };

  //
  // loginButtonsLoggedInDropdown template and related
  //

  Template._loginButtonsLoggedInDropdown.events({
    'click .login-buttons-global-settings': function(event) {
      event.stopPropagation();
      loginButtonsSession.resetMessages();
      loginButtonsSession.set('inSettingsEditingFlow', true);
      Tracker.flush();
    },

    'click .login-buttons-exit-global-settings': function(event) {
      event.stopPropagation();
      loginButtonsSession.resetMessages();
      loginButtonsSession.set('inSettingsEditingFlow', false);
      Tracker.flush();
    },

    'click .login-buttons-exit-change-password': function(event) {
      event.stopPropagation();
      loginButtonsSession.resetMessages();
      loginButtonsSession.set('inChangePasswordFlow', false);
      Tracker.flush();
    }
  });

  Template._loginButtonsLoggedInDropdown.helpers({
    displayName: function() {
      return Accounts._loginButtons.displayName();
    },

    inChangePasswordFlow: function() {
      return loginButtonsSession.get('inChangePasswordFlow');
    },

    inSettingsEditingFlow: function() {
      return loginButtonsSession.get('inSettingsEditingFlow');
    },

    inMessageOnlyFlow: function() {
      return loginButtonsSession.get('inMessageOnlyFlow');
    },

    dropdownVisible: function() {
      return loginButtonsSession.get('dropdownVisible');
    },

    userAvatarFields: function() {
      return Meteor.user({fields: JustdoAvatar.avatar_required_fields});
    },

    userHasProfilePic: function() {
      return JustdoHelpers.userHasProfilePic(Meteor.user());
    },

    user_profile_picture: function() {
      var user = Meteor.user();
      if (user && user.profile && user.profile.display_picture) {
        return user.profile.display_picture;
      }
      return "";
    }

  });


  Template._loginButtonsLoggedInDropdownActions.helpers({
    allowChangingPassword: function() {
      // it would be more correct to check whether the user has a password set,
      // but in order to do that we'd have to send more data down to the client,
      // and it'd be preferable not to send down the entire service.password document.
      //
      // instead we use the heuristic: if the user has a username or email set.
      var user = Meteor.user();
      return user.username || (user.emails && user.emails[0] && user.emails[0].address);
    },
    isAffiliate: function () {
      return APP.justdo_promoters_campaigns?.isCurrentUserPromoter();
    },
    additionalLoggedInDropdownActions: function() {
      return Template._loginButtonsAdditionalLoggedInDropdownActions !== undefined;
    },

    isMarketingEnvironment: function() {
      return env.LANDING_PAGE_TYPE === "marketing";
    },

    getUserLangIfNotDefault: function() {
      var lang = APP.justdo_i18n.getLang()
      if (lang && lang !== JustdoI18n.default_lang) {
        return lang;
      }
      return
    },

    justdoLabsFeaturesEnabled: justdoLabsFeaturesEnabled
  });

  Template._loginButtonsLoggedInDropdownActions.events({
    "click .affiliates-console-btn": function() {
      Router.go(JustdoAffiliatesProgram.plugin_page_id);

      return;
    },

    "click .info-btn-settings": function(e) {
      e.preventDefault();
    }
  });

  Template._loginButtonsFormField.helpers({
    equals: function(a, b) {
      return (a === b);
    },
    inputType: function() {
      return this.inputType || "text";
    },
    inputTextual: function() {
      return !_.contains(["radio", "checkbox", "select"], this.inputType);
    }
  });

  //
  // loginButtonsChangePassword template
  //
  Template._loginButtonsChangePassword.events({
    'keypress #login-old-password, keypress #login-password, keypress #login-password-again': function(event) {
      if (event.keyCode === 13){
        changePassword();
      }
    },
    'click #login-buttons-do-change-password': function(event) {
      event.stopPropagation();
      changePassword();
    },
    'click #login-buttons-cancel-change-password': function(event) {
      event.stopPropagation();
      loginButtonsSession.resetMessages();
      Accounts._loginButtonsSession.set('inChangePasswordFlow', false);
      Tracker.flush();
    }
  });

  Template._loginButtonsChangePassword.helpers({
    fields: function() {
      return [{
        fieldName: 'old-password',
        fieldLabel: TAPi18n.__("change_password_fields_current_password"),
        inputType: 'password',
        visible: function() {
          return true;
        }
      }, {
        fieldName: 'password',
        fieldLabel: TAPi18n.__("change_password_fields_new_password"),
        inputType: 'password',
        visible: function() {
          return true;
        }
      }, {
        fieldName: 'password-again',
        fieldLabel: TAPi18n.__("change_password_fields_new_password_again"),
        inputType: 'password',
        visible: function() {
          // No need to make users double-enter their password if
          // they'll necessarily have an email set, since they can use
          // the "forgot password" flow.
          return true;
          // return _.contains(
          //   ["USERNAME_AND_OPTIONAL_EMAIL", "USERNAME_ONLY"],
          //   Accounts.ui._passwordSignupFields());
        }
      }];
    }
  });

  //
  // helpers
  //

  var elementValueById = function(id) {
    var element = document.getElementById(id);
    if (!element){
      return null;
    } else {
      return element.value;
    }
  };

  var elementValueByIdForRadio = function(fieldIdPrefix, radioOptions) {
    var value = null;
    for (i in radioOptions) {
      var element = document.getElementById(fieldIdPrefix + '-' + radioOptions[i].id);
      if (element && element.checked){
        value =  element.value;
      }
    }
    return value;
  };

  var elementValueByIdForCheckbox = function(id) {
    var element = document.getElementById(id);
    return element.checked;
  };

  var trimmedElementValueById = function(id) {
    var element = document.getElementById(id);
    if (!element){
      return null;
    } else {
      return element.value.replace(/^\s*|\s*$/g, ""); // trim;
    }
  };

  var toggleDropdown = function() {
    $("#login-dropdown-list").toggleClass("open");
  }

  var focusInput = function() {
    setTimeout(function() {
      $("#login-dropdown-list input").first().focus();
    }, 0);
  };

  var changePassword = function() {
    loginButtonsSession.resetMessages();
    // notably not trimmed. a password could (?) start or end with a space
    var oldPassword = elementValueById('login-old-password');
    // notably not trimmed. a password could (?) start or end with a space
    var password = elementValueById('login-password');

    if (password == oldPassword) {
      loginButtonsSession.errorMessage(TAPi18n.__("error_messages_new_password_same_as_old"));
      return;
    }

    if (!Accounts._loginButtons.validatePassword(password)){
      return;
    }

    if (!matchPasswordAgainIfPresent()){
      return;
    }

    Accounts.changePassword(oldPassword, password, function(error) {
      if (error) {
        if (error.reason == 'Incorrect password'){
          loginButtonsSession.errorMessage(TAPi18n.__("error_messages_incorrect_password"))
        } else {
          loginButtonsSession.errorMessage(error.reason || "Unknown error");
        }
      } else {
        loginButtonsSession.infoMessage(TAPi18n.__("info_messages_password_changed"));

        $("#login-old-password,#login-password,#login-password-again").val("")

        // wait 3 seconds, then expire the msg
        Meteor.setTimeout(function() {
          loginButtonsSession.resetMessages();
        }, 3000);
      }
    });
  };

  var matchPasswordAgainIfPresent = function() {
    // notably not trimmed. a password could (?) start or end with a space
    var passwordAgain = elementValueById('login-password-again');
    if (passwordAgain !== null) {
      // notably not trimmed. a password could (?) start or end with a space
      var password = elementValueById('login-password');
      if (password !== passwordAgain) {
        loginButtonsSession.errorMessage(TAPi18n.__("error_messages_passwords_dont_match"));
        return false;
      }
    }
    return true;
  };
})();
