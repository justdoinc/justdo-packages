# JustDo Projects Templates

You may use the JustDoProjectsTemplates package to create projects or subtrees in existing projects.

To create a project for use with a justdo onboarding tutorial, first create the project and ensure any test users exist and that the user and all test users are members of the project, then use the createSubtreeFromTemplateUnsafe method to populate the sandbox project using a template you've defined.

To populate a project or task with a user defined template, call createSubtreeFromTemplate with any options, the template, and the perform_as (the creating user).

## Package API

- createSubtreeFromTemplate(options, perform_as) - creates a subtree in the specified project using the template specified in the options, all actions are performed as the user passed in via the perform_as argument
- createSubtreeFromTemplateUnsafe(options) - creates a subtree in the specified project using the template specified in the options, all actions are performed as the user defined in the template, unless a perform_as option is passed as a key on the options.

Both api methods take the same options argument:

- options.project_id - (required) The project in which the subtree should be placed.
- options.root_task_id - (optional) The root task in which to place the subtree, if not specified tasks will be placed in the root of the project
- options.template (required) The subtree template
- options.users (required) A map of user aliases to user ids, keys should be the alias as defined in the template, values should be ids of actual (or fake) users which exist in the Meteor.users collection.
- options.perform_as (required, but may be inherited from the task) The user to who should perform all actions. If you call createSubtreeFromTemplate this option will be populated (overridden) from the perform_as argument.

## Template API

The subtree template is a json/javascript object describing the subtree to be created.

The following properties are allowed:

- users - (required) An array of all the users used by this template, by default these users will be the default users for each task in the subtree if no explicit set of users is defined. The values in this array are aliases and need to mapped to actual users in options.users (see Package API).
- tasks - (required) An array of tasks to be added to the project (or root node), see the Tasks API for more details

## Tasks API

Each task is an object with the following properties:

- key - An alias for this task so it can be referenced elsewhere in the subtree template.
- title - (not required, but recommended) The title of the task
- owner - (optional, defaults to perform_as, may be inherited) The owner of the task
- pending_owner - (optional, may be inherited) The pending owner of the task
- perform_as - (required, but may be inherited) The user who creates this task, and by default is the actor in any actions associated with this task, this value should be one of the aliases listed in the subtree template's users array, this property will be overridden by any value in the perform_as property of the subtree options.
- due_date - (optional) The due date of the task
- follow_up - (optional) The follow up date of the task
- users - (required, but may be inherited) An array of users to be added to the task, you should use values from the users array defined at the template level, these values will be mapped to real user ids at runtime.
- parents - (optional) Any additional parents to add to this task, values in this array should be keys of other tasks (see the key property)
- tasks - (or sub_tasks, optional) Any sub-tasks to be added as children of this task, each task has the same format as tasks at the root level.
- events - (optional) Any events which should be applied to this task after the creation of the subtree is complete, see the Events API for more details.

Note about inheritance:

Several fields are inherited by default, in particular the users, owner, pending_owner, and perform_as fields, these fields can be specified at the subtree template level, at the task level, or (in case of perform_as) at the event level.

## Events API

In addition to the built in properties of a task, you may define a set of events which will be performed against the task after the subtree has been created.

Each event is a json object with the following properties:

- action - (required) the event action e.g. update, setOwner, etc.
- perform_as - (optional, may be inherited) the user who performs the action
- args - (required) arguments for the action

The following event actions are available:

- update - Perform an update, args should be a mongo update argument and may include any changes which the performing user has permission to perform.
- setOwner - Set the owner_id of the task, args should be the new owner and should be one of the users specified on the subtree template. (also unsets the pending owner id)
- setPendingOwner - Set the pending_owner_id, args should be the new owner and should be one of the user aliases specified on the subtree template.
- setFollowUp - Set the follow_up, args should be the date in 'YYYY-MM-DD' format.
- setDueDate - Set the follow_up, args should be the date in 'YYYY-MM-DD' format.
- setStatus - Set the status, args should be a string.
- setState - Set the state, args should be a string, one of the possible states. (XXX -- Daniel can you paste the possible states here)
- addParents - Add parent tasks to the task, should be an array containing task aliases (see the key property in the Tasks API).
- removeParents - Remove parent tasks from a task, should be an array containing task aliases (see the key property in the Tasks API).
