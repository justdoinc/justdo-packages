minimum_pixels_per_day = 20
minimum_pixels_per_week = 20
minimum_pixels_per_month = 30
minimum_pixels_per_quarter = 30
minimum_pixels_per_year = 31

Template.justdo_grid_gantt_header.onCreated ->
  self = @
  
  @high_res_divs_rv = new ReactiveVar []
  @low_res_divs_rv = new ReactiveVar []
  
  @autorun =>
    grid_gantt = APP.justdo_grid_gantt
    width = grid_gantt.getColumnWidth()
    range = grid_gantt.getEpochRange()
    
    calculateDivs = (period, periods, format) ->
      # high res
      moment_from = moment.utc(range[0])
      moment_to = moment.utc(range[1])
      moment_from = moment_from.startOf period
      moment_to = moment_to.endOf period
      high_res_divs = []
      while moment_from <= moment_to
        from = moment_from.valueOf()
        div_data =
          from: from
          text: moment_from.format format
          left: grid_gantt.timeOffsetPixels range, from, width
          title: moment_from.format "ddd, MMM Do, YYYY"
        moment_from = moment_from.add 1, periods
        div_data.to = moment_from.valueOf()
        right = grid_gantt.timeOffsetPixels range, div_data.to, width
        div_data.width = right - div_data.left
        high_res_divs.push div_data
      return high_res_divs
      
    moment_from = moment.utc(range[0])
    moment_to = moment.utc(range[1])
  
    # days
    if (width / (moment_to.diff moment_from, "days") > minimum_pixels_per_day)
      self.high_res_divs_rv.set(calculateDivs("day", "days", "dd"))
      self.low_res_divs_rv.set(calculateDivs("week", "weeks", "MMM DD, [week] ww"))
      
    # weeks
    else if (width / (moment_to.diff moment_from, "weeks") > minimum_pixels_per_week)
      self.high_res_divs_rv.set(calculateDivs("week", "weeks", "DD"))
      self.low_res_divs_rv.set(calculateDivs("month", "months", "MMM"))
      
    # months
    else if (width / (moment_to.diff moment_from, "months") > minimum_pixels_per_month)
      self.high_res_divs_rv.set(calculateDivs("month", "months", "MMM"))
      self.low_res_divs_rv.set(calculateDivs("quarter", "quarters", "Qo [Q]"))
      
    # quarters
    else if (width / (moment_to.diff moment_from, "quarters") > minimum_pixels_per_quarter)
      self.high_res_divs_rv.set(calculateDivs("quarter", "quarters", "Qo [Q]"))
      self.low_res_divs_rv.set(calculateDivs("year", "years", "YYYY"))
      
    # years
    else if (width / (moment_to.diff moment_from, "years") > minimum_pixels_per_year)
      self.high_res_divs_rv.set(calculateDivs("year", "years", "YYYY"))
      self.low_res_divs_rv.set []
      
    # todo: limit the zoom out
    
  return
  
Template.justdo_grid_gantt_header.helpers
  highResDivs: ->
    return Template.instance().high_res_divs_rv.get()
    
  lowResDivs: ->
    return Template.instance().low_res_divs_rv.get()
  
Template.justdo_grid_gantt_header.events
  "click .grid-gantt-zoom-in": (e, tpl) ->
    APP.justdo_grid_gantt.zoomIn()
    return
  
  "click .grid-gantt-zoom-out": (e, tpl) ->
    APP.justdo_grid_gantt.zoomOut()
    return