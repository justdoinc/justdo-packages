### API CALLS

* String to epoch functions:

      dateStringToStartOfDayEpoch(date)
      dateStringToMidDayEpoch(date)
      dateStringToEndOfDayEpoch(date)      
    
  * date in YYYY-MM-DD 
  * Returns the epoch time of the beginning/mid-dat/end of that date
  
* Time offset calculation

      timeOffsetPixels([from_epoch, to_epoch], time, width_in_pixels)
      
  * [from_epoch, to_epoch] - represent the first and last time points on the x axis
  * time - represents the point of time to present
  * with_in_pixels - the length of the x axis
  
  Returns the x offset on the time axis in pixels if time is w/in the range, otherwise 
  returns undefined.
  
   
 