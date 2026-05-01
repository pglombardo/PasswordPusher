/**
 * LocalTime i18n for all application locales.
 * Structure matches LocalTime gem (camelCase). Fallback: gem default "en".
 * Call setLocalTimeLocaleFromDocument() after load to use document lang.
 */
import LocalTime from "local-time"

const { i18n } = LocalTime.config

function defineLocale(locale, spec) {
  i18n[locale] = {
    date: {
      dayNames: spec.dayNames,
      abbrDayNames: spec.abbrDayNames,
      monthNames: spec.monthNames,
      abbrMonthNames: spec.abbrMonthNames,
      yesterday: spec.yesterday,
      today: spec.today,
      tomorrow: spec.tomorrow,
      on: spec.on,
      formats: { default: "%b %e, %Y", thisYear: "%b %e" }
    },
    time: {
      am: spec.am,
      pm: spec.pm,
      singular: spec.singular,
      singularAn: spec.singularAn,
      elapsed: spec.elapsed,
      second: spec.second,
      seconds: spec.seconds,
      minute: spec.minute,
      minutes: spec.minutes,
      hour: spec.hour,
      hours: spec.hours,
      formats: { default: "%l:%M%P", default_24h: "%H:%M" }
    },
    datetime: {
      at: spec.datetimeAt,
      formats: { default: "%B %e, %Y at %l:%M%P %Z", default_24h: "%B %e, %Y at %H:%M %Z" }
    }
  }
}

const en = {
  dayNames: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
  abbrDayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
  monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
  abbrMonthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
  yesterday: "yesterday", today: "today", tomorrow: "tomorrow", on: "on {date}",
  am: "am", pm: "pm", singular: "a {time}", singularAn: "an {time}", elapsed: "{time} ago",
  second: "second", seconds: "seconds", minute: "minute", minutes: "minutes", hour: "hour", hours: "hours",
  datetimeAt: "{date} at {time}"
}
defineLocale("en", en)

const enGB = { ...en }
defineLocale("en-GB", enGB)

defineLocale("ca", {
  dayNames: ["diumenge", "dilluns", "dimarts", "dimecres", "dijous", "divendres", "dissabte"],
  abbrDayNames: ["dg.", "dl.", "dt.", "dc.", "dj.", "dv.", "ds."],
  monthNames: ["gener", "febrer", "març", "abril", "maig", "juny", "juliol", "agost", "setembre", "octubre", "novembre", "desembre"],
  abbrMonthNames: ["gen.", "febr.", "març", "abr.", "maig", "juny", "jul.", "ag.", "set.", "oct.", "nov.", "des."],
  yesterday: "ahir", today: "avui", tomorrow: "demà", on: "el {date}",
  am: "a. m.", pm: "p. m.", singular: "1 {time}", singularAn: "1 {time}", elapsed: "fa {time}",
  second: "segon", seconds: "segons", minute: "minut", minutes: "minuts", hour: "hora", hours: "hores",
  datetimeAt: "{date} a les {time}"
})

defineLocale("cs", {
  dayNames: ["neděle", "pondělí", "úterý", "středa", "čtvrtek", "pátek", "sobota"],
  abbrDayNames: ["ne", "po", "út", "st", "čt", "pá", "so"],
  monthNames: ["leden", "únor", "březen", "duben", "květen", "červen", "červenec", "srpen", "září", "říjen", "listopad", "prosinec"],
  abbrMonthNames: ["led", "úno", "bře", "dub", "kvě", "čvn", "čvc", "srp", "zář", "říj", "lis", "pro"],
  yesterday: "včera", today: "dnes", tomorrow: "zítra", on: "dne {date}",
  am: "dop.", pm: "odp.", singular: "1 {time}", singularAn: "1 {time}", elapsed: "před {time}",
  second: "sekunda", seconds: "sekundy", minute: "minuta", minutes: "minuty", hour: "hodina", hours: "hodiny",
  datetimeAt: "{date} v {time}"
})

