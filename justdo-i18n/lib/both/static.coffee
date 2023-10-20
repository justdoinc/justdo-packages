_.extend JustdoI18n,
  plugin_human_readable_name: "justdo-i18n"
  default_lang: "en"
  amplify_lang_key: "lang"
  amplify_hide_top_banner_key: "hide_top_banner"
  # The following locale confs are taken directly from https://github.com/moment/moment/tree/develop/locale
  moment_locale_confs:
    vi:
      months: 'tháng 1_tháng 2_tháng 3_tháng 4_tháng 5_tháng 6_tháng 7_tháng 8_tháng 9_tháng 10_tháng 11_tháng 12'.split('_')
      monthsShort: 'Thg 01_Thg 02_Thg 03_Thg 04_Thg 05_Thg 06_Thg 07_Thg 08_Thg 09_Thg 10_Thg 11_Thg 12'.split('_')
      monthsParseExact: true
      weekdays: 'chủ nhật_thứ hai_thứ ba_thứ tư_thứ năm_thứ sáu_thứ bảy'.split('_')
      weekdaysShort: 'CN_T2_T3_T4_T5_T6_T7'.split('_')
      weekdaysMin: 'CN_T2_T3_T4_T5_T6_T7'.split('_')
      weekdaysParseExact: true
      meridiemParse: /sa|ch/i
      isPM: (input) ->
        /^ch$/i.test input
      meridiem: (hours, minutes, isLower) ->
        if hours < 12
          if isLower then 'sa' else 'SA'
        else
          if isLower then 'ch' else 'CH'
      longDateFormat:
        LT: 'HH:mm'
        LTS: 'HH:mm:ss'
        L: 'DD/MM/YYYY'
        LL: 'D MMMM [năm] YYYY'
        LLL: 'D MMMM [năm] YYYY HH:mm'
        LLLL: 'dddd, D MMMM [năm] YYYY HH:mm'
        l: 'DD/M/YYYY'
        ll: 'D MMM YYYY'
        lll: 'D MMM YYYY HH:mm'
        llll: 'ddd, D MMM YYYY HH:mm'
      calendar:
        sameDay: '[Hôm nay lúc] LT'
        nextDay: '[Ngày mai lúc] LT'
        nextWeek: 'dddd [tuần tới lúc] LT'
        lastDay: '[Hôm qua lúc] LT'
        lastWeek: 'dddd [tuần trước lúc] LT'
        sameElse: 'L'
      relativeTime:
        future: '%s tới'
        past: '%s trước'
        s: 'vài giây'
        ss: '%d giây'
        m: 'một phút'
        mm: '%d phút'
        h: 'một giờ'
        hh: '%d giờ'
        d: 'một ngày'
        dd: '%d ngày'
        w: 'một tuần'
        ww: '%d tuần'
        M: 'một tháng'
        MM: '%d tháng'
        y: 'một năm'
        yy: '%d năm'
      dayOfMonthOrdinalParse: /\d{1,2}/
      ordinal: (number) ->
        number
      week:
        dow: 1
        doy: 4
    "zh-tw":
      months: '一月_二月_三月_四月_五月_六月_七月_八月_九月_十月_十一月_十二月'.split('_')
      monthsShort: '1月_2月_3月_4月_5月_6月_7月_8月_9月_10月_11月_12月'.split('_')
      weekdays: '星期日_星期一_星期二_星期三_星期四_星期五_星期六'.split('_')
      weekdaysShort: '週日_週一_週二_週三_週四_週五_週六'.split('_')
      weekdaysMin: '日_一_二_三_四_五_六'.split('_')
      longDateFormat:
        LT: 'HH:mm'
        LTS: 'HH:mm:ss'
        L: 'YYYY/MM/DD'
        LL: 'YYYY年M月D日'
        LLL: 'YYYY年M月D日 HH:mm'
        LLLL: 'YYYY年M月D日dddd HH:mm'
        l: 'YYYY/M/D'
        ll: 'YYYY年M月D日'
        lll: 'YYYY年M月D日 HH:mm'
        llll: 'YYYY年M月D日dddd HH:mm'
      meridiemParse: /凌晨|早上|上午|中午|下午|晚上/
      meridiemHour: (hour, meridiem) ->
        if hour == 12
          hour = 0
        if meridiem == '凌晨' or meridiem == '早上' or meridiem == '上午'
          return hour
        else if meridiem == '中午'
          return if hour >= 11 then hour else hour + 12
        else if meridiem == '下午' or meridiem == '晚上'
          return hour + 12
        return
      meridiem: (hour, minute, isLower) ->
        hm = hour * 100 + minute
        if hm < 600
          '凌晨'
        else if hm < 900
          '早上'
        else if hm < 1130
          '上午'
        else if hm < 1230
          '中午'
        else if hm < 1800
          '下午'
        else
          '晚上'
      calendar:
        sameDay: '[今天] LT'
        nextDay: '[明天] LT'
        nextWeek: '[下]dddd LT'
        lastDay: '[昨天] LT'
        lastWeek: '[上]dddd LT'
        sameElse: 'L'
      dayOfMonthOrdinalParse: /\d{1,2}(日|月|週)/
      ordinal: (number, period) ->
        switch period
          when 'd', 'D', 'DDD'
            return number + '日'
          when 'M'
            return number + '月'
          when 'w', 'W'
            return number + '週'
          else
            return number
        return
      relativeTime:
        future: '%s後'
        past: '%s前'
        s: '幾秒'
        ss: '%d 秒'
        m: '1 分鐘'
        mm: '%d 分鐘'
        h: '1 小時'
        hh: '%d 小時'
        d: '1 天'
        dd: '%d 天'
        M: '1 個月'
        MM: '%d 個月'
        y: '1 年'
        yy: '%d 年'
