import { checkNpmVersions } from "meteor/tmeasday:check-npm-versions"
checkNpmVersions({
  "swiper": "11.1.x"
}, "justdoinc:justdo-plugin-store")
import Swiper from "swiper"
import Navigation from "swiper/modules/navigation.mjs"
import Pagination from "swiper/modules/pagination.mjs"
import Keyboard from "swiper/modules/keyboard.mjs"

Template.justdo_plugins_store_plugin_page.onCreated ->
  @store_manager = @data.store_manager

  return

Template.justdo_plugins_store_plugin_page.onRendered ->
  swiper = new Swiper($(".swiper")[0], {
    modules: [Navigation, Pagination, Keyboard],
    speed: 600,
    initialSlide: 0,
    grabCursor: true,
    slidesPerView: 'auto',
    centeredSlides: true,
    watchSlidesProgress: true,
    keyboard: true,
    loop: true
    pagination:
      el: ".swiper-pagination",
      clickable: true
    navigation:
      nextEl: ".swiper-button-next",
      prevEl: ".swiper-button-prev"
  })

  @autorun ->
    # Prevent changing between ltr/rtl lang from breaking the swiper content
    dir = "ltr"
    if APP.justdo_i18n.isRtl()
      dir = "rtl"
    swiper.changeLanguageDirection dir
  
    # Ensure navigation is working consistently between ltr/rtl lang
    swiper.navigation.destroy()
    if dir is "ltr"
      nextEl = ".swiper-button-next"
      prevEl = ".swiper-button-prev"
    else
      nextEl = ".swiper-button-prev"
      prevEl = ".swiper-button-next"
    swiper.params.navigation.nextEl = nextEl
    swiper.params.navigation.prevEl = prevEl
    swiper.navigation.init()

    return
  
  return

Template.justdo_plugins_store_plugin_page.helpers
  getActivePluginPageObject: ->
    tpl = Template.instance()

    return tpl.store_manager.getActivePluginPageObject()

  activePluginPagePluginInstallable: ->
    tpl = Template.instance()

    return tpl.store_manager.activePluginPagePluginInstallable()

  activePluginPagePluginInstalled: ->
    tpl = Template.instance()

    return tpl.store_manager.activePluginPagePluginInstalled()

  activePluginPagePluginEnabledForEnvironment: ->
    tpl = Template.instance()

    return tpl.store_manager.activePluginPagePluginEnabledForEnvironment()

  isProjectPage: ->
    if (cur_proj = APP?.modules?.project_page?.curProj())?
      return true

    return false

  isProjectPageAdmin: ->
    if (cur_proj = APP?.modules?.project_page?.curProj())?
      if cur_proj.isAdmin()
        return true

    return false
  
  categories: -> _.map @categories, (category) -> APP.justdo_plugin_store.getCategoryById category
  
  getActiveCategory: ->
    tpl = Template.instance()

    return tpl.store_manager.getActiveCategory()

  getDefaultCategory: ->
    tpl = Template.instance()

    return tpl.store_manager.getDefaultCategory()

  hasMoreThanOneSliderItems: ->
    tpl = Template.instance()

    plugin_def = tpl.store_manager.getActivePluginPageObject()

    if not (slider = plugin_def.slider)?
      return false

    return slider.length > 1

  developerI18n: -> TAPi18n.__ @developer

Template.justdo_plugins_store_plugin_page.events
  "click .install-toggle-btn": (e, tpl) ->
    return tpl.store_manager.activePluginPagePluginToggleInstallPage()

  "click .return-to-menu": (e, tpl) ->
    tpl.store_manager.clearActivePluginPage()

    Tracker.flush()

    $(".store-front").scrollTop(0)
    $(document).scrollTop(0)

    return
