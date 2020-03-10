### Logic
* If there is no end-date, and no implied end-date but we do have due-date, we will use the 
  due date as if it is also the end-date
  

### Todo:
+ present due-date on the same line if exists, allow moving around
+ when there is a dependency on something with due-date but no end-date, use the due date instead
+ click on milestone to select the task on the grid
+ what happens on a double click on a milestone?
+ remove the 'top-series' from the title of the on-hover on point
+ alert when a due-date is before the implied start/end date
* as in 'ganttpro' 
  * colors for baskets, same for tasks
  * name of task on the bar
  * when moving a basket - all tasks underneath it are moving in the same way
  * the basket derives it's start-end from its children

* fix "if parent.milestone and data_obj.end > parent.start"
* deal with colors and colors of baskets
* add a note if there are unassigned hours
* check if milestone violates anything
* add alert on the due-date before start/end date on the alerts list.    
* on the title - if we zoom into a project and it has a due date which is crossed, color it red
* there is an issue with the second level title that is not displaying well
* if moving a basket (i.e. a task that it's start and end is based on children, add some warning)
* requires dependencies 
* requires is_milestone
* there is an issue when a task has a start, end and a due date.
  Need to add two objects to the gantt (at the moment I just add
  the due-date as a milestone )
* set a different color scale for things that are 'done'
* present % completed based on resources manager if available 
* unless specified, hicharts calculate parent's tasks start and end date internally, and then
  such tasks can't be used for calculating start date based on F2S.. so in order to fix it, 
  the start/end times should be calculated by us. Should be easy now that we have the parents 
  for all tasks during the iteration 


### QA
* Drag and drop
  * check situation where we have only start_date
  * check when we have start and stop
  * when we have start and due-date only
  

### Known bugs:
* if by drag and drop you move the end-date to be on the 
  start date the chart will display and empty point and
  then removes it, the data is okay.  Need
  to refresh the chart to show the point again
* a task with start time and no end time should be marked with a right arrow on the chart. for
  some reason the arrow is displayed only when the chart is 'zoomed-in'
  
## Notes about highchart's gantt
* multiple series is not supported well (there is a bug if multiple series are used and 
  yAxis.uniqueNames is true, the height of the rows is messed up. Need to use a single series 

* the following is not working due to bug on highcharts side. waiting for their reply
          https://github.com/highcharts/highcharts/issues/12012
  ```
        # adding a a callback at the end of the call
        chart:
          height: 1 #Without first/default value height function doesn't work
      ,
        (chart) ->          
          chart.update({
            chart: {
              height:  40 * object_count;
            }
          })
   ```