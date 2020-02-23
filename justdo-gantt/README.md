### Todo:
* requires dependencies 
* there is an issue when a task has a start, end and a due date.
  Need to add two objects to the gantt (at the moment I just add
  the due-date as a milestone )
* set a different color scale for things that are 'done'
* present % completed based on resources manager if available 


### Known bugs:
* if by drag and drop you move the end-date to be on the 
  start date the chart will display and empty point and
  then removes it, the data is okay.  Need
  to refresh the chart to show the point again
  