defineLocale("cy", {
  dayNames: ["Dydd Sul", "Dydd Llun", "Dydd Mawrth", "Dydd Mercher", "Dydd Iau", "Dydd Gwener", "Dydd Sadwrn"],
  abbrDayNames: ["Sul", "Llun", "Maw", "Mer", "Iau", "Gwe", "Sad"],
  monthNames: ["Ionawr", "Chwefror", "Mawrth", "Ebrill", "Mai", "Mehefin", "Gorffennaf", "Awst", "Medi", "Hydref", "Tachwedd", "Rhagfyr"],
  abbrMonthNames: ["Ion", "Chwe", "Maw", "Ebr", "Mai", "Meh", "Gor", "Aws", "Med", "Hyd", "Tach", "Rhag"],
  yesterday: "ddoe", today: "heddiw", tomorrow: "yfory", on: "ar {date}",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "{time} yn ôl",
  second: "eiliad", seconds: "eiliad", minute: "munud", minutes: "munud", hour: "awr", hours: "awr",
  datetimeAt: "{date} am {time}"
})

defineLocale("da", {
  dayNames: ["søndag", "mandag", "tirsdag", "onsdag", "torsdag", "fredag", "lørdag"],
  abbrDayNames: ["søn", "man", "tir", "ons", "tor", "fre", "lør"],
  monthNames: ["januar", "februar", "marts", "april", "maj", "juni", "juli", "august", "september", "oktober", "november", "december"],
  abbrMonthNames: ["jan", "feb", "mar", "apr", "maj", "jun", "jul", "aug", "sep", "okt", "nov", "dec"],
  yesterday: "i går", today: "i dag", tomorrow: "i morgen", on: "den {date}",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "for {time} siden",
  second: "sekund", seconds: "sekunder", minute: "minut", minutes: "minutter", hour: "time", hours: "timer",
  datetimeAt: "{date} kl. {time}"
})

defineLocale("de", {
  dayNames: ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"],
  abbrDayNames: ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"],
  monthNames: ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"],
  abbrMonthNames: ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"],
  yesterday: "gestern", today: "heute", tomorrow: "morgen", on: "am {date}",
  am: "am", pm: "pm", singular: "eine {time}", singularAn: "eine {time}", elapsed: "vor {time}",
  second: "Sekunde", seconds: "Sekunden", minute: "Minute", minutes: "Minuten", hour: "Stunde", hours: "Stunden",
  datetimeAt: "{date} um {time}"
})

defineLocale("es", {
  dayNames: ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"],
  abbrDayNames: ["dom", "lun", "mar", "mié", "jue", "vie", "sáb"],
  monthNames: ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"],
  abbrMonthNames: ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"],
  yesterday: "ayer", today: "hoy", tomorrow: "mañana", on: "el {date}",
  am: "a. m.", pm: "p. m.", singular: "1 {time}", singularAn: "1 {time}", elapsed: "hace {time}",
  second: "segundo", seconds: "segundos", minute: "minuto", minutes: "minutos", hour: "hora", hours: "horas",
  datetimeAt: "{date} a las {time}"
})

defineLocale("eu", {
  dayNames: ["igandea", "astelehena", "asteartea", "asteazkena", "osteguna", "ostirala", "larunbata"],
  abbrDayNames: ["ig.", "al.", "ar.", "az.", "og.", "or.", "lr."],
  monthNames: ["urtarrilak", "otsailak", "martxoak", "apirilak", "maiatza", "ekainak", "uztailak", "abuztuak", "irailak", "urriak", "azaroak", "abenduak"],
  abbrMonthNames: ["urt.", "ots.", "mar.", "api.", "mai.", "eka.", "uzt.", "abu.", "ira.", "urr.", "aza.", "abe."],
  yesterday: "atzo", today: "gaur", tomorrow: "bihar", on: "{date}",
  am: "am", pm: "pm", singular: "{time} 1", singularAn: "{time} 1", elapsed: "duela {time}",
  second: "segundo", seconds: "segundo", minute: "minutu", minutes: "minutu", hour: "ordu", hours: "ordu",
  datetimeAt: "{date} {time}"
})

