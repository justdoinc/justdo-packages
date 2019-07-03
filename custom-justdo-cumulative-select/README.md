To install: APP.modules.project_page.curProj().enableCustomFeatures("justdo_checklist_fields")

To remove: APP.modules.project_page.curProj().disableCustomFeatures("justdo_checklist_fields")

## Note regarding editor/formatter

Due to limitation of the More Info section of the task pane that doesn't print formatters html
but their textual output, we are using the editors for the More Info section, and the formatters
on the grid. However, we don't want the grid the formatters to change into editors, we block that
using the BeforeEditCell handler of the grid control