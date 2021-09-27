_.extend JustdoUsageStatistics.prototype,
  _immediateInit: ->
    @usage_statistics_level = _.map @usage_statistics_level.split(","), (x) -> x.trim()

    return

  _deferredInit: ->
    if @destroyed
      return

    @setupUsageStatisticsKeys = _.once =>
      @_local_pass = JustdoAnalytics.prototype._generateLocalPass()
      @devops_password_encrypted = JustdoAnalytics.prototype._getEncryptedBase64LocalPass.call(@)

      return

    @setupUsageStatisticsMethod()

    return

  _encryptWithLocalPass: (string) ->
    return JustdoAnalytics.prototype._encryptWithLocalPass.call(_.extend(@, {requireDevopsPublicKey: -> true}), string)

  isCategoryEnabled: (category_id) ->
    return ("all" in @usage_statistics_level) or (category_id in @usage_statistics_level)

  setupUsageStatisticsMethod: ->
    self = @

    Meteor.methods
      getUsageStatistics: (task_id) ->
        if not self.devops_public_key? or _.isEmpty(self.devops_public_key.trim())
          return throw self._error "devops-public-key-is-not-set"

        self.setupUsageStatisticsKeys()

        usage_statistics = {
          days_back: 60
        }

        if self.isCategoryEnabled("basic")
          usage_statistics.changelog_entries_grouped_by_project_user_date = []
          await APP.collections.TasksChangelog.rawCollection().aggregate([
            {
              $match:
                when:
                  $gt: new Date(new Date().setDate(new Date().getDate() - usage_statistics.days_back))
            }
            {
              $project:
                by: "$by",
                project_id:"$project_id",
                date:
                  $substr: ["$when", 0, 10]
            }
            {
              $sort:
                project_id: -1
                by: 1
                date: 1
            }
            {
              $group: {
                _id:
                  project_id: "$project_id",
                  user_id: "$by",
                  date: "$date"
                changes:
                  $sum: 1
              }
            }
          ], {allowDiskUse:true})
          .forEach (doc) ->
            usage_statistics.changelog_entries_grouped_by_project_user_date.push doc

            return

        if self.isCategoryEnabled("basic")
          usage_statistics.chat_messages_by_project_user_date = []
          await APP.collections.JDChatMessages.rawCollection().aggregate([
              {
                $match:
                  createdAt:
                    $gt: new Date(new Date().setDate(new Date().getDate() - usage_statistics.days_back))
              }
              {
                $lookup:
                  from: "jd_chat_channels"
                  localField: "channel_id"
                  foreignField: "_id"
                  as: "channel"
              }
              {
                $project:
                  by: "$author"
                  project_id: "$channel.project_id"
                  date:
                    $substr: ["$createdAt", 0, 10]
              }
              {
                $sort:
                  project_id: -1
                  by: 1
                  date: 1
              }
              {
                $group:
                  _id:
                    project_id: "$project_id"
                    user_id: "$by"
                    date: "$date"
                  changes:
                    $sum: 1
              }
             
          ], {allowDiskUse:true})
          .forEach (doc) ->
            usage_statistics.chat_messages_by_project_user_date.push doc

            return

        if self.isCategoryEnabled("basic")
          usage_statistics.all_time_tasks_by_project_state = []
          await APP.collections.Tasks.rawCollection().aggregate([
            {
              $match:
                _raw_removed_date: null
                state:
                  $ne: null
                project_id:
                  $ne: null
            }
            {
              $project:
                project_id: "$project_id"
                state: "$state"
            }
            {
              $sort:
                project_id: 1
                state:1
            }
            {
              $group:
                _id:
                  project_id: "$project_id"
                  state: "$state"
                count:
                  $sum: 1
            }
          ], {allowDiskUse:true})
          .forEach (doc) ->
            usage_statistics.all_time_tasks_by_project_state.push doc

            return

        if self.isCategoryEnabled("users")
          usage_statistics.users =
            Meteor.users.find {},
              fields:
                "profile.first_name": 1
                "profile.last_name": 1
                emails: 1
                invited_by: 1
                createdAt: 1
            .fetch()

        if self.isCategoryEnabled("justdos")
          usage_statistics.justdos =
            APP.collections.Projects.find {},
              fields:
                title: 1
                members: 1
                access_restriction_type: 1
                lastTaskSeqId: 1
                createdAt: 1
                updatedAt: 1
                conf: 1
                custom_fields: 1
                removed_custom_fields: 1
            .fetch()


        usage_statistics.active_positions_ledger =
          APP.collections.UsersActivePositionsLedger.find
            time:
              $gt: new Date(new Date().setDate(new Date().getDate() - usage_statistics.days_back))
          .fetch()

        returned_val =
          key: self.devops_password_encrypted
          stats: self._encryptWithLocalPass(EJSON.stringify(usage_statistics))

        return returned_val


    return
