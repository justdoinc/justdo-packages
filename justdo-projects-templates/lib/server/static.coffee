_.extend JustDoProjectsTemplates,
  ai_requests:
    stream_project_template:
      api_provider: "openai"
      requestGeneratorOptionsSchema: new SimpleSchema
        msg:
          type: String
          min: 1
          max: 4096
      requestGenerator: (req_options) ->
        {msg} = req_options

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
              "content": "Tech startup"
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
              "role" : "user",
              "content" : "科技公司"
            },
            {
              "role" : "assistant",
              "content" : """[["技術部門","","","",6,0,-1],["軟體開發","","","",6,1,0],["確定產品需求",1,5,5,1,2,1],["設計架構",2,7,7,1,3,1],["編碼與測試",5,10,10,1,4,1],["部署產品",9,15,15,1,5,1],["升級與維護",13,20,20,1,6,1],["資料分析","","","",6,7,0],["收集資料",1,5,5,1,8,7],["數據清理",3,7,7,1,9,7],["數據分析",5,10,10,1,10,7],["生成報告",8,15,15,1,11,7],["營銷與促銷","","","",6,12,0],["市場研究",1,5,5,1,13,12],["制定行銷策略",5,10,10,1,14,12],["制作廣告素材",8,15,15,1,15,12],["展覽會籌辦",11,20,20,1,16,12],["客戶關係管理","","","",6,17,0],["建立客戶數據庫",1,5,5,1,18,17],["跟進客戶查詢",4,8,8,1,19,17],["解決客戶問題",7,12,12,1,20,17],["客戶滿意度調查",10,15,15,1,21,17],["資訊安全","","","",6,22,0],["制定安全政策",2,5,5,1,23,22],["實施數據加密",5,8,8,1,24,22],["定期安全審查",8,12,12,1,25,22],["應急響應計劃",11,15,15,1,26,22],["人事及管理","","","",6,27,0],["人員招聘",1,5,5,1,28,27],["培訓與發展",5,10,10,1,29,27],["績效評估與反饋",10,15,15,1,30,27],["管理團隊動態",13,20,20,1,31,27],["財務管理","","","",6,32,0],["預算分配",2,5,5,1,33,32],["財務報告",6,10,10,1,34,32],["風險管理",8,12,12,1,35,32],["投資計劃",11,15,15,1,36,32],["業務擴展","","","",6,37,0],["新客戶開發",3,7,7,1,38,37],["合作夥伴關係",8,12,12,1,39,37],["尋找新市場機會",10,15,15,1,40,37],["擴展產品線",12,18,18,1,41,37],["技術支援","","","",6,42,0],["客戶支援",1,5,5,1,43,42],["數據恢復服務",5,10,10,1,44,42],["系統維護",10,15,15,1,45,42],["產品更新",15,20,20,1,46,42]]"""
            },
            {
              "role" : "user",
              "content" : "診所"
            },
            {
              "role" : "assistant",
              "content" : """[["醫療部門","","","",6,0,-1],["患者治療","","","",6,1,0],["診斷患者",1,5,5,1,2,1],["制定治療方案",3,7,7,1,3,1],["實施治療",5,10,10,1,4,1],["追蹤治療效果",8,15,15,1,5,1],["預防保健","","","",6,6,0],["定期檢查",1,5,5,1,7,6],["疫苗接種",4,8,8,1,8,6],["宣導健康生活方式",7,12,12,1,9,6],["疾病預防教育",10,15,15,1,10,6],["緊急處置","","","",6,11,0],["急救培訓",1,5,5,1,12,11],["應對意外傷害",3,8,8,1,13,11],["處理急症疾病",6,12,12,1,14,11],["轉診安排",10,15,15,1,15,11],["患者關係管理","","","",6,16,0],["溝通患者需求",2,5,5,1,17,16],["回應患者查詢",5,8,8,1,18,16],["解決投訴",8,12,12,1,19,16],["建立信任關係",11,15,15,1,20,16],["資訊技術","","","",6,21,0],["病歷管理系統",2,5,5,1,22,21],["數據保護措施",4,8,8,1,23,21],["數據分享許可",7,12,12,1,24,21],["資訊安全檢查",10,15,15,1,25,21],["人事管理","","","",6,26,0],["招聘新人員",1,5,5,1,27,26],["培訓與發展計劃",5,10,10,1,28,26],["績效評估流程",10,15,15,1,29,26],["職位調整",13,20,20,1,30,26],["財務管理","","","",6,31,0],["預算制定",2,5,5,1,32,31],["費用核算",6,10,10,1,33,31],["資金管理",8,12,12,1,34,31],["財務報告",11,15,15,1,35,31],["品質保證","","","",6,36,0],["品質控制標準制定",3,7,7,1,37,36],["持續監控",5,10,10,1,38,36],["改進標準作業流程",8,15,15,1,39,36],["外部品質審查",12,18,18,1,40,36],["設備維護","","","",6,41,0],["定期檢修",2,5,5,1,42,41],["故障排除",4,8,8,1,43,41],["更新設備",7,12,12,1,44,41],["技術支援",10,15,15,1,45,41]]"""
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
      cachedResponseCondition: (req_options, pub_id, user_id) ->
        {msg} = req_options
        return APP.justdo_projects_templates.getTemplateById(msg)?
      cachedResponsePublisher: (req_options, pub_id, user_id) ->
        {msg} = req_options

        template_obj = APP.justdo_projects_templates.getTemplateById(msg)
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
          
          @added "ai_response", fields._id, fields
          key += 1

          if (subtasks = template_task.tasks)?
            for subtask in subtasks
              _recursiveParseAndPublishTemplateTask.call @, subtask, fields.key

          return
        
        template_tasks = template_obj.template.tasks
        for template_task in template_tasks
          _recursiveParseAndPublishTemplateTask.call @, template_task, -1
        
        return
      streamedResponsePublisher: (res_data, req_options, pub_id) ->
        _parseStreamedTasks = (task_arr, pub_id) ->
          states = ["pending", "in-progress", "done", "will-not-do", "on-hold", "duplicate", "nil"]          
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

        if res_data.intermediate_res.includes "]"
          # Replace double brackets with single brackets
          res_data.intermediate_res = res_data.intermediate_res.replace /\[\s*\[/g, "["
          res_data.intermediate_res = res_data.intermediate_res.replace /\]\s*\]/g, "]"

          # When the intermediate_res contains a complete task, parse and publish the task. Keep the remaining tokens in intermediate_res for future chunks.
          [finished_intermediate_res, incomplete_intermediate_res] = res_data.intermediate_res.split(/],?/)

          # Add back the missing bracket from .split()
          finished_intermediate_res += "]"

          task_arr = JSON.parse finished_intermediate_res
          task = _parseStreamedTasks task_arr, pub_id
          @added "ai_response", task._id, task
          res_data.intermediate_res = incomplete_intermediate_res

        return

    stream_child_tasks:
      api_provider: "openai"
      requestGeneratorOptionsSchema: new SimpleSchema
        project: 
          type: String
          optional: true
        target_task:
          type: String
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
      requestGenerator: (options) ->
        req = 
          "model": JustDoProjectsTemplates.openai_template_generation_model,
          "messages": [
            {
              "role": "system",
              "content": """
                You are a task generator of a project management system. Generate tasks based on user input. Be creative and try to come up with subtasks under the target task.

                User input will be a JSON object containing the project context.
                "project context" contains the project title, and the surrounding tasks of the target task, including "parents", "siblings", and "children".
                "target task" is always the last element in the "parents" array.

                The schema of user input is provided below. The "description" of each schema field contains instruction on how the data should be handled.
                ### User input JSON schema begin ###
                {
                  "project": {
                    "type": "string",
                    "description": "Title of the project.",
                    "optional": true
                  },
                  "target_task": {
                    "type": "string",
                    "description": "Title of the target task. This is the task you will be generating subtasks for. Ensure the generated task are relevant to this task.",
                    "optional": true
                  },
                  "parents": {
                    "type": "array",
                    "description": "Array of parent task titles. The first element is the top level parent, and the last element is the immidiate parent of the target task.",
                    "optional": true
                  },
                  "siblings": {
                    "type": "array",
                    "description": "Array of same-level task titles provided to you to understand what the project is about.",
                    "optional": true
                  },
                  "children": {
                    "type": "array",
                    "description": "Array of existing children task titles under the target task.",
                    "optional": true
                  }
                }
                ### User input JSON schema ends ###

                Note that "parents", "siblings", "children" are provided to you to understand the context of the project.
                Never generate tasks that are already in the project, or tasks that should be children of other tasks.

                The length of parents indicates the depth of the target task. As the depth increases, the scope of the task should decrease.
                Example 1: If there are only a 1 to 2 parents and no children, generated tasks should be broad in scope (like departments, categories, sub-projects, etc. each with their own relevant subtasks).
                Example 2: If there are multiple parnets and some children, generated tasks should be more specific and are actionable items or examples of the target task.

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

                Ensure the language of generated tasks are the same as the target task.

                To reduce the size of task definition, use an array to represent a task. The array must contain only the value of the task object, in the order of the schema.
                Generate 5 to 20 tasks in total. Return only the array without any formatting like whitespaces and line breakes.

              """.trim()
            },
            {
              "role": "user",
              "content": """{"project": "Untitled JustDo","target_task": "Trip to Hong Kong", "parents": ["Travel Planning"]}"""
            },
            {
              "role" : "assistant",
              "content" : """[["Transportation",0,-1],["Book Flight Tickets",1,0],["Arrange Airport Transfer",2,0],["Accommodation",3,-1],["Hotel Reservation",4,3],["Check-in Online",5,3],["Activities",6,-1],["Sightseeing Tours Booking",7,6],["Dining Reservations",8,6],["Shopping Plans",9,6],["Emergency Contact List",10,6]]"""
            },
            {
              "role" : "user",
              "content" : """{"project":"Travel ideas","target_task":"Israel","parents":["Locations"],"siblings":["Hong Kong","Vietnam","Korea","Russia"],"children":["Transportation"]}"""
            },
            {
              "role" : "assistant",
              "content" : """[["Accommodation",0,-1],["Hotel Reservation",1,0],["Check-in Procedures",2,0],["Explore Attractions",3,-1],["Historical Sites Visits",4,3],["Cultural Landmarks Tour",5,3],["Food and Drinks",6,3],["Local Cuisine Tasting",7,6],["Street Food Exploration",8,6],["Modern Bistros Visit",9,6],["Shopping",10,-1],["Souvenir Hunting",11,10],["Local Markets Exploration",12,10],["Specialty Stores Visit",13,16]]"""
            },
            {
              "role" : "user",
              "content" : """{"project":"Untitled JustDo","target_task":"User Interface Design","parents":["R&D","Mobile App Development","Sprints","v1.0.0","Implement new feature 1","Design & UX/UI"]}"""
            },
            {
              "role" : "assistant",
              "content" : """[["Interaction Design",0,-1],["Wireframes Creation",1,0],["Prototyping",2,0],["Visual Design",3,-1],["Create Style Guide",4,3],["Design Mockups",5,3],["Iconography",6,3],["User Testing",7,-1],["Prepare Test Scenarios",8,7],["Conduct User Interviews",9,7],["Collect Feedback",10,7],["Iterate Design",11,7]]"""
            },
            {
              "role" : "user",
              "content" : """{"project":"Hospital Management","target_task":"Pre-Op Procedures","parents":["Clinical Services","Surgical Services"],"siblings":["Surgical Team Coordination","Post-Op Care Plans","Equipment Sterilization"],"children":[]}"""
            },
            {
              "role" : "assistant",
              "content" : """[["Patient Assessment",0,-1],["Medical History Review",1,0],["Physical Examination",2,0],["Pre-Surgery Instructions",3,0],["Consent Form Signing",4,0],["Lab Tests",5,-1],["Blood Work",6,5],["X-Rays",7,5],["ECG",8,5],["Pre-Surgery Checklist",9,-1],["Verify Consent",10,9],["Confirm Allergies",11,9],["Prepare Equipment",12,9],["Anesthesia Assessment",13,9]]"""
            },
            {
                "role" : "user",
                "content" : """{"project":"Hospital Management","target_task":"Post-Op Care Plans","parents":["Clinical Services","Surgical Services"],"siblings":["Surgical Team Coordination","Pre-Op Procedures","Equipment Sterilization"]}"""
            },
            {
                "role" : "assistant",
                "content" : """[["Patient Monitoring",0,-1],["Vital Signs Tracking",1,0],["Symptom Assessment",2,0],["Medication Administration",3,0],["Progress Notes Documentation",4,0],["Recovery Plan Implementation",5,-1],["Activity Monitoring",6,5],["Diet Supervision",7,5],["Pain Management",8,5],["Follow-up Appointments Scheduling",9,5],["Post-Discharge Care",10,-1],["Home Care Instructions",11,10],["Medication Regimen Explanation",12,10],["Rehabilitation Referrals",13,10],["Symptom Monitoring Plan",14,10]]"""
            },
            {
                "role" : "user",
                "content" : """{"project":"咖啡店管理","target_task":"社交媒體宣傳","parents":["營銷推廣"]},"siblings": ["舉辦試喝活動", "優惠促銷策略"]"""
            },
            {
                "role" : "assistant",
                "content" : """[["線上活動",0,-1],["推文創作",1,0],["社群互動",2,0],["市場分析",3,0],["品牌形象",4,-1],["設計視覺元素",5,4],["制定廣告策略",6,4],["品牌定位優化",7,4],["優惠促銷",8,-1],["設計促銷活動",9,8],["製作宣傳物料",10,8],["執行促銷計劃",11,8]]"""
            },
            {
              "role" : "user",
              "content" : """{"project":"IT firm management","target_task":"Backend Development","parents":["R&D","Mobile App Development","Sprints","v1.0.0","Implement new feature 1"],"siblings":["Design & UX/UI","Frontend Development","QA"],"children":["Feature B"]}"""
            },
            {
              "role" : "assistant",
              "content" : """[["Database Design",0,-1],["ER Diagram Creation",1,0],["Schema Implementation",2,0],["API Development",3,-1],["Endpoint Creation",4,3],["Data Manipulation Functions",5,3],["Security Integration",6,-1],["Authentication Systems",7,6],["Authorization Processes",8,6],["Performance Optimization",9,-1],["Database Queries Refinement",10,9],["Query Caching Implementation",11,9],["Error Handling Enhancement",12,9]]"""
            },
            {
              "role": "user",
              "content": JSON.stringify options
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
      streamedResponsePublisher: (res_data, req_options, pub_id) ->
        _parseStreamedTasks = (task_arr, pub_id) ->
          [title, key, parent_task_key] = task_arr

          fields = 
            _id: "#{key}_#{pub_id}"
            key: key
            pub_id: pub_id
            parent: parent_task_key
            title: title
            state: "pending"

          return fields
          
        if res_data.intermediate_res.includes "]"
          # Replace double brackets with single brackets
          res_data.intermediate_res = res_data.intermediate_res.replace /\[\s*\[/g, "["
          res_data.intermediate_res = res_data.intermediate_res.replace /\]\s*\]/g, "]"

          # When the intermediate_res contains a complete task, parse and publish the task. Keep the remaining tokens in intermediate_res for future chunks.
          [finished_intermediate_res, incomplete_intermediate_res] = res_data.intermediate_res.split(/],?/)

          # Add back the missing bracket from .split()
          finished_intermediate_res += "]"

          task_arr = JSON.parse finished_intermediate_res
          task = _parseStreamedTasks task_arr, pub_id
          @added "ai_response", task._id, task
          res_data.intermediate_res = incomplete_intermediate_res
