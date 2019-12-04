document.addEventListener('DOMContentLoaded', function () {
  add_event(document)
  M.AutoInit();
  //initialize_materialize_select()
  var elems = document.querySelectorAll(".submit-button")
  if (elems) {
    for (var i = 0; i < elems.length; i++) {
      elems[i].addEventListener('click', function () {
        var node = this;
        while (node && node.nodeName != "FORM") { node = node.parentNode }
        node.submit();
      })
    }
  }
})

function add_event(obj) {
  var elems = obj.querySelectorAll('[event]')
  if (elems) {
    console.log("events=" + elems.length)
    for (var i = 0; i < elems.length; i++) {
      var elem = elems[i]
      var event_s = elem.getAttribute("event")
      var cmd = parse_event(event_s)
      elem.addEventListener(cmd.on, function(event) {
        execute_command(event, this)
      })
    }
  }
}

function parse_event(event) {
  var res = {}
  var a = event.split(":")
  for (var i = 0; i < a.length; i++) {
    if (a[i].indexOf("=") > 0) {
      var b = a[i].split("=")
      res[b[0]] = b[1]
    }
  }
  if (!res.url) {
    res.url = location.pathname
    console.log("set url: " +res.url)
  }
  return res
}

function access_server(path, send_values, func) {
  console.log("access_server: " + path)
  if (!path) {
    path = location.pathname
  }
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function () {
    if (this.readyState == 4 && this.status == 200) {
      var res = this.response;
      console.log("access_server: res=")
      console.dir(res)
      func(res)
    }
  }
  xhr.open("POST", path, true);
  xhr.setRequestHeader("Content-Type", "application/json");
  xhr.responseType = 'json';
  xhr.send(JSON.stringify(send_values));
}

function execute_command(event, obj) {
  var cmd = parse_event(obj.getAttribute("event"))
  console.log("execute_command: event=" + JSON.stringify(event) + 
    ", cmd=" + JSON.stringify(cmd))
  //console.dir(obj)
  switch (cmd.cmd) {
    case "open":
      open_page(cmd, obj)
      break
    case "inject":
      inject(cmd, obj)
      break
    case "update_value":
      console.log("update_value")
      update_value(cmd, obj)
      break
    case "reset_value":
      reset_value(cmd, obj)
      break
    default:
      console.log("unknown command: " + command)
  }
}

function open_page(cmd, obj) {
  var win = window.open(cmd.url)
}

function inject(cmd, obj) {
  var url = cmd.url // obj.getAttribute("url")
  console.log("inject: url=" + url)
  access_server(url, cmd, function (res) {
    var selector = cmd.into  //obj.getAttribute("into")
    console.log("inject: into=" + selector)
    var elem = document.querySelector(selector)
    if (elem) {
      elem.innerHTML = htmlgen(res)
      add_event(elem)
      initialize_materialize_select()
    } else {
      console.log("no such element: " + selector)
    }
  })
}

function initialize_materialize_select() {
  var elems = document.querySelectorAll('select');
  if (elems) {
    for (var i = 0; i < elems.length; i++) {
      M.FormSelect.init(elems[i], {});
    }
  }
  elems = document.querySelectorAll('.tabs');
  if (elems) {
    for (var i = 0; i < elems.length; i++) {
      M.Tabs.init(elems[i], { onShow: show_tab_contents })
    }
  }
}

function show_tab_contents(obj) {
  console.log("show_tab_contents: "+obj.id)
  console.dir(obj)
  var id = obj.id
  url ="/"+id
  //obj.removeEventListner("show", show_tab_contents)
  access_server(url, {}, function(obj) {
    var elem = document.querySelector("#"+id);
    elem.innerHTML = htmlgen(obj)
  })
}

function update_value(cmd, obj) {
  var url = cmd.url
  var input = obj.parentNode.querySelector("select")
  if (!input) {
    input = obj.parentNode.querySelector("input")
  } 
  if (!input) {
    console.log("no input element")
  }
  //console.log("update_value: url="+url+", input.value")
  //console.dir(input)
  cmd.update_value = input.value
  access_server(url, cmd, function(res) {
    var selector = cmd.into
    var elem = document.querySelector(selector)
    if (elem) {
      elem.innerHTML = htmlgen(res)
      add_event(elem)
    } else {
      console.log("no such element: " + selector)
    }
  })
}

function reset_value(cmd, obj) {
  access_server(cmd.url, cmd, function(res) {
    var elem = document.querySelector(cmd.into)
    if (elem) {
      elem.innerHTML = htmlgen(res)
      add_event(elem)
    } else {
      console.log("no such element: " + selector)
    }
  })
}

function collect_form_values(obj) {
  var inputs = obj.querySelectorAll("form input");
  var res = {};
  for (var i = 0; i < inputs.length; i++) {
    var elem = inputs[i]
    res[elem.key] = elem.value
  }
  var selects = obj.querySelectorAll("form select");
  for (var i = 0; i < selects.length; i++) {
    var elem = selects[i]
    res[elem.key] = elem.value
  }
  return res
}