defineLocale("fi", {
  dayNames: ["sunnuntai", "maanantai", "tiistai", "keskiviikko", "torstai", "perjantai", "lauantai"],
  abbrDayNames: ["su", "ma", "ti", "ke", "to", "pe", "la"],
  monthNames: ["tammikuu", "helmikuu", "maaliskuu", "huhtikuu", "toukokuu", "kesäkuu", "heinäkuu", "elokuu", "syyskuu", "lokakuu", "marraskuu", "joulukuu"],
  abbrMonthNames: ["tammi", "helmi", "maalis", "huhti", "touko", "kesä", "heinä", "elo", "syys", "loka", "marras", "joulu"],
  yesterday: "eilen", today: "tänään", tomorrow: "huomenna", on: "{date}",
  am: "ap.", pm: "ip.", singular: "1 {time}", singularAn: "1 {time}", elapsed: "{time} sitten",
  second: "sekunti", seconds: "sekuntia", minute: "minuutti", minutes: "minuuttia", hour: "tunti", hours: "tuntia",
  datetimeAt: "{date} klo {time}"
})

defineLocale("fr", {
  dayNames: ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"],
  abbrDayNames: ["dim.", "lun.", "mar.", "mer.", "jeu.", "ven.", "sam."],
  monthNames: ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"],
  abbrMonthNames: ["janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc."],
  yesterday: "hier", today: "aujourd'hui", tomorrow: "demain", on: "le {date}",
  am: "AM", pm: "PM", singular: "1 {time}", singularAn: "1 {time}", elapsed: "il y a {time}",
  second: "seconde", seconds: "secondes", minute: "minute", minutes: "minutes", hour: "heure", hours: "heures",
  datetimeAt: "{date} à {time}"
})

defineLocale("ga", {
  dayNames: ["Dé Domhnaigh", "Dé Luain", "Dé Máirt", "Dé Céadaoin", "Déardaoin", "Dé hAoine", "Dé Sathairn"],
  abbrDayNames: ["Dom", "Luan", "Mái", "Céa", "Déa", "Aoi", "Sat"],
  monthNames: ["Eanáir", "Feabhra", "Márta", "Aibreán", "Bealtaine", "Meitheamh", "Iúil", "Lúnasa", "Meán Fómhair", "Deireadh Fómhair", "Samhain", "Nollaig"],
  abbrMonthNames: ["Ean", "Fea", "Már", "Aib", "Bea", "Mei", "Iúi", "Lún", "MFó", "DFó", "Sam", "Nol"],
  yesterday: "inné", today: "inniu", tomorrow: "amárach", on: "ar {date}",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "{time} ó shin",
  second: "soicind", seconds: "soicind", minute: "nóiméad", minutes: "nóiméad", hour: "uair", hours: "uaire",
  datetimeAt: "{date} ag {time}"
})

defineLocale("hi", {
  dayNames: ["रविवार", "सोमवार", "मंगलवार", "बुधवार", "गुरुवार", "शुक्रवार", "शनिवार"],
  abbrDayNames: ["रवि", "सोम", "मंगल", "बुध", "गुरु", "शुक्र", "शनि"],
  monthNames: ["जनवरी", "फ़रवरी", "मार्च", "अप्रैल", "मई", "जून", "जुलाई", "अगस्त", "सितंबर", "अक्तूबर", "नवंबर", "दिसंबर"],
  abbrMonthNames: ["जन", "फ़र", "मार्च", "अप्रै", "मई", "जून", "जुल", "अग", "सित", "अक्तू", "नव", "दिस"],
  yesterday: "कल", today: "आज", tomorrow: "कल", on: "{date} को",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "{time} पहले",
  second: "सेकंड", seconds: "सेकंड", minute: "मिनट", minutes: "मिनट", hour: "घंटा", hours: "घंटे",
  datetimeAt: "{date} को {time}"
})

defineLocale("hu", {
  dayNames: ["vasárnap", "hétfő", "kedd", "szerda", "csütörtök", "péntek", "szombat"],
  abbrDayNames: ["V", "H", "K", "Sze", "Cs", "P", "Szo"],
  monthNames: ["január", "február", "március", "április", "május", "június", "július", "augusztus", "szeptember", "október", "november", "december"],
  abbrMonthNames: ["jan", "feb", "márc", "ápr", "máj", "jún", "júl", "aug", "szept", "okt", "nov", "dec"],
  yesterday: "tegnap", today: "ma", tomorrow: "holnap", on: "{date}",
  am: "de", pm: "du", singular: "1 {time}", singularAn: "1 {time}", elapsed: "{time} ezelőtt",
  second: "másodperc", seconds: "másodperc", minute: "perc", minutes: "perc", hour: "óra", hours: "óra",
  datetimeAt: "{date} {time}"
})

