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