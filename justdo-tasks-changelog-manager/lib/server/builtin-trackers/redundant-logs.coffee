_.extend PACK.builtin_trackers,
  redundantLogsTracker: ->
    self = @

    # self.changelog_collection.after.insert (userId, doc) ->
    #   if not (userId = doc.by)? # Derive userId from the doc by field and not from the arg above
    #                         # (by field must be set for all activities) to make sure activities
    #                         # originated from server ops will work properly 
    #     self.logger.warn "Couldn't find by field in added doc"
    #     return

    #   # here we want to avoid keeping multiple change logs
    #   # if they where done to the same field by the same user
    #   # and within only few minutes from each other... so if
    #   # the user found a typo or just changed his mind...
    #   # todo: also add here the ability to mark changes as insignificant
    #   threshold = new Date(new Date().getTime() - (2 * 60 * 1000));
    #   query =
    #     field: doc.field
    #     task_id: doc.task_id
    #     by: userId
    #     when:
    #       $gte: threshold
    #     _id:
    #       $ne: doc._id

    #   self.changelog_collection.remove query, (err, id) ->
    #     if err?
    #       self.logger.error(err)

    #       return

    #     # in the case of priority, if we delete priority updates, it might be that the description
    #     # of the current one (increased/decreased) is inaccurate, so here we will fix it...
    #     # todo: there is an edge case in which the priority is set to >0 when the task is created (for example
    #     # when we have a ticket queue item). In such case, there is no previous priority change log, so the logic below
    #     # will assume that the priority was 0 (which might not be the case) and will set the priority change to
    #     # 'increased' . AL.

    #     if doc.field == 'priority'
    #       # Find the previous priority change field....
    #       query =
    #         field: 'priority'
    #         task_id: doc.task_id
    #         when:
    #           $lte: doc.when
    #         _id:
    #           $ne: doc._id
    #       sort =
    #         when: -1

    #       previous_change = self.changelog_collection.findOne query, {sort: sort}

    #       if not previous_change?
    #         # If we have no previous change, then we need to make sure
    #         # the change_type is "priority_increased". Since, if the user
    #         # will increase and decrease the priority during threshold time
    #         # we'll end up with a log that states the priority decreased,
    #         # where it was never set before.
    #         #
    #         # TODO: might want to consider adding another type: "first_set"
    #         prev_priority = 0
    #       else
    #         # Values are saved strings
    #         prev_priority = parseInt(previous_change.new_value, 10)

    #       new_priority = parseInt(doc.new_value, 10)

    #       if prev_priority == new_priority
    #         # User changed the value back to where it originally was, remove
    #         # current change
    #         self.changelog_collection.remove doc._id, (err, id) ->
    #           if err?
    #             self.logger.error(err)

    #         return

    #       if prev_priority > new_priority
    #         change_type = 'priority_decreased'
    #       else
    #         change_type = 'priority_increased'

    #       self.changelog_collection.update doc._id, {change_type: change_type}, (err, id) ->
    #         if err?
    #           self.logger.error(err)

    #           return

    #       return

    #   return true
