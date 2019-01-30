# Uncomment if you want to log events to JustdoAnalytics in your package

JustdoAnalytics.registerLogs "core", [
  {
    action_id: "tab-load"
    description: "Called when the browser tab is loaded. Note, when the user is being redirected from the landing app following sign-in, the attached state might not have UID, state will be set with UID when the login-state:post-sign-in-redirect-completed log will fire."
  }
  {
    action_id: "connection-closed"
    description: "Callen when the DDP connection is closed. Note, connection close doesn't mean the session end (e.g. user might refresh the page, or we might push new version that will trigger refresh). Server failure might result in this event not logging - so avoid counting on its reliability too much."
  }
  {
    action_id: "migration-reload"
    description: "Client reloaded due to a deploy of a new version"
  }
  {
    action_id: "404-route"
    description: "Called when Router.current()._handled is false. Val is the 404 url"
  }
  {
    action_id: "load-route"
    description: "Called when on IronRouter route load. Val is 'route-name|full-url'"
  }
  {
    action_id: "sign-in"
    description: "User signed in"
  }
  {
    action_id: "sign-out"
    description: "User signed out"
  }
  {
    action_id: "special-user-state"
    description: "User is inside one of the special user states, val will be the user state: email-verification|user-id, email-verification-expired, reset-password|user-id, reset-password-expired, enrollment|user-id, enrollment-expired."
  }
  { # Implemented in each one of the apps and not in this package
    action_id: "redirect-jd-env"
    description: "Called when the user is redirected to another JustDo environment (e.g from web-app to landing page after sign-out)"
  }
]

# Due to problematic circular dependencies, the logs of the package justdo-login-state
# are defined here
JustdoAnalytics.registerLogs "core", [
  {
    action_id: "post-sign-in-redirect-processing"
    description: "Called following a post-sign-in redirection to the web app, before processing of the sign-in token begin."
  }
  {
    action_id: "post-sign-in-redirect-completed"
    description: "Called following a post-sign-in redirection from the landing app."
  }
]