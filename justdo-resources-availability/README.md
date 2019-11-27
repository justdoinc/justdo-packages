

###todo:
* replace the \<input type="time"> with a different option is this is not compatible 
with all browsers.

* prevent non-admin from editing other users availability

* in calculating bottom line - use the real working hours

  
### API:
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
 
 