defineLocale("id", {
  dayNames: ["Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"],
  abbrDayNames: ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"],
  monthNames: ["Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"],
  abbrMonthNames: ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"],
  yesterday: "kemarin", today: "hari ini", tomorrow: "besok", on: "pada {date}",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "{time} yang lalu",
  second: "detik", seconds: "detik", minute: "menit", minutes: "menit", hour: "jam", hours: "jam",
  datetimeAt: "{date} pukul {time}"
})

defineLocale("is", {
  dayNames: ["sunnudagur", "mánudagur", "þriðjudagur", "miðvikudagur", "fimmtudagur", "föstudagur", "laugardagur"],
  abbrDayNames: ["sun", "mán", "þri", "mið", "fim", "fös", "lau"],
  monthNames: ["janúar", "febrúar", "mars", "apríl", "maí", "júní", "júlí", "ágúst", "september", "október", "nóvember", "desember"],
  abbrMonthNames: ["jan", "feb", "mar", "apr", "maí", "jún", "júl", "ágú", "sep", "okt", "nóv", "des"],
  yesterday: "í gær", today: "í dag", tomorrow: "á morgun", on: "{date}",
  am: "f.h.", pm: "e.h.", singular: "1 {time}", singularAn: "1 {time}", elapsed: "fyrir {time} síðan",
  second: "sekúnda", seconds: "sekúndur", minute: "mínúta", minutes: "mínútur", hour: "klukkustund", hours: "klukkustundir",
  datetimeAt: "{date} kl. {time}"
})

defineLocale("it", {
  dayNames: ["domenica", "lunedì", "martedì", "mercoledì", "giovedì", "venerdì", "sabato"],
  abbrDayNames: ["dom", "lun", "mar", "mer", "gio", "ven", "sab"],
  monthNames: ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio", "agosto", "settembre", "ottobre", "novembre", "dicembre"],
  abbrMonthNames: ["gen", "feb", "mar", "apr", "mag", "giu", "lug", "ago", "set", "ott", "nov", "dic"],
  yesterday: "ieri", today: "oggi", tomorrow: "domani", on: "il {date}",
  am: "AM", pm: "PM", singular: "1 {time}", singularAn: "1 {time}", elapsed: "{time} fa",
  second: "secondo", seconds: "secondi", minute: "minuto", minutes: "minuti", hour: "ora", hours: "ore",
  datetimeAt: "{date} alle {time}"
})

defineLocale("ja", {
  dayNames: ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"],
  abbrDayNames: ["日", "月", "火", "水", "木", "金", "土"],
  monthNames: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
  abbrMonthNames: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
  yesterday: "昨日", today: "今日", tomorrow: "明日", on: "{date}",
  am: "午前", pm: "午後", singular: "1{time}", singularAn: "1{time}", elapsed: "{time}前",
  second: "秒", seconds: "秒", minute: "分", minutes: "分", hour: "時間", hours: "時間",
  datetimeAt: "{date} {time}"
})

defineLocale("ko", {
  dayNames: ["일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"],
  abbrDayNames: ["일", "월", "화", "수", "목", "금", "토"],
  monthNames: ["1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월"],
  abbrMonthNames: ["1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월"],
  yesterday: "어제", today: "오늘", tomorrow: "내일", on: "{date}",
  am: "오전", pm: "오후", singular: "1 {time}", singularAn: "1 {time}", elapsed: "{time} 전",
  second: "초", seconds: "초", minute: "분", minutes: "분", hour: "시간", hours: "시간",
  datetimeAt: "{date} {time}"
})

defineLocale("lv", {
  dayNames: ["svētdiena", "pirmdiena", "otrdiena", "trešdiena", "ceturtdiena", "piektdiena", "sestdiena"],
  abbrDayNames: ["Sv", "Pr", "Ot", "Tr", "Ce", "Pk", "Se"],
  monthNames: ["janvāris", "februāris", "marts", "aprīlis", "maijs", "jūnijs", "jūlijs", "augusts", "septembris", "oktobris", "novembris", "decembris"],
  abbrMonthNames: ["janv.", "febr.", "marts", "apr.", "maijs", "jūn.", "jūl.", "aug.", "sept.", "okt.", "nov.", "dec."],
  yesterday: "vakar", today: "šodien", tomorrow: "rīt", on: "{date}",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "pirms {time}",
  second: "sekunde", seconds: "sekundes", minute: "minūte", minutes: "minūtes", hour: "stunda", hours: "stundas",
  datetimeAt: "{date} plkst. {time}"
})

