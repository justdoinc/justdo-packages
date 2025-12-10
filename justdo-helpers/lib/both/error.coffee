_.extend JustdoHelpers,
  produceError: (chance, message = "fatal", details = "") ->
    if (chance > 1) or (chance < 0)
      throw new Meteor.Error("invalid-argument", "Chance must be between 0 and 1")

    if chance >= Math.random() # `Math.random()` returns a value between 0 and 1
      throw new Meteor.Error(message, details)
      
    return
