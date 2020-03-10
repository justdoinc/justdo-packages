

###todo:
* replace the \<input type="time"> with a different option is this is not compatible 
with all browsers.

* prevent non-admin from editing other users availability

* in calculating bottom line - use the real working hours

  
### API:
       
* Enable Library

      enableResourceAvailability(requesting_plugin_id) #(client) 
    
    Enables the functionality of the plugin (if called by different plugins 
    still have a single copy)
    
* Disable library

      disbleResourceAvailability(requesting_plugin_id) #(client) 
    

* Display configuration dialog   
     
      displayConfigDialog: (user_id, task_id) #(client )
      
      user_id: optional 
      ask_id: optional 
    
    if user and task are given, it will display the info for the justdo-project
    else if user is given, it will display the info for the justdo user
    else it will display the info for the justdo
   
* Get workdays and holidays for user

      workdaysAndHolidaysFor(project_id, dates_list, user_id) #(both)  
  
      ret=
        workdays: new Set() 
        holidays: new Set() 
        working_hours: {} # in the structure of [[from, to],[from,to],...] where the main index is the day of week
              
  "from" and "to" are in "HH:MM" format
     
* Find user availability

      userAvailabilityBetweenDates: (from_date, to_date, project_id, user_id) 
  
      ret =
        working_days: 
        available_hours:     
    
  returns the number of available days and the available hours for the user between 
  the two dates (inclusive)

* Calculate end date given start date and work required   

      startToFinishForUser: (project_id, user_id, start_date, amount, type)
    
  Given project, user, and start date, the amount of days/hours required,
  the function will return the date of the end of the period (start to end) 
  taking into account holidays or working hours.
  
  Type is either 'days' or 'hours'.
  
    
      
 
 