document.addEventListener('DOMContentLoaded', function () {
  var elems = document.querySelectorAll('[event]')
  if (elems) {
    //console.log("events="+elems.length)
    for (var i = 0; i < elems.length; i++) {
      var elem = elems[i]
      elem.addEventListener('click', function (event) {
        execute_command(event, this)
      });
    }
  }

  initialize_materialize_select()
  var elems = document.querySelectorAll(".submit-button")
  if (elems) {
    for (var i = 0; i < elems.length; i++) {
      elems[i].addEventListener('click', function () {
        var node = this;
        while (node && node.nodeName != "FORM") { node = node.parentNode }
        node.submit();
      });
    }
  };
});

function add_event(obj) {
  var elems = obj.querySelectorAll('[event]')
  if (elems) {
    console.log("events=" + elems.length)
    for (var i = 0; i < elems.length; i++) {
      var elem = elems[i]
      var event = elem.getAttribute("event")
      elem.addEventListener(event, function (event) {
        execute_command(event, this)
      })
    }
  }
}

function access_server(path, send_values, func) {
  console.log("access_server: " + path)
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function () {
    if (this.readyState == 4 && this.status == 200) {
      var res = this.response;
      console.log("access_server: res=")
      console.dir(res)
      if (func) {
        func(res)
      } else {
        execute_response(res)
      }
    }
  }
  xhr.open("POST", path, true);
  xhr.setRequestHeader("Content-Type", "application/json");
  xhr.responseType = 'json';
  xhr.send(JSON.stringify(send_values));
}

function execute_response(obj) {
  console.log("execute_response: ")
  console.dir(obj)
  var event = obj.event
  if (event) {
    var elem = document.querySelector(obj.on)
    if (elem) {
      elem.addEventListner(event, function (event) {
        execute_command(event, this)
      })
    } else {
      console.log("[warn] no element to add listener: " + obj.on)
    }
  } else {
    if (obj.tag) {
      htmlgen(obj)
    }
    execute_command(event, obj)
  }
}

function execute_command(event, obj) {
  var command = obj.getAttribute("command")
  //console.log("execute_command: "+command)
  switch (command) {
    case "open":
      open_page(obj)
      break
    case "inject":
      inject(obj)
      break
    case "update_value":
      console.log("update_value")
      update_value(obj)
      break
    case "reset_value":
      reset_value(obj)
      break
    default:
      console.log("unknown command: "+command)
  }
}

function open_page(obj) {
  var url = obj.getAttribute("url")
  window.open(url)
}

function inject(obj) {
  var url = obj.getAttribute("url")
  console.log("inject: url=" + url)
  access_server(url, obj, function (res) {
    var selector = obj.getAttribute("into")
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
      M.Tabs.init(elems[i], { onShow: function(obj) { show_tab_contents(obj) }})
    }
  }
}

function show_tab_contents(obj) {
  console.log("show_tab_contents: "+obj.id)
  var id = obj.id
  url ="/"+id
  access_server(url, {}, function(obj) {
    var elem = document.querySelector("#"+id);
    elem.innerHTML = htmlgen(obj)
  })
}

function update_value(obj) {
  var url = obj.getAttribute("url")
  var input = obj.parentNode.querySelector("select")
  if (!input) {
    input = obj.parentNode.querySelector("input")
  } 
  if (!input) {
    console.log("no input element")
  }
  url += "&update_value="+input.value
  console.log("update_value: url="+url+", input.value")
  console.dir(input)
  access_server(url, { new_value: input.value }, function(res) {
    var selector = obj.getAttribute("into")
    var elem = document.querySelector(selector)
    if (elem) {
      elem.innerHTML = htmlgen(res)
      add_event(elem)
    } else {
      console.log("no such element: " + selector)
    }
  })
}

function reset_value(obj) {
  access_server(obj.getAttribute("url"), {}, function(res) {
    var selector = obj.getAttribute("into")
    var elem = document.querySelector(selector)
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
