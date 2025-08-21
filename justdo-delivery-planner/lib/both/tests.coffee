# _.extend JustdoDeliveryPlanner.prototype,
#   testBoth: ->
#     @testCrv()

#     return

#   testCrv: ->
#     names_prefix = "delivery-planner: getAllProjectsGroupedByProjectsCollectionsUnderJustdo: "
    
#     CrvUnitTests = JustdoHelpers.newTestCase "#{names_prefix} basic plumbing",
#       setUp: (test_context) ->
#         console.log("setUp")
#         return

#       tearDown: (test_context) ->
#         console.log("tearDown")
#         return

#     # CrvUnitTests.addTest "test non-department no-projects returns an empty object", ->
#     #   # @testOnNewJd({options necessary for templating to create a new JD, will diffrentiate between server side and client (if templating doesn't fit can use the framework in use by excel import)}, () => following the completion of this cb - must remove the JD (need to think about orgs picking)

#     #   #   if Meteor.isClient
#     #   #     @assertEqual(APP.justdo_delivery_planner.getAllProjectsGroupedByProjectsCollectionsUnderJustdo(), {})
#     #   #   else
#     #   #     @assertEqual(APP.justdo_delivery_planner.getAllProjectsGroupedByProjectsCollectionsUnderJustdo(created_jd_id), {})
#     #   # )
#     #   return

#     # CrvUnitTests.addTest "test empty department returned", ->
#     #   return

#     # CrvUnitTests.addTest "test empty department due to full filtering of children returned", ->
#     #   return

#     # CrvUnitTests.addTest "test a department that remained empty, following pruning doesn't have sub_pcs", ->
#     #   return

#     CrvUnitTests.run()

#     return