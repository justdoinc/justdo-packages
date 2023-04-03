Template.version_release_features.onCreated ->
  # Add date to each of the updates to faciliate the date display in updates_card
  @data.template?.template_data = _.map @data.template?.template_data, (data) =>
    data.date = @data.date
    return data
  return
