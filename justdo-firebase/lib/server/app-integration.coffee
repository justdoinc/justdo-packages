if process.env.FIREBASE_ENABLED == "true"
  APP.justdo_firebase = new JustdoFirebase
    server_key: process.env.FIREBASE_SERVER_KEY
else
  APP.justdo_firebase =
    isEnabled: -> false
