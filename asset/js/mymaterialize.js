function initialize_materialize() {
  M.AutoInit()
  var elems = document.querySelectorAll('.tabs');
  if (elems) {
    for (var i = 0; i < elems.length; i++) {
      M.Tabs.init(elems[i], {})
    }
  }
  elems = document.querySelectorAll('.datepicker');
  if (elems) {
    var instances = M.Datepicker.init(elems, { 
      format: "yyyy-mm-dd",
      firstDay: 0,
      //defaultDate: new Date(), 
      showMonthAfterYear: true,
      setDefaultDate: true,
      i18n: {
        months: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
        monthsShort: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
        weekdays: ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'],
        weekdaysShort: ['月', '火', '水', '木', '金', '土', '日'],
        weekdaysAbbrev: ['月', '火', '水', '木', '金', '土', '日']
      }
    });
  }
}

function show_tab_contents(obj) {
  console.log("show_tab_contents: " + JSON.stringify(obj.getAttribute("event")))
  var event = parse_event(obj.getAttribute("event"))
  var id = obj.id
  url ="/admin/"+id
  access_server(event.url, event, function(res) {
    var elem = document.querySelector("#"+id);
    elem.innerHTML = htmlgen(res)
    add_event(elem)
  })
}