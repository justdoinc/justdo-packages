APP.executeAfterAppLibCode ->
  JD?.registerPlaceholderItem "user-journey-ai-section",
    domain: "user-journey-dialog"
    listingCondition: -> APP.justdo_ai_kit?
    data:
      template: "ai_analytics_user_journey_dialog_section"

Template.ai_analytics_user_journey_dialog_section.onCreated ->
  if not (@user_id = @data.user_id)?
    return
  
  @ai_query_logs_rv = new ReactiveVar []

  @autorun =>
    if not _.isNumber(cur_journey_ts = @data.getCurrentJourneyTimestamp())
      return

    starting_ts = moment(cur_journey_ts).startOf("day").valueOf()
    ending_ts = moment(cur_journey_ts).endOf("day").valueOf()

    options = 
      starting_ts: starting_ts
      ending_ts: ending_ts
      user_id: @user_id
    APP.justdo_ai_kit.getAIRequestsLog options, (err, res) =>
      if err?
        JustdoSnackbar.show
          text: err.reason or err
        return

      @ai_query_logs_rv.set res
      return

    return

  return

Template.ai_analytics_user_journey_dialog_section.helpers
  log: -> Template.instance().ai_query_logs_rv.get()

  createdAtToHumanReadable: ->
    return moment(@createdAt).format("#{JustdoHelpers.getUserPreferredDateFormat()} h:mm:ss a")

  stringifiedReq: (max_length) -> 
    data = EJSON.stringify @req.data
    if max_length?
      data = JustdoHelpers.ellipsis data, max_length
    return data
  
  stringifiedRes: (max_length) ->
    if not @res?
      return

    data = EJSON.stringify @res.choices?[0]?.message?.content
    if max_length?
      data = JustdoHelpers.ellipsis data, max_length

    return data

  rowClassByUserChoice: ->
    if @choice is "a"
      return "success"
    
    if @choice is "p"
      return "warning"
    
    if @choice is "d"
      return "danger"
    
    return "default"

  userChoice: ->
    if @choice is "a"
      return "All"
    
    if @choice is "p"
      return "Partial"
    
    if @choice is "d"
      return "Declined"
    
    return ""

Template.ai_analytics_user_journey_dialog_section.events
  "click td[title]": (e, tpl) ->
    if $(e.currentTarget).hasClass("req-container")
      clipboard_data = @req
    
    if $(e.currentTarget).hasClass("res-container")
      clipboard_data = @res

    if not clipboard_data?
      return

    clipboard.copy
      "text/plain": EJSON.stringify clipboard_data
    JustdoSnackbar.show 
      text: "Data copied to clipboard"
    
    return
  
  "click .copy-to-clipboard": (e, tpl) ->
    clipboard.copy
      "text/plain": EJSON.stringify @
    JustdoSnackbar.show 
      text: "Data copied to clipboard"
      
    return