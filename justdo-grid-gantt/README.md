## Plugin Structure

### JustdoGridGantt

With a single instance (APP.justdo_grid_gantt) this object will manage the data needed for the 
graphical representation of the Gantt chart. 

Notes:
* All times in epoch

#### Data Structure
      task_id_to_info: # Map to relevant information including                    
        gantt_data:
            earliest_child_start_time: <>
            latest_chiled_end_time: <>
            alerts: [<structure TBD>,]
      
      task_id_to_dependies: {} # a map of task_id to a Set of dependy-tasks' ids. This is not part of the 
        task_id_to_info, since the order of tasks added by the ovserver is not gurenteed to have the 
        dependies before the dependants (which will make it more complicated)  
      
Column Related:

      gantt_column_from_epoch_time_rv
      gantt_colunm_to_epoch_time_rv
            
      
      
          
#### Process flow
* on JustDo change we loop through all tasks and process them one by one
* thereafter we listen to core_data.on "data-changes-queue-processed" events and process changes
* for every change/remove we call either processTaskChange or processTaskRemove
* the last two break down the changes to processStartTimeChange, processEndTimeChange etc
* for every change, the changed task is added into a Set of tasks that were changed (gantt_dirty_tasks)
* at the end of the init loop, or the queue processing, we process the gantt_dirty_tasks set
  to invalidate the appropriate cells
  


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
  
  Returns the x offset on the time axis in pixels. Note that if time below thew range or 
  above the range, it will return negative value, or value that is bigger than the 
  column width

* Pixels delta to epoch delta

      pixelsDeltaToEpochDelta(delta_pixels)
      
  Translate offset of pixels to offset in epoch times
  
* updating the task-bar end time:

      setPresentationEndTime(task_id, new_end_time)
      
  This moves the bar end to a new time. Information is not saved to the
  database and is not persistent
  
* set and get column width with setColumnWidth and getColumnWidth   
 
 
### gantt-grid-formatter

This object's functions will be used to render the information from the task_id_to_info. No computations
will take place here
 

#### Operations


# Notes
```
1. Getting an up-to-date grid data of the natural tree on plugin init, and consequence updates to it:

APP.modules.project_page.mainGridControl()._grid_data._grid_data_core.items_by_id
APP.modules.project_page.mainGridControl()._grid_data._grid_data_core.on("data-changes-queue-processed", (queue) => {console.log("XXX", queue)})

2. For the active tree, once you notice that an item state changed as a result of another item data changes:

APP.modules.project_page.gridControl()._grid_data._items_ids_map_to_grid_tree_indices

3. Updating a specific field_id of row r in the current grid control:

field_id_to_col_id = @getFieldIdToColumnIndexMap()
APP.modules.project_page.gridControl()._grid.updateCell(r, field_id_to_col_id[field_id])

General comment, same tick caching:

JustdoHelpers.sameTickCacheSet("x", {a: 13})
JustdoHelpers.sameTickCacheGet("x")
```

