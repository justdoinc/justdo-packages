_.extend JustdoI18n,
  plugin_human_readable_name: "justdo-i18n"
  default_lang: "en"
  amplify_lang_key: "lang"
  amplify_hide_top_banner_key: "hide_top_banner"
  supported_rtl_langs: ["he", "ar"] # RTL will be enabled for these languages
  # The following locale confs are taken directly from https://github.com/jquery/jquery-ui/tree/main/ui/i18n
  jquery_ui_datepicker_locale_confs:
    vi:
      closeText: 'Đóng'
      prevText: 'Trước'
      nextText: 'Tiếp'
      currentText: 'Hôm nay'
      monthNames: [
        'Tháng Một'
        'Tháng Hai'
        'Tháng Ba'
        'Tháng Tư'
        'Tháng Năm'
        'Tháng Sáu'
        'Tháng Bảy'
        'Tháng Tám'
        'Tháng Chín'
        'Tháng Mười'
        'Tháng Mười Một'
        'Tháng Mười Hai'
      ]
      monthNamesShort: [
        'Tháng 1'
        'Tháng 2'
        'Tháng 3'
        'Tháng 4'
        'Tháng 5'
        'Tháng 6'
        'Tháng 7'
        'Tháng 8'
        'Tháng 9'
        'Tháng 10'
        'Tháng 11'
        'Tháng 12'
      ]
      dayNames: [
        'Chủ Nhật'
        'Thứ Hai'
        'Thứ Ba'
        'Thứ Tư'
        'Thứ Năm'
        'Thứ Sáu'
        'Thứ Bảy'
      ]
      dayNamesShort: [
        'CN'
        'T2'
        'T3'
        'T4'
        'T5'
        'T6'
        'T7'
      ]
      dayNamesMin: [
        'CN'
        'T2'
        'T3'
        'T4'
        'T5'
        'T6'
        'T7'
      ]
      weekHeader: 'Tu'
      dateFormat: 'dd/mm/yy'
      firstDay: 0
      isRTL: false
      showMonthAfterYear: false
      yearSuffix: ''
    "zh-TW": 
      closeText: '關閉'
      prevText: '上個月'
      nextText: '下個月'
      currentText: '今天'
      monthNames: [
        '一月'
        '二月'
        '三月'
        '四月'
        '五月'
        '六月'
        '七月'
        '八月'
        '九月'
        '十月'
        '十一月'
        '十二月'
      ]
      monthNamesShort: [
        '一月'
        '二月'
        '三月'
        '四月'
        '五月'
        '六月'
        '七月'
        '八月'
        '九月'
        '十月'
        '十一月'
        '十二月'
      ]
      dayNames: [
        '星期日'
        '星期一'
        '星期二'
        '星期三'
        '星期四'
        '星期五'
        '星期六'
      ]
      dayNamesShort: [
        '週日'
        '週一'
        '週二'
        '週三'
        '週四'
        '週五'
        '週六'
      ]
      dayNamesMin: [
        '日'
        '一'
        '二'
        '三'
        '四'
        '五'
        '六'
      ]
      weekHeader: '週'
      dateFormat: 'yy/mm/dd'
      firstDay: 1
      isRTL: false
      showMonthAfterYear: true
      yearSuffix: '年'
  # Translates our format of lang tag to Vimeo's
  vimeo_lang_tags:
    "zh-TW": "zh-Hant"
