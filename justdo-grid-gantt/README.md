## Plugin Structure

### JustdoGridGantt

With a single instance (APP.justdo_grid_gantt) this object will manage the data needed for the 
graphical representation of the Gantt chart. 

Notes:
* All times in epoch

#### Data Structure
      task_id_to_info: # Map to relevant information including
        task_obj:
        grid_rows: [row #,..] # where on the grid                 
        gantt_data:
            earliest_child_start_time: <>
            latest_chiled_end_time: <>
            alerts: [<structure TBD>,]
         
      seq_id_to_task_id: # Map for quick access from the seq_id to the task_id (needed for dependencies)
      
      task_id_to_dependies: {} # a map of task_id to a Set of dependy-tasks' ids. This is not part of the 
        task_id_to_info, since the order of tasks added by the ovserver is not gurenteed to have the 
        dependies before the dependants (which will make it more complicated)  
        
      task_id_to_child_tasks: {} # a dictionary of task_id to Set of direct children ids
      
      
          
#### Operations
* An observer on tasks collection will trigger updates to the relevant data structure items


#### API CALLS

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
  
   
 
 
### gantt-grid-formatter

This object's functions will be used to render the information from the task_id_to_info. No computations
will take place here
 

#### Operations
* __Daniel__ - I need the events fired when a task is added to the grid and when it's removed from the grid.
  If you have also events for when the task is hidden or not (either because it is filtered or collapsed)
  it will be great. 

