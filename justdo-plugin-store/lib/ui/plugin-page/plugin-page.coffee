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
  swiper = null
  @autorun ->
    is_rtl = APP.justdo_i18n.isRtl()

    if swiper?
      swiper.destroy?()

    # Wrap the re-init of swiper inside a defer to give time for the DOM to update
    Meteor.defer ->
      swiper = new Swiper $(".swiper")[0], 
        modules: [Navigation, Pagination, Keyboard]
        speed: 600
        initialSlide: 0
        grabCursor: true
        slidesPerView: 'auto'
        centeredSlides: true
        watchSlidesProgress: true
        keyboard: true
        loop: true
        pagination:
          el: ".swiper-pagination"
          clickable: true
        navigation:
          nextEl: if is_rtl then ".swiper-button-prev" else ".swiper-button-next"
          prevEl: if is_rtl then ".swiper-button-next" else ".swiper-button-prev"
      return
    
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
