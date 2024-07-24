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

  categories: ->
    tpl = Template.instance()

    cat_names = _.map @categories, (cat_id) ->
      cat_def = _.find tpl.store_manager.listCategories(), (c) -> c.id is cat_id
      cat_label_i18n = cat_def?.label or "plugin_store_category_unknown_label"
      return TAPi18n.__ cat_label_i18n

    return cat_names.join(" &bull; ")
  
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
