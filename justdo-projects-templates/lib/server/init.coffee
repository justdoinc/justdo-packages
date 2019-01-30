_.extend JustDoProjectsTemplates.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in allow-deny.coffee
    @_setupAllowDenyRules()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return
#
# # TEMPORARY: Test code for project
# Meteor.startup () =>
#   try
#     project_id = "SBcMGnKABajwanMet"
#     user_id = "d77PMEWFR5MD6nnL5"
#     template =
#       users: ["manager", "employee"]
#       tasks: [
#         title: "Task"
#         users: ["manager"]
#         perform_as: "manager"
#         tasks: [
#           title: "Child Task"
#           users: ["manager", "employee"]
#           owner: "employee"
#         ,
#           title: "Child Task 2"
#           users: ["manager", "employee"]
#           owner: "manager"
#           parents: ["other"]
#           events: [
#             action: "setPendingOwner"
#             args: "employee"
#           ,
#             action: "setDueDate"
#             args: "2017-05-19"
#           ,
#             action: "update"
#             args:
#               $set:
#                 description: "<p>Do X</p>"
#           ,
#             action: "setOwner"
#             args: "employee"
#             perform_as: "employee"
#           ,
#             action: "setStatus"
#             args: "Test status message"
#             perform_as: "employee"
#           ,
#             action: "setState"
#             args: "in-progress"
#             perform_as: "employee"
#           ,
#             action: "setFollowUp"
#             args: "2017-05-08"
#             perform_as: "employee"
#           ,
#             action: "removeParents"
#             args: ["other"]
#             perform_as: "manager"
#           ,
#             action: "addParents"
#             args: ["mytasks"]
#             perform_as: "employee"
#           ]
#         ]
#       ,
#         title: "Other Task"
#         key: "other"
#         perform_as: "employee"
#       ,
#         title: "My Tasks"
#         key: "mytasks"
#         perform_as: "employee"
#       ]
#
#     APP.justdo_projects_templates.createSubtreeFromTemplateUnsafe
#       project_id: project_id
#       template: template
#       root_task_id: "S5hkTr7RZeWrrhkd3"
#       users:
#         manager: user_id
#         employee: "sandbox_user_Joe_Sandbox"
#   catch e
#     console.warn e.stack