defineLocale("nl", {
  dayNames: ["zondag", "maandag", "dinsdag", "woensdag", "donderdag", "vrijdag", "zaterdag"],
  abbrDayNames: ["zo", "ma", "di", "wo", "do", "vr", "za"],
  monthNames: ["januari", "februari", "maart", "april", "mei", "juni", "juli", "augustus", "september", "oktober", "november", "december"],
  abbrMonthNames: ["jan", "feb", "mrt", "apr", "mei", "jun", "jul", "aug", "sep", "okt", "nov", "dec"],
  yesterday: "gisteren", today: "vandaag", tomorrow: "morgen", on: "op {date}",
  am: "a.m.", pm: "p.m.", singular: "1 {time}", singularAn: "1 {time}", elapsed: "{time} geleden",
  second: "seconde", seconds: "seconden", minute: "minuut", minutes: "minuten", hour: "uur", hours: "uur",
  datetimeAt: "{date} om {time}"
})

defineLocale("no", {
  dayNames: ["søndag", "mandag", "tirsdag", "onsdag", "torsdag", "fredag", "lørdag"],
  abbrDayNames: ["søn", "man", "tir", "ons", "tor", "fre", "lør"],
  monthNames: ["januar", "februar", "mars", "april", "mai", "juni", "juli", "august", "september", "oktober", "november", "desember"],
  abbrMonthNames: ["jan", "feb", "mar", "apr", "mai", "jun", "jul", "aug", "sep", "okt", "nov", "des"],
  yesterday: "i går", today: "i dag", tomorrow: "i morgen", on: "den {date}",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "for {time} siden",
  second: "sekund", seconds: "sekunder", minute: "minutt", minutes: "minutter", hour: "time", hours: "timer",
  datetimeAt: "{date} kl. {time}"
})

defineLocale("pl", {
  dayNames: ["niedziela", "poniedziałek", "wtorek", "środa", "czwartek", "piątek", "sobota"],
  abbrDayNames: ["niedz.", "pon.", "wt.", "śr.", "czw.", "pt.", "sob."],
  monthNames: ["styczeń", "luty", "marzec", "kwiecień", "maj", "czerwiec", "lipiec", "sierpień", "wrzesień", "październik", "listopad", "grudzień"],
  abbrMonthNames: ["sty", "lut", "mar", "kwi", "maj", "cze", "lip", "sie", "wrz", "paź", "lis", "gru"],
  yesterday: "wczoraj", today: "dzisiaj", tomorrow: "jutro", on: "{date}",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "{time} temu",
  second: "sekunda", seconds: "sekundy", minute: "minuta", minutes: "minuty", hour: "godzina", hours: "godziny",
  datetimeAt: "{date} o {time}"
})

defineLocale("pt-BR", {
  dayNames: ["domingo", "segunda-feira", "terça-feira", "quarta-feira", "quinta-feira", "sexta-feira", "sábado"],
  abbrDayNames: ["dom", "seg", "ter", "qua", "qui", "sex", "sáb"],
  monthNames: ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"],
  abbrMonthNames: ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"],
  yesterday: "ontem", today: "hoje", tomorrow: "amanhã", on: "em {date}",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "há {time}",
  second: "segundo", seconds: "segundos", minute: "minuto", minutes: "minutos", hour: "hora", hours: "horas",
  datetimeAt: "{date} às {time}"
})

defineLocale("pt-PT", {
  dayNames: ["domingo", "segunda-feira", "terça-feira", "quarta-feira", "quinta-feira", "sexta-feira", "sábado"],
  abbrDayNames: ["dom", "seg", "ter", "qua", "qui", "sex", "sáb"],
  monthNames: ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"],
  abbrMonthNames: ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"],
  yesterday: "ontem", today: "hoje", tomorrow: "amanhã", on: "em {date}",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "há {time}",
  second: "segundo", seconds: "segundos", minute: "minuto", minutes: "minutos", hour: "hora", hours: "horas",
  datetimeAt: "{date} às {time}"
})

