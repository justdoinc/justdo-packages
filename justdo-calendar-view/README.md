Added a end_date field to the grid with this plugin. Intentionally didn't 
make it plugin specific as I believe that this field is needed anyway, and will be 
reused in other places. -AL

workdays and holidays are based on  the justdo_delivery_planner.justdo_level_workdays,
with internal default if that module is not set.

note that working hours are based on planned (on display and when moving from 
one user to another). This means that if a user logged some work on a task and
then we move the task to a different user, we will add the original planned
hours (vs left hours) to the new owner. 

This can be changed in the future by configuration

### technical debt
* If two users are moving a task with resources concurrently and there is a 
race condition to the server, hours will be double-booked.
  