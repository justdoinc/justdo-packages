_.extend JustDoProjectsTemplates.prototype,
  _immediateInit: ->
    return

  _deferredInit: ->
    if @destroyed
      return

    # Defined in methods.coffee
    @_setupMethods()

    # Defined in publications.coffee
    @_setupPublications()

    # Defined in collections-hooks.coffee
    @_setupCollectionsHooks()

    # Defined in collections-indexes.coffee
    @_ensureIndexesExists()

    return

  createSubtreeFromTemplateUnsafe: (options) ->
    for role, user_id of options.users
      if not APP.accounts.getUserById(user_id)?
        throw @_error "unknown-user", "User #{role} does not exist"

    parser = new TemplateParser(options.template, options, null)
    parser.logger = @logger

    parser.createTasks(options.template.tasks)
    parser.runEvents()

    @emit "post-create-subtree-from-template", options

    return {paths_to_expand: parser.paths_to_expand, first_root_task_id: parser.tasks?.first_root_task}

  destroy: ->
    if @destroyed
      @logger.debug "Destroyed already"

      return

    @destroyed = true

    @logger.debug "Destroyed"

    return

  _generateStreamTemplateReq: (msg) ->
    req = 
      "model": JustDoProjectsTemplates.openai_template_generation_model,
      "messages": [
        {
          "role": "system",
          "content": """
            Based on user input, generate an array of tasks. 
            They must be relevant to the user input, and must be in the same language as the user input.

            Below is the JSON schema of a task object:
            ### JSON schema begin ###
            {
              "type": "object",
              "properties": {
                "title": {
                  "type": "string",
                  "description": "Title of the task describing the task, or describing what the child tasks does if it has child tasks."
                },
                "start_date_offset": {
                  "type": "number",
                  "description": "Start date of the task represented by the offset in days relative to today's date"
                },
                "end_date_offset": {
                  "type": "number",
                  "description": "End date of the task represented by the offset in days relative to today's date"
                },
                "due_date_offset": {
                  "type": "number",
                  "description": "Due date of the task represented by the offset in days relative to today's date"
                },
                "state_idx": {
                  "type": "number",
                  "description": "Index of the task's state from this list: ['pending', 'in-progress', 'done', 'will-not-do', 'on-hold', 'duplicate', 'nil']"
                },
                "key": {
                  "type": "number",
                  "description": "0-based sequence ID of the task."
                },
                "parent_task_key": {
                  "type": "number",
                  "description": "Parent task's key. The parent task must exist before referencing. If the task is a top-level task, use -1."
                }
              }
            }
            ### JSON schema ends ###

            The tasks hierachy are as follows:
            ### Tasks hierarchy begin ###
            Top level tasks must have 3 to 6 child tasks, and it's depth must be 3 to 5 levels.

            Depth means the number of levels of the task tree. E.g. a top-level task with no child tasks has a depth of 1, a top-level task with 1 child task has a depth of 2, and so on.

            The title of top level tasks must be a category or a department.

            Immediate child tasks of top level tasks must be projects under the category or the department.

            Other child tasks must be action items that can be assigned to team members under the parent project or category.

            All child tasks must be grouped under a relevant parent task.
            ### Tasks hierarchy ends ###

            Only set dates for child tasks. For parent tasks, set the date to an empty string.

            For state_idx field:
            "nil" is the default state for a task that means there is no state.
            "will-not-do"  means the task is cancelled.
            Apply as many states to the tasks generated as you can, but ensure they make sense (e.g. if a child task is pending/in-progress, the parent task should never be set to done.)
            When generating tasks, use the index of possible_states to reference a state.

            To reduce the size of task definition, use an array to represent a task. The array must contain only the value of the task object, in the order of the schema.
            Generate 45 to 60 tasks in total. Return only the array without any formatting like whitespaces and line breakes.
          """.trim()
        },
        {
          "role": "user",
          "content": "Manage a tech startup"
        },
        {
          "role": "assistant",
          "content": """[["Product Development", "", "", "", 6, 0, -1], ["Website Launch", "", "", "", 6, 1, 0], ["Design Homepage", 1, 7, 7, 2, 2, 1], ["Setup Hosting", 0, 1, 1, 1, 3, 1], ["Implement SEO Best Practices", 3, 10, 10, 0, 4, 1], ["Launch Marketing Campaign", 8, 14, 14, 2, 5, 1], ["App Development", "", "", "", 6, 6, 0], ["Design UI/UX", 1, 14, 14, 1, 7, 6], ["Develop Backend", 3, 30, 40, 1, 8, 6], ["Quality Assurance", 15, 50, 50, 1, 9, 6], ["Publish to App Store", 51, 60, 60, 0, 10, 6], ["Market Research", "", "", "", 6, 11, 0], ["Identify Target Market", 0, 5, 5, 1, 12, 11], ["Competitor Analysis", 1, 10, 10, 1, 13, 11], ["Product Feedback Loop", 11, 60, 60, 1, 14, 11], ["Sales Strategy", "", "", "", 6, 15, 0], ["Define Pricing Model", 3, 7, 7, 1, 16, 15], ["Identify Sales Channels", 4, 8, 8, 1, 17, 15], ["Train Sales Team", 5, 9, 9, 1, 18, 15], ["Operate Sales Campaigns", 10, 60, 60, 0, 19, 15], ["Customer Support Setup", "", "", "", 6, 20, 0], ["Implement Support Software", 2, 9, 9, 1, 21, 20], ["Hire Support Team", 3, 12, 12, 1, 22, 20], ["Train Support Team", 13, 20, 20, 1, 23, 20], ["Publish FAQ and Documentation", 10, 15, 15, 1, 24, 20], ["Investor Relations", "", "", "", 6, 25, 0], ["Prepare Investment Deck", 5, 12, 12, 1, 26, 25], ["Identify Potential Investors", 1, 5, 5, 1, 27, 25], ["Schedule Meetings", 6, 18, 18, 1, 28, 25], ["Follow-up Communications", 19, 22, 22, 1, 29, 25], ["Legal & Compliance", "", "", "", 6, 30, 0], ["Register Business", 0, 1, 1, 1, 31, 30], ["Trademark Product Names", 2, 8, 8, 1, 32, 30], ["Legal Review of Contracts", 3, 9, 9, 1, 33, 30], ["Ensure Data Protection Compliance", 4, 10, 10, 1, 34, 30], ["Financial Planning", "", "", "", 6, 35, 0], ["Budget Allocation", 1, 3, 3, 1, 36, 35], ["Cash Flow Management", 2, 6, 6, 1, 37, 35], ["Financial Reporting", 4, 8, 8, 1, 38, 35], ["Resource Planning", "", "", "", 6, 39, 0], ["Hire Key Roles", 1, 7, 7, 1, 40, 39], ["Allocate Office Space", 2, 8, 8, 1, 41, 39], ["Setup Workstations", 3, 9, 9, 1, 42, 39], ["Technology Procurement", 4, 10, 10, 1, 43, 39], ["Team Development", "", "", "", 6, 44, 0], ["Regular Team Meetings", 1, 30, 30, 1, 45, 44], ["Team Building Activities", 10, 40, 40, 0, 46, 44], ["Professional Development Programs", 15, 45, 45, 1, 47, 44], ["Performance Review Process", 20, 50, 50, 1, 48, 44]]"""
        },
        {
          "role": "user",
          "content": "管理醫院人事部門"
        },
        {
          "role": "assistant",
          "content": """[["人事部門","","","",6,0,-1],["招聘流程","","","",6,1,0],["確定員工需求",1,5,5,1,2,1],["制定職位描述",2,7,7,1,3,1],["發布職位空缺",3,8,8,1,4,1],["篩選簡歷",4,10,10,1,5,1],["面試候選人",6,12,12,1,6,1],["招聘決策",8,14,14,1,7,1],["員工入職",10,17,17,1,8,1],["培訓與發展",15,20,20,1,9,1],["績效評估",20,25,25,1,10,1],["員工關係","","","",6,11,-1],["解決員工關切",1,5,5,1,12,11],["解決工作場所衝突",2,6,6,1,13,11],["員工表揚計劃",7,15,15,1,14,11],["組織文化發展",10,20,20,1,15,11],["人力資源政策與合規","","","",6,16,-1],["更新員工手冊",1,7,7,1,17,16],["確保勞工法合規",2,8,8,1,18,16],["實施多元和包容性倡議",5,12,12,1,19,16],["衝突解決程序",10,15,15,1,20,16],["培訓與發展","","","",6,21,-1],["確定培訓需求",1,5,5,1,22,21],["制定培訓計劃",2,8,8,1,23,21],["培訓交付",5,12,12,1,24,21],["培訓評估",10,15,15,1,25,21],["健康與安全計畫","","","",6,26,-1],["實施 OSHA 指南",1,7,7,1,27,26],["緊急應變培訓",2,8,8,1,28,26],["工作場所安全檢查",5,12,12,1,29,26],["健康和健康計劃",10,15,15,1,30,26],["福利管理","","","",6,31,-1],["設計員工福利計劃",3,10,10,1,32,31],["參加福利計劃",5,12,12,1,33,31],["福利溝通",8,15,15,1,34,31],["福利評估和調整",12,20,20,1,35,31],["勞動力規劃","","","",6,36,-1],["預測員工需求",2,5,5,1,37,36],["承傳計劃",3,7,7,1,38,36],["管理組織變革",8,12,12,1,39,36],["人才管理",13,17,17,1,40,36],["員工發展","","","",6,41,-1],["職業規劃",2,5,5,1,42,41],["導師計劃",5,8,8,1,43,41],["專業發展機會",8,12,12,1,44,41],["領導培訓",13,15,15,1,45,41],["員工參與","","","",6,46,-1],["員工反饋調查",2,5,5,1,47,46],["員工表揚計劃",6,10,10,1,48,46]]"""
        },
        {
          "role": "user",
          "content": msg.trim()
        }
      ],
      "temperature": 1,
      "top_p": 1,
      "n": 1,
      "stream": true,
      "max_tokens": 4096,
      "presence_penalty": 0,
      "frequency_penalty": 0,
    return req

  createStreamRequestWithOpenAi: (req, user_id) ->
    request_id = APP.justdo_ai_kit.openai.createChatCompletion req, user_id
    stream = await APP.justdo_ai_kit.openai.getRequest request_id

    await return stream
  
  streamTemplateFromOpenAiMethodHandler: (msg, user_id) ->
    check msg, String
    check user_id, String

    self = @

    pub_id = Random.id()
    Meteor.publish pub_id, ->
      publish_this = @

      # This block is to specifically handle requests that requires pre-defined project templates.
      if (template_obj = self.getTemplateById msg)?
        key = 0
        _recursiveParseAndPublishTemplateTask = (template_task, parent) ->
          fields = 
            _id: "#{key}_#{pub_id}"
            key: key
            pub_id: pub_id
            parent: parent
            state: template_task.state
            start_date: template_task.start_date
            end_date: template_task.end_date
            due_date: template_task.due_date

          if _.isFunction(i18n_title = template_task.title_i18n)
            fields.title = i18n_title user_id
          else if _.isObject i18n_title
            fields.title = APP.justdo_i18n.tr i18n_title.key, i18n_title.options, user_id
          else if _.isString i18n_title
            fields.title = APP.justdo_i18n.tr i18n_title, {}, user_id

          if _.isObject(status_i18n = template_task.status_i18n)
            fields.status = APP.justdo_i18n.tr status_i18n.key, status_i18n.options, user_id
          else if _.isString status_i18n
            fields.status = APP.justdo_i18n.tr status_i18n, {}, user_id

          if template_task.archived
            fields.archived = new Date()
          
          publish_this.added "ai_response", fields._id, fields
          key += 1

          if (subtasks = template_task.tasks)?
            for subtask in subtasks
              _recursiveParseAndPublishTemplateTask subtask, fields.key

          return
        
        template_tasks = template_obj.template.tasks
        for template_task in template_tasks
          _recursiveParseAndPublishTemplateTask template_task, -1
        
        publish_this.stop()
        return

      req = self._generateStreamTemplateReq msg
      stream = await self.createStreamRequestWithOpenAi req, user_id
      
      self.once "stop_stream_#{pub_id}_#{user_id}", ->
        stream.abort()
        publish_this.stop()
        return

      tasks = []
      task_string = ""
      _parseStreamedTasks = (task_arr) ->
        states = ["pending", "in-progress", "done", "will-not-do", "on-hold", "duplicate", "nil"]
        grid_data = APP.projects._grid_data_com
        
        [
          title
          start_date_offset
          end_date_offset
          due_date_offset
          state_idx
          key
          parent_task_key
        ] = task_arr

        fields = 
          _id: "#{key}_#{pub_id}"
          key: key
          pub_id: pub_id
          parent: parent_task_key
          title: title
          start_date: if _.isNumber(start_date_offset) then moment().add(start_date_offset, 'days').format("YYYY-MM-DD") else null
          end_date: if _.isNumber(end_date_offset) then moment().add(end_date_offset, 'days').format("YYYY-MM-DD") else null
          due_date: if _.isNumber(due_date_offset) then moment().add(due_date_offset, 'days').format("YYYY-MM-DD") else null
          # state: if (state_idx >= 0) then states[state_idx] else "nil"
          # Uncomment the line above and remove the line below once the AI model is updated to return more variety of states,
          # instead just in-progress.
          state: "pending"

        return fields

      for await part from stream
        res += part.choices[0].delta.content
        task_string += part.choices[0].delta.content

        if task_string.includes "]"
          # Replace double brackets with single brackets
          task_string = task_string.replace /\[\s*\[/g, "["
          task_string = task_string.replace /\]\s*\]/g, "]"

          # When the task_string contains a complete task, parse it and add it to the tasks array
          [finished_task_string, incomplete_task_string] = task_string.split(/],?/)

          # Add back the missing bracket from .split()
          finished_task_string += "]"

          task_arr = JSON.parse finished_task_string
          task = _parseStreamedTasks task_arr
          @added "ai_response", task._id, task
          task_string = incomplete_task_string
      
      stream.done().then ->
        publish_this.stop()
        self.off "stop_stream_#{pub_id}_#{user_id}"
        return

      return
    
    return pub_id
    
  _generateProjectTitleReq: (msg) ->
    req = 
      "model": JustDoProjectsTemplates.openai_template_generation_model,
      "messages": [
        {
          "role": "system",
          "content": "Summerize user input to a few words that will be used in a project's title. Your response must be in the same language as the user input."
        },
        {
          "role" : "user",
          "content" : "I'd like to manage a corner store"
        },
        {
          "role" : "assistant",
          "content" : "Corner store management"
        },
        {
          "role" : "user",
          "content" : "I'd like to manage a tech company that has about 10 employees"
        },
        {
          "role" : "assistant",
          "content" : "Tech startup management"
        },
        {
          "role" : "user",
          "content" : "管理醫院"
        },
        {
          "role" : "assistant",
          "content" : "醫院管理"
        },
        {
          "role": "user",
          "content": msg.trim()
        }
      ],
      "temperature": 1,
      "top_p": 1,
      "n": 1,
      "max_tokens": 128,
      "presence_penalty": 0,
      "frequency_penalty": 0,
    return req
  
  generateProjectTitleFromOpenAiMethodHandler: (msg, user_id) ->
    check msg, String
    check user_id, String

    req = @_generateProjectTitleReq msg
    request_id = APP.justdo_ai_kit.openai.createChatCompletion req, user_id
    res = await APP.justdo_ai_kit.openai.getRequest(request_id)

    await return res?.choices?[0]?.message?.content

  _generateStreamChildTasksReq: (msg) ->
    req = 
      "model": JustDoProjectsTemplates.openai_template_generation_model,
      "messages": [
        {
          "role": "system",
          "content": """
            User input will be a JSON object containing the project context. Based on the project context, expand the idea of the target task and generate child tasks under it.
            "project context" contains the project title, and the surrounding tasks of the target task, including "parents", "siblings", and "children".
            "target task" is always the last element in the "parents" array.

            User input will be the project context in JSON format. The schema is provided below. The "description" of each schema field contains instruction on how the data should be handled.
            ### User input JSON schema begin ###
            {
              "title": {
                "type": "string",
                "description": "Title of the project.",
                "optional": true
              },
              "parents": {
                "type": "array",
                "description": "Array of parent task titles. The first element is the top level parent (least relevant), and the last element is the target task (most relevant). The tasks you will be genereating are only children tasks of the target task. ",
                "optional": true
              },
              "siblings": {
                "type": "array",
                "description": "Array of same-level task titles provided to you to understand what the project is about.",
                "optional": true
              },
              "children": {
                "type": "array",
                "description": "Array of existing children task titles under the target task. The tasks you generate will be siblings of children. If provided, the tasks you generate must be different from the existing children tasks.",
                "optional": true
              }
            }
            ### User input JSON schema ends ###

            Below is the JSON schema of a task object that you will be generating:
            ### JSON schema begin ###
            {
              "type": "object",
              "properties": {
                "title": {
                  "type": "string",
                  "description": "Title of the task describing the task, or describing what the child tasks does if it has child tasks."
                },
                "key": {
                  "type": "number",
                  "description": "0-based sequence ID of the task."
                },
                "parent_task_key": {
                  "type": "number",
                  "description": "Parent task's key. The parent task must exist before referencing. If the task parent is the target task, use -1."
                }
              }
            }
            ### JSON schema ends ###

            Ensure the generated task title is the same as the target task.

            To reduce the size of task definition, use an array to represent a task. The array must contain only the value of the task object, in the order of the schema.
            Generate 5 to 20 tasks in total. Return only the array without any formatting like whitespaces and line breakes.
          """.trim()
        },
        {
          "role": "user",
          "content": """{"project": "Untitled JustDo", "parents": ["Travel Planning", "Trip to Hong Kong"]}"""
        },
        {
          "role" : "assistant",
          "content" : """[["Transportation",0,-1],["Book Flight Tickets",1,0],["Arrange Airport Transfer",2,0],["Accommodation",3,-1],["Hotel Reservation",4,3],["Check-in Online",5,3],["Activities",6,-1],["Sightseeing Tours Booking",7,6],["Dining Reservations",8,6],["Shopping Plans",9,6],["Emergency Contact List",10,6]]"""
        },
        {
          "role" : "user",
          "content" : """{"project":"Travel ideas","parents":["Locations","Israel"],"siblings":["Hong Kong","Vietnam","Korea","Russia"],"children":["Transportation"]}"""
        },
        {
          "role" : "assistant",
          "content" : """[["Accommodation",0,-1],["Hotel Reservation",1,0],["Check-in Procedures",2,0],["Explore Attractions",3,-1],["Historical Sites Visits",4,3],["Cultural Landmarks Tour",5,3],["Food and Drinks",6,3],["Local Cuisine Tasting",7,6],["Street Food Exploration",8,6],["Modern Bistros Visit",9,6],["Shopping",10,-1],["Souvenir Hunting",11,10],["Local Markets Exploration",12,10],["Specialty Stores Visit",13,16]]"""
        },
        {
          "role" : "user",
          "content" : """{"project":"1","parents":["Product Development","Prototype Development"],"siblings":["Market Research","Product Launch"],"children":["Design Sketching","3D Modeling","Prototype Testing","Feedback Collection"]}"""
        },
        {
          "role" : "assistant",
          "content" : """[["Material Selection",0,-1],["Cost Analysis",1,-1],["User Testing",2,-1],["Quality Assurance",3,-1],["Documentation",4,-1],["Demo Setup",5,-1],["Prepare for Production",6,-1]]"""
        },
        # {
        #   "role" : "user",
        #   "content" : """{"project":"Untitled JustDo","parents":["R&D","Mobile App Development","Sprints","v1.0.0","Implement new feature 1","Design & UX/UI","User Interface Design"]}"""
        # },
        # {
        #   "role" : "assistant",
        #   "content" : """[["Interaction Design",0,-1],["Wireframes Creation",1,0],["Prototyping",2,0],["Visual Design",3,-1],["Create Style Guide",4,3],["Design Mockups",5,3],["Iconography",6,3],["User Testing",7,-1],["Prepare Test Scenarios",8,7],["Conduct User Interviews",9,7],["Collect Feedback",10,7],["Iterate Design",11,7]]"""
        # },
        # {
        #     "role" : "user",
        #     "content" : """{"project":"Hospital Management","parents":["Clinical Services","Surgical Services","Post-Op Care Plans"],"siblings":["Surgical Team Coordination","Pre-Op Procedures","Equipment Sterilization"]}"""
        # },
        # {
        #     "role" : "assistant",
        #     "content" : """[["Patient Monitoring",0,-1],["Vital Signs Tracking",1,0],["Symptom Assessment",2,0],["Medication Administration",3,0],["Progress Notes Documentation",4,0],["Recovery Plan Implementation",5,-1],["Activity Monitoring",6,5],["Diet Supervision",7,5],["Pain Management",8,5],["Follow-up Appointments Scheduling",9,5],["Post-Discharge Care",10,-1],["Home Care Instructions",11,10],["Medication Regimen Explanation",12,10],["Rehabilitation Referrals",13,10],["Symptom Monitoring Plan",14,10]]"""
        # },
        # {
        #     "role" : "user",
        #     "content" : """{"project":"咖啡店管理","parents":["營銷推廣","社交媒體宣傳"]},"siblings": ["舉辦試喝活動", "優惠促銷策略"]"""
        # },
        # {
        #     "role" : "assistant",
        #     "content" : """[["線上活動",0,-1],["推文創作",1,0],["社群互動",2,0],["市場分析",3,0],["品牌形象",4,-1],["設計視覺元素",5,4],["制定廣告策略",6,4],["品牌定位優化",7,4],["優惠促銷",8,-1],["設計促銷活動",9,8],["製作宣傳物料",10,8],["執行促銷計劃",11,8]]"""
        # },
        {
          "role": "user",
          "content": JSON.stringify msg
        }
      ],
      "temperature": 1,
      "top_p": 1,
      "n": 1,
      "stream": true,
      "max_tokens": 4096,
      "presence_penalty": 0,
      "frequency_penalty": 0,
    return req

  _streamChildTasksFromOpenAiMethodHandlerContextSchema: new SimpleSchema
    project: 
      type: String
      optional: true
    parents:
      type: [String]
      optional: true
    "parents.$":
      type: String
      optional: true
    siblings:
      type: [String]
      optional: true
    "siblings.$":
      type: String
      optional: true
    children: 
      type: [String]
      optional: true
    "children.$":
      type: String
      optional: true
  streamChildTasksFromOpenAiMethodHandler: (context, user_id) ->
    check user_id, String

    {cleaned_val} =
      JustdoHelpers.simpleSchemaCleanAndValidate(
        @_streamChildTasksFromOpenAiMethodHandlerContextSchema,
        context,
        {self: @, throw_on_error: true}
      )
    context = cleaned_val

    self = @

    pub_id = Random.id()
    Meteor.publish pub_id, ->
      publish_this = @

      req = self._generateStreamChildTasksReq context
      stream = await self.createStreamRequestWithOpenAi req, user_id

      self.once "stop_stream_#{pub_id}_#{user_id}", ->
        stream.abort()
        publish_this.stop()
        return

      tasks = []
      task_string = ""
      _parseStreamedTasks = (task_arr) ->
        grid_data = APP.projects._grid_data_com

        [title, key, parent_task_key] = task_arr

        fields = 
          _id: "#{key}_#{pub_id}"
          key: key
          pub_id: pub_id
          parent: parent_task_key
          title: title
          state: "pending"

        return fields

      for await part from stream
        res += part.choices[0].delta.content
        task_string += part.choices[0].delta.content

        if task_string.includes "]"
          # Replace double brackets with single brackets
          task_string = task_string.replace /\[\s*\[/g, "["
          task_string = task_string.replace /\]\s*\]/g, "]"

          # When the task_string contains a complete task, parse it and add it to the tasks array
          [finished_task_string, incomplete_task_string] = task_string.split(/],?/)

          # Add back the missing bracket from .split()
          finished_task_string += "]"

          task_arr = JSON.parse finished_task_string
          task = _parseStreamedTasks task_arr
          @added "ai_response", task._id, task
          task_string = incomplete_task_string

      stream.done().then ->
        publish_this.stop()
        self.off "stop_stream_#{pub_id}_#{user_id}"
        return

      return

    return pub_id