defineLocale("ro", {
  dayNames: ["duminică", "luni", "marți", "miercuri", "joi", "vineri", "sâmbătă"],
  abbrDayNames: ["Dum", "Lun", "Mar", "Mie", "Joi", "Vin", "Sâm"],
  monthNames: ["ianuarie", "februarie", "martie", "aprilie", "mai", "iunie", "iulie", "august", "septembrie", "octombrie", "noiembrie", "decembrie"],
  abbrMonthNames: ["ian", "feb", "mar", "apr", "mai", "iun", "iul", "aug", "sep", "oct", "nov", "dec"],
  yesterday: "ieri", today: "azi", tomorrow: "mâine", on: "la {date}",
  am: "a.m.", pm: "p.m.", singular: "1 {time}", singularAn: "1 {time}", elapsed: "acum {time}",
  second: "secundă", seconds: "secunde", minute: "minut", minutes: "minute", hour: "oră", hours: "ore",
  datetimeAt: "{date} la {time}"
})

defineLocale("ru", {
  dayNames: ["воскресенье", "понедельник", "вторник", "среда", "четверг", "пятница", "суббота"],
  abbrDayNames: ["вс", "пн", "вт", "ср", "чт", "пт", "сб"],
  monthNames: ["январь", "февраль", "март", "апрель", "май", "июнь", "июль", "август", "сентябрь", "октябрь", "ноябрь", "декабрь"],
  abbrMonthNames: ["янв", "фев", "мар", "апр", "май", "июн", "июл", "авг", "сен", "окт", "ноя", "дек"],
  yesterday: "вчера", today: "сегодня", tomorrow: "завтра", on: "{date}",
  am: "AM", pm: "PM", singular: "1 {time}", singularAn: "1 {time}", elapsed: "{time} назад",
  second: "секунда", seconds: "секунды", minute: "минута", minutes: "минуты", hour: "час", hours: "часа",
  datetimeAt: "{date} в {time}"
})

defineLocale("sr", {
  dayNames: ["недеља", "понедељак", "уторак", "среда", "четвртак", "петак", "субота"],
  abbrDayNames: ["нед", "пон", "уто", "сре", "чет", "пет", "суб"],
  monthNames: ["јануар", "фебруар", "март", "април", "мај", "јун", "јул", "август", "септембар", "октобар", "новембар", "децембар"],
  abbrMonthNames: ["јан", "феб", "мар", "апр", "мај", "јун", "јул", "авг", "сеп", "окт", "нов", "дец"],
  yesterday: "јуче", today: "данас", tomorrow: "сутра", on: "{date}",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "пре {time}",
  second: "секунд", seconds: "секунди", minute: "минут", minutes: "минута", hour: "сат", hours: "сати",
  datetimeAt: "{date} у {time}"
})

defineLocale("sk", {
  dayNames: ["nedeľa", "pondelok", "utorok", "streda", "štvrtok", "piatok", "sobota"],
  abbrDayNames: ["ne", "po", "ut", "st", "št", "pi", "so"],
  monthNames: ["január", "február", "marec", "apríl", "máj", "jún", "júl", "august", "september", "október", "november", "december"],
  abbrMonthNames: ["jan", "feb", "mar", "apr", "máj", "jún", "júl", "aug", "sep", "okt", "nov", "dec"],
  yesterday: "včera", today: "dnes", tomorrow: "zajtra", on: "dňa {date}",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "pred {time}",
  second: "sekunda", seconds: "sekundy", minute: "minúta", minutes: "minúty", hour: "hodina", hours: "hodiny",
  datetimeAt: "{date} o {time}"
})

defineLocale("sv", {
  dayNames: ["söndag", "måndag", "tisdag", "onsdag", "torsdag", "fredag", "lördag"],
  abbrDayNames: ["sön", "mån", "tis", "ons", "tor", "fre", "lör"],
  monthNames: ["januari", "februari", "mars", "april", "maj", "juni", "juli", "augusti", "september", "oktober", "november", "december"],
  abbrMonthNames: ["jan", "feb", "mar", "apr", "maj", "jun", "jul", "aug", "sep", "okt", "nov", "dec"],
  yesterday: "i går", today: "i dag", tomorrow: "i morgon", on: "den {date}",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "för {time} sedan",
  second: "sekund", seconds: "sekunder", minute: "minut", minutes: "minuter", hour: "timme", hours: "timmar",
  datetimeAt: "{date} kl. {time}"
})

