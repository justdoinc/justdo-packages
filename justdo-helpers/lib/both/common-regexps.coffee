_.extend JustdoHelpers,
  common_regexps:
    # We use the RegExp suggested by W3C in http://www.w3.org/TR/html5/forms.html#valid-e-mail-address
    # This is probably the same logic used by most browsers when type=email, which is our goal. It is
    # a very permissive expression. Some apps may wish to be more strict and can write their own RegExp.
    # (Taken from SimpleSchema.RegEx.Email)
    email: /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