getFromTemplateOnly = (key) ->
  return @template[key]

getFromTemplateOrParents = (key) ->
  return @template[key] ? @parent?.lookup(key)

getFromOptionsOrParents = (key) ->
  return @options[key] ? @parent?.lookup(key)

TemplateParser = (template, options, parent) ->
  @logger = parent?.logger ? console
  @users = parent?.users ? options.users ? {}
  @tasks = parent?.tasks ? {}
  @postponed_internal_actions = parent?.postponed_internal_actions ? []
  @events = parent?.events ? []
  @options = options ? {}
  @template = template
  @parent = parent
  if not parent?
    @paths_to_expand = []

  return

_.extend TemplateParser.prototype,
  lookup: (key, arg) ->
    if @["lookup:#{key}"]?
      return @["lookup:#{key}"](key, arg)

    @logger.warn "Using default lookup, this is not recommended, please define a method 'lookup:#{key}' on the TemplateParser.prototype"

    return getFromTemplateOrParents(key)

  "lookup:key": getFromTemplateOnly

  "lookup:dep_id": getFromTemplateOnly

  "lookup:title": ->
    if (i18n_title = @template.title_i18n)?
      user_id = @users.performing_user
      if _.isFunction i18n_title
        return i18n_title user_id
      if _.isObject i18n_title
        return APP.justdo_i18n.tr i18n_title.key, i18n_title.options, user_id
      return APP.justdo_i18n.tr i18n_title, {}, user_id

    return @template.title

  "lookup:events": getFromTemplateOnly

  "lookup:parents": getFromTemplateOnly

  "lookup:state": getFromTemplateOnly

  "lookup:start_date": getFromTemplateOnly

  "lookup:end_date": getFromTemplateOnly

  "lookup:due_date": getFromTemplateOnly

  "lookup:follow_up": getFromTemplateOnly

  "lookup:expand": getFromTemplateOnly

  "lookup:sub_tasks": (key) ->
    return @template.sub_tasks ? @template.tasks

  "lookup:users": getFromTemplateOrParents

  "lookup:owner": getFromTemplateOrParents

  "lookup:pending_owner": getFromTemplateOrParents

  "lookup:perform_as": (key, event_perform_as) ->
    parent = @parent
    while parent?
      if parent.options?[key]?
        return parent.options[key]
      parent = parent.parent

    if event_perform_as?
      return event_perform_as

    return getFromTemplateOrParents.call(@, key)

  "lookup:root_task_id": getFromOptionsOrParents

  "lookup:project_id": getFromOptionsOrParents

  "lookup:status_i18n": ->
    if not (status_i18n = getFromTemplateOnly.call(@, "status_i18n"))?
      return

    perform_as = @user @lookup "perform_as"

    if _.isObject status_i18n
      status = APP.justdo_i18n.tr status_i18n.key, status_i18n.options, perform_as
    if _.isString status_i18n
      status = APP.justdo_i18n.tr status_i18n, {}, perform_as
    return status
  
  "lookup:archived": ->
    if getFromTemplateOnly.call(@, "archived")
      return new Date()
    return null

  "lookup:path": (key) ->
    if @parent?.task_id? and @parent?.task_id isnt "/"
      return "/#{@parent.task_id}/"
    if (root_task_id = @lookup "root_task_id")? and root_task_id isnt "/"
      return  "/#{root_task_id}/"
    return "/"

  user: (key) ->
    return @users[key]

  task: (key) ->
    return @tasks[key]

  createTasks: (tasks) ->
    for task in tasks
      parser = new TemplateParser(task, null, @)
      task = parser.createTask()

    return

  createTask: ->
    path = @lookup "path"
    user = @user @lookup "perform_as"

    task_props =
      project_id: @lookup "project_id"
      title: @lookup "title"
      start_date: @lookup "start_date"
      end_date: @lookup "end_date"
      due_date: @lookup "due_date"
      follow_up: @lookup "follow_up"
      state: @lookup "state"
      archived: @lookup "archived"
    
    if (status = @lookup "status_i18n")?
      task_props.status = status

    @task_id = APP.projects._grid_data_com.addChild path, task_props, user

    if (key = @lookup "key")
      @tasks[key] = @task_id

    if (users = @lookup "users")
      @addUsers(users)

    if (owner = @lookup "owner")
      @setOwner(owner)

    if (pending_owner = @lookup "pending_owner")
      @setPendingOwner(pending_owner)

    if (tasks = @lookup "sub_tasks")
      @createTasks(tasks)

    if (parents = @lookup "parents")
      @addParents(parents)

    if (events = @lookup "events")
      @addEvents(events)

    if (expand = @lookup "expand")
      @setExpand()

  addUsers: (users) ->
    perform_as = @user @lookup "perform_as"
    EventsAPI.addUsers.call(@, @task_id, users, perform_as)

  setOwner: (user) ->
    perform_as = @user @lookup "perform_as"
    EventsAPI.setOwner.call(@, @task_id, user, perform_as)

  setPendingOwner: (user) ->
    perform_as = @user @lookup "perform_as"
    EventsAPI.setPendingOwner.call(@, @task_id, user, perform_as)

  addParents: (parents) ->
    perform_as = @lookup "perform_as"
    @postponed_internal_actions.push
      action: "addParents"
      task_id: @task_id
      perform_as: perform_as
      args: parents

  addEvents: (events) ->
    _.each events, (event) =>
      perform_as = @lookup "perform_as", event.perform_as
      @events.push
        action: event.action
        task_id: @task_id
        perform_as: perform_as
        args: event.args

  runEvents: ->
    _.each @postponed_internal_actions, (event) =>
      perform_as = @user event.perform_as
      # Warn the user that the action doesn't exist if it doesn't exist,
      # skip the event
      EventsAPI[event.action].call(@, event.task_id, event.args, perform_as)

    _.each @events, (event) =>
      perform_as = @user event.perform_as
      # Warn the user that the action doesn't exist if it doesn't exist,
      # skip the event
      EventsAPI[event.action].call(@, event.task_id, event.args, perform_as)

    return

  setExpand: ->
    task_ids = [@task_id]
    parent = @parent

    # Traverse up the tree of TemplateParser objects, until we get to the root
    while parent?.task_id?
      task_ids.push parent.task_id
      parent = parent.parent

    path_to_expand = GridData.helpers.joinPathArray task_ids.reverse()
    # Add expanded paths to the root TemplateParser
    parent.paths_to_expand.push path_to_expand
    return