defineLocale("th", {
  dayNames: ["วันอาทิตย์", "วันจันทร์", "วันอังคาร", "วันพุธ", "วันพฤหัสบดี", "วันศุกร์", "วันเสาร์"],
  abbrDayNames: ["อา.", "จ.", "อ.", "พ.", "พฤ.", "ศ.", "ส."],
  monthNames: ["มกราคม", "กุมภาพันธ์", "มีนาคม", "เมษายน", "พฤษภาคม", "มิถุนายน", "กรกฎาคม", "สิงหาคม", "กันยายน", "ตุลาคม", "พฤศจิกายน", "ธันวาคม"],
  abbrMonthNames: ["ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."],
  yesterday: "เมื่อวาน", today: "วันนี้", tomorrow: "พรุ่งนี้", on: "เมื่อ {date}",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "{time} ที่แล้ว",
  second: "วินาที", seconds: "วินาที", minute: "นาที", minutes: "นาที", hour: "ชั่วโมง", hours: "ชั่วโมง",
  datetimeAt: "{date} เวลา {time}"
})

defineLocale("uk", {
  dayNames: ["неділя", "понеділок", "вівторок", "середа", "четвер", "п'ятниця", "субота"],
  abbrDayNames: ["нд", "пн", "вт", "ср", "чт", "пт", "сб"],
  monthNames: ["січень", "лютий", "березень", "квітень", "травень", "червень", "липень", "серпень", "вересень", "жовтень", "листопад", "грудень"],
  abbrMonthNames: ["січ", "лют", "бер", "квіт", "трав", "черв", "лип", "серп", "вер", "жовт", "лист", "груд"],
  yesterday: "вчора", today: "сьогодні", tomorrow: "завтра", on: "{date}",
  am: "AM", pm: "PM", singular: "1 {time}", singularAn: "1 {time}", elapsed: "{time} тому",
  second: "секунда", seconds: "секунди", minute: "хвилина", minutes: "хвилини", hour: "година", hours: "години",
  datetimeAt: "{date} о {time}"
})

defineLocale("ur", {
  dayNames: ["اتوار", "پیر", "منگل", "بدھ", "جمعرات", "جمعہ", "ہفتہ"],
  abbrDayNames: ["اتوار", "پیر", "منگل", "بدھ", "جمعرات", "جمعہ", "ہفتہ"],
  monthNames: ["جنوری", "فروری", "مارچ", "اپریل", "مئی", "جون", "جولائی", "اگست", "ستمبر", "اکتوبر", "نومبر", "دسمبر"],
  abbrMonthNames: ["جنوری", "فروری", "مارچ", "اپریل", "مئی", "جون", "جولائی", "اگست", "ستمبر", "اکتوبر", "نومبر", "دسمبر"],
  yesterday: "کل", today: "آج", tomorrow: "کل", on: "{date}",
  am: "am", pm: "pm", singular: "1 {time}", singularAn: "1 {time}", elapsed: "{time} پہلے",
  second: "سیکنڈ", seconds: "سیکنڈ", minute: "منٹ", minutes: "منٹ", hour: "گھنٹہ", hours: "گھنٹے",
  datetimeAt: "{date} {time}"
})

defineLocale("zh-CN", {
  dayNames: ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"],
  abbrDayNames: ["周日", "周一", "周二", "周三", "周四", "周五", "周六"],
  monthNames: ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"],
  abbrMonthNames: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
  yesterday: "昨天", today: "今天", tomorrow: "明天", on: "{date}",
  am: "上午", pm: "下午", singular: "1{time}", singularAn: "1{time}", elapsed: "{time}前",
  second: "秒", seconds: "秒", minute: "分钟", minutes: "分钟", hour: "小时", hours: "小时",
  datetimeAt: "{date} {time}"
})

/**
 * Set LocalTime.config.locale from document's lang attribute (e.g. from layout html lang="<%= I18n.locale %>").
 * Call after locales are loaded and before or when LocalTime runs.
 */
export function setLocalTimeLocaleFromDocument() {
  const lang = document.documentElement.getAttribute("lang")
  if (lang && i18n[lang]) {
    LocalTime.config.locale = lang
  }
}
