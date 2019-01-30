###
  PageTitleManager controls the document title with 3 parts - <page> - <section> - suffix

  To use:

   ptm = new JustdoPageTitle.PageTitleManager {
        [suffix: <suffix>,]
        [page: <page title>, ]
        [section: <section title>, ]
        [set_on_init: <true|false>] - default to true
      }
  ...
  ptm.setSuffix 'myApp'
  ptm.setPageName 'myPage'
  ptm.setSection 'mySection'
###

default_options =
  page: ""
  section: ""
  prefix: ""
  suffix: ""
  set_on_init: true

PageTitleManager = (options) ->
  @options = _.extend {}, default_options, options

  @page = options.page
  @section = options.section
  @prefix = options.prefix
  @suffix = options.suffix

  if options.set_on_init
    @updateTitle()

_.extend PageTitleManager.prototype,
  setPrefix: (prefix = "") ->
    @prefix = prefix

    @updateTitle()

  setSuffix: (suffix = "") ->
    @suffix = suffix

    @updateTitle()

  setPageName: (page = "") ->
    @page = page
    @section = ""

    @updateTitle()

  setSectionName: (section = "") ->
    @section = section

    @updateTitle()

  updateTitle: ->
    if not Meteor.isClient
      # Server side have no meaning at the moment
      return

    title = _.filter([@page, @section, @suffix], (t) -> not _.isEmpty(t)).join(" - ")

    if not _.isEmpty(@prefix)
      title = @prefix + " " + title

    document.title = title