_.extend JustDoProjectsTemplates,
  template_grid_views:
    gantt:
      [
          {
              "field": "title",
              "width": 400,
              "filter": null,
              "frozen": true
          },
          {
              "field": "justdo_grid_gantt",
              "width": 500
          },
          {
              "field": "jpu:basket_start_date_formatter",
              "width": 122,
              "filter": null
          },
          {
              "field": "jpu:basket_end_date_formatter",
              "width": 122,
              "filter": null
          },
          {
              "field": "state",
              "width": 122,
              "filter": null
          },
          {
              "field": "status",
              "width": 196
          },
          {
              "field": "priv:follow_up",
              "width": 150,
              "filter": null
          }
      ]