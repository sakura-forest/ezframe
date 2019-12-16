function initialize_materialize_tabs() {
  
  elems = document.querySelectorAll('.tabs');
  if (elems) {
    for (var i = 0; i < elems.length; i++) {
      M.Tabs.init(elems[i], { onShow: show_tab_contents })
    }
  }
}

function show_tab_contents(obj) {
  console.log("show_tab_contents: " + JSON.stringify(obj.getAttribute("event")))
  var event = parse_event(obj.getAttribute("event"))
  //console.dir(obj)
  var id = obj.id
  url ="/admin/"+id
  access_server(event.url, event, function(res) {
    var elem = document.querySelector("#"+id);
    elem.innerHTML = htmlgen(res)
    add_event(elem)
  })
}