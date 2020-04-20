## API
* Set tasks F2S dependencies

    ```
        addFinishToStartDependency(project_id, from_task_id, to_task_id) #client side
    ```
    Will perform some validation test and then will add a finish to start dependency.

* Remove tasks F2S dependencies

    ```
        removeFinishToStartDependency(project_id, from_task_id, to_task_id) #client side
    ```

  
* Check F2S dependeny:
    ```javascript
      tasksDependentF2S(project_id, from_task_id, to_task_id) #client side
    ```
    Returns true if to_task is F2S dependent on from_task
    
* Get the latest end_date off all dependent task of a certain task_obj. 
  Use to find the potential start date of a task. 

       heighestDependentsEndDate(task_obj) #client
       
  returns "YYYY-MM-DD"  the latest end date or null if there are no
  dependencies or no dependencies with end_date
  
* Get list of dependent tasks

       dependentTasksBySeqNumber(task_obj) #client & server

  returns a map of task_id to dependent type. In the future when seq id to task Id is cached
  we should replace it with an option to get the dependent task ids or docs.
         
  
 