EventsAPI =
  addUsers: (task_id, users, perform_as) ->
    update =
      $set:
        users: _.map users, (user) => @user user
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  setOwner: (task_id, user, perform_as) ->
    update =
      $set:
        owner_id: @user user
        pending_owner_id: null
        is_removed_owner: null
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  setPendingOwner: (task_id, user, perform_as) ->
    update =
      $set:
        pending_owner_id: @user user
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  setFollowUp: (task_id, follow_up, perform_as) ->
    update =
      $set:
        follow_up: follow_up
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  setDueDate: (task_id, due_date, perform_as) ->
    update =
      $set:
        due_date: due_date
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  setStatus: (task_id, status_i18n, perform_as) ->
    if _.isObject status_i18n
      status = APP.justdo_i18n.tr status_i18n.key, status_i18n.options, perform_as
    else
      status = APP.justdo_i18n.tr status_i18n, {}, perform_as
    update =
      $set:
        status: status
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  setState: (task_id, state, perform_as) ->
    update =
      $set:
        state: state
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  addParents: (task_id, parents, perform_as) ->
    for parent in parents
      update =
        parent: @task parent

      APP.projects._grid_data_com.addParent task_id, update, perform_as

  removeParents: (task_id, parents, perform_as) ->
    for parent in parents
      APP.projects._grid_data_com.removeParent "/#{@task parent}/#{task_id}/", perform_as

  setArchived: (task_id, args, perform_as) ->
    update =
      $set:
        archived: new Date()
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  unsetArchived: (task_id, args, perform_as) ->
    update =
      $set:
        archived: null
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  toggleIsProject: (task_id, args, perform_as) ->
    APP.justdo_delivery_planner.toggleTaskIsProject task_id, perform_as

  update: (task_id, update, perform_as) ->
    APP.projects._grid_data_com.updateItem task_id, update, perform_as

  # deps: (An arrey of dep_id OR object that has the same structure as items inside justdo_task_dependencies_mf)
  #   dep_id: (String) key as defined in template obj
  #   type: (String) Supported dependency type (default is F2S), optional
  #   lag: (Number) Lag in days, optional
  addGanttDependency: (task_id, deps, perform_as) ->
    if _.isString deps
      deps = [deps]
    if _.isEmpty deps
      return
    
    deps = _.map deps, (dep) => 
      if _.isString dep
        dep_id = dep
      else
        dep_id = dep.dep_id
      dep_task_id = @tasks[dep_id]
      dep_obj = {task_id: dep_task_id, type: deps.type or "F2S", lag: deps.lag or 0}
      return dep_obj

    update = 
      $set:
        "#{JustdoPlanningUtilities.dependencies_mf_field_id}": deps
    
    APP.projects._grid_data_com.updateItem task_id, update, perform_as
