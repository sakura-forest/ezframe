function add_event(obj) {
  var elems = obj.querySelectorAll('[event]')
  if (elems) {
    console.log("events=" + elems.length)
    for (var i = 0; i < elems.length; i++) {
      var elem = elems[i]
      var event_s = elem.getAttribute("event")
      var event = parse_event(event_s)
      // console.log(JSON.stringify(event))
      elem.addEventListener(event.on, function () {
        execute_event(this)
      })
    }
  }
  M.AutoInit();
  initialize_materialize_tabs()
  // init_datatable(document.querySelector("#main-table table"))
}

function parse_event(event) {
  var ev = {}
  var a = event.split(":")
  for (var i = 0; i < a.length; i++) {
    if (a[i].indexOf("=") > 0) {
      var b = a[i].split("=")
      var key = b[0]
      var value = b[1]
      var cur_value = ev[key]
      if (cur_value) {
        if (Array.isArray(cur_value)) {
          cur_value.push(value)
        } else {
          ev[key] = [ev[key], value]
        }
      } else {
        ev[key] = value
      }
    }
  }
  if (!ev.url) {
    ev.url = location.pathname
  }
  return ev
}

function execute_event(obj) {
  var event_s = obj.getAttribute("event")
  var event = parse_event(event_s)
  with_attr(event, obj)
  post_values(event, obj)
}

function with_attr(event, obj) {
  if (!event.with) {
    return null
  }
  var with_s = event.with
  if (event.with == "form") {
    var node = obj
    while (node && node.nodeName != 'FORM') {
      node = node.parentNode
    }
    form = collect_form_values(node)
    event.form = form
  }
}

function post_values(event, obj) {
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function () {
    if (this.readyState == 4 && this.status == 200) {
      var res = this.response;
      manage_response(res, event, obj)
    }
  }
  xhr.open("POST", event.url, true);
  xhr.setRequestHeader("Content-Type", "application/json");
  xhr.responseType = 'json';
  xhr.send(JSON.stringify({ event: event }));
}

function manage_response(res, event, obj) {
  var elem;
  console.log("manage_response: res="+JSON.stringify(res)+", event=" + JSON.stringify(event) +
    ", obj=" + JSON.stringify(obj))
  if (res.inject) {
    console.log("inject")
    elem = document.querySelector(res.inject)
    elem.innerHTML = htmlgen(res.body)
    document
    add_event(elem)
  }
  if (res.reset) {
    elem = document.querySelector(res.reset)
    if (event.reset=="form") {
      while (node && node.nodeName != 'FORM') {
        node = node.parentNode
      }
      node.reset();
    } else {
      var elems = document.querySelectorAll(event.reset)
      if (elems) {
        for(var i = 0; i < elems.length; i++) {
          elem = elems[i]
        }

      }
    }
  }
}

function collect_form_values(obj) {
  var res = {};
  var inputs = Array.from(obj.querySelectorAll("input"));
  var selects = Array.from(obj.querySelectorAll("select"));
  console.dir(inputs)
  inputs = inputs.concat(selects)
  for (var i = 0; i < inputs.length; i++) {
    var elem = inputs[i]
    if ((elem.type == "checkbox" || elem.type == "radio") && !elem.checked) {
      continue
    }
    var cur_value = res[elem.name]
    if (cur_value) {
      if (Array.isArray(cur_value)) {
        cur_value.push(elem.value)
      } else {
        res[elem.name] = [ cur_value, elem.value ]
      }
    } else {
      res[elem.name] = elem.value
    }
  }
  return res
}
