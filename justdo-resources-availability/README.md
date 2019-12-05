

###todo:
* replace the \<input type="time"> with a different option is this is not compatible 
with all browsers.

* prevent non-admin from editing other users availability

* in calculating bottom line - use the real working hours

  
### API:
* _enableResourceAvailability(requesting_plugin_id)_ (client) <br>
    Enables the functionality of the plugin (if called by different plugins 
    still have a single copy)
    
* _disbleResourceAvailability(requesting_plugin_id)_ (client) <br>
    Disable the plugin

* _displayConfigDialog: (user_id, task_id)_ (client ) <br>
    user_id: optional <br>
    task_id: optional <br>
    
    if user and task are given, it will display the info for the justdo-project
    else if user is given, it will display the info for the justdo user
    else it will display the info for the justdo
    
* _workdaysAndHolidaysFor(project_id, dates_list, user_id)_ (both) <br>
*       ret=
            workdays: new Set() 
            holidays: new Set() 
            working_hours: {} # in the structure of [[from, to],[from,to],...] where the main index is the day of week
            
     "from" and "to" are in "HH:MM" format
     
* _userAvailabilityBetweenDates: (from_date, to_date, project_id, user_id, task_id)_ <br>
    returns the number of available days and the available hours for the users between 
    the two dates (inclusive)
*       ret =
              working_days: 
              available_hours:     
* _startToFinishForUser: (project_id, user_id, start_date, amount, type)_
    Given project, user, and start date, the amount of days/hours required,
    the function will return the date of the end of the period (start to end) 
    taking into account holidays or working hours.<br><br>
    Type is either 'days' or 'hours'. <br>
    
      
 
 