document.addEventListener('DOMContentLoaded', function () {
  add_event(document)
  //initialize_materialize_select()
  /*
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
  */
})

function add_event(obj) {
  var elems = obj.querySelectorAll('[event]')
  if (elems) {
    console.log("events=" + elems.length)
    for (var i = 0; i < elems.length; i++) {
      var elem = elems[i]
      var event_s = elem.getAttribute("event")
      var event = parse_event(event_s)
      console.log(JSON.stringify(event))
      elem.addEventListener(cmd.on, function(ev) {
        execute_command(ev, this)
      })
    }
  }
  M.AutoInit();
  // initialize_materialize_tabs()
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
  //console.log("current url: " + res.url)
  if (!res.url) {
    res.url = location.pathname
    //console.log("set url: " + res.url)
  }
  // console.log("parse_event: "+JSON.stringify(res))
  return res
}

/*
function access_server(path, send_values, func) {
  console.log("access_server: " + path)
  if (!path) {
    path = location.pathname
  }
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function () {
    if (this.readyState == 4 && this.status == 200) {
      var res = this.response;
      console.log("access_server: res="+JSON.stringify(res))
      func(res)
    }
  }
  xhr.open("POST", path, true);
  xhr.setRequestHeader("Content-Type", "application/json");
  xhr.responseType = 'json';
  xhr.send(JSON.stringify(send_values));
}
*/

function execute_command(ev, obj) {
  var event = parse_event(obj.getAttribute("event"))
  console.log("execute_command: event=" + JSON.stringify(ev) + 
    ", event=" + JSON.stringify(event))
  //console.dir(obj)
  if (event.branch) {
    console.log("[obsolete] event.branch is obsolete")
    return
  }
  if (event.cmd) {
    console.log("[obsolete] event.cmd is obsolete")
    return
  }
  return
  /*
  switch (event.branch) {
    case "open":
    case "inject":
      inject(event, obj)
      break
    case "update_value":
      console.log("update_value")
      update_value(event, obj)
      break
    case "reset_value":
      reset_value(event)
      break
    default:
      console.log("unknown command: " + command)
  }
  */
}

/*
function inject(event, obj) {
  var url = event.url // obj.getAttribute("url")
  console.log("inject: url=" + url)
  if (event.get_form) {
    var node = obj
    // console.dir(node)
    while(node && node.nodeName !='FORM') { 
      node = node.parentNode 
      // console.log(node.nodeName)
    }
    form = collect_form_values(node)
    cmd.form = form
  }
  access_server(url, cmd, function (res) {
    switch(cmd.cmd) {
      case "inject":
        var selector = cmd.into
        console.log("inject: into=" + selector)
        var elem = document.querySelector(selector)
        if (elem) {
          elem.innerHTML = htmlgen(res)
          add_event(elem)
        } else {
          console.log("no such element: " + selector)
        }
        break
      case "open":
        console.log("open: "+JSON.stringify(cmd))
        location.href = cmd.goto
    }
  })
}

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
*/

function collect_form_values(obj) {
  // console.log("collect_form_values")
  var res = {};
  var inputs = obj.querySelectorAll("input");
  for (var i = 0; i < inputs.length; i++) {
    var elem = inputs[i]
    // console.dir(elem)
    res[elem.name] = elem.value
  }
  var selects = obj.querySelectorAll("select");
  for (var i = 0; i < selects.length; i++) {
    var elem = selects[i]
    // console.dir(elem)
    res[elem.name] = elem.value
  }
  return res
}
