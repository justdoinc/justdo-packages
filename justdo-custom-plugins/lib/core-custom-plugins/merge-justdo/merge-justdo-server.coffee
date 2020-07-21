# Here implement a meteor method that 

# Meteor.method "jdCustomMergeJustdo", (source_justdo_id, target_justdo_id) ->
#   check String..
#
#   Ensure @userId is admin of both source and target.
#
#   Create a new task under target subject "Merged from #{source_justdo_id title}"
#
#   All the tasks of source need to update project_id to target, allocate new seqIds
#   take care of dependencies seqId as well.
#
#   When allocating seqId remember to update the target_justdo.lastTaskSeqId <- use mongo $inc
#   the amount of tasks you are going to move before moving them.
#
#   Then play with *all* JustDo plugins - files, 
#
#   return