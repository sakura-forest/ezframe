// 2020年05月25日(月) 6
var extra_event_funcs = []
var event_commands = {
  /*
  switch_hide: function(event) {
    console.log("switch")
    var a = event.between
    for(var i = 0; i<a.length; i++) {
      switch_hide(a[i])
    }
  },*/
  set_validation: function(event, form_dom) {
    console.log("set_validation")
    var inputs = collect_all_input_elements(form_dom)
    for(var i = 0; i < inputs.length; i++) {
      var elem = inputs[i]
      var send_with = "input";
      var on = "change"
      var target_key = elem.name
      var ezvalid = elem.getAttribute("ezvalid")
      if (ezvalid) {
        ezvalid = parse_one_event(ezvalid)
        if (ezvalid.with) { send_with = ezvalid.with }
        if (ezvalid.on) { on = ezvalid.on }
        if (ezvalid.target_key) { target_key = ezvalid.target_key }
      }
      var ev_s = "on=" + on + ":branch=single_validate:target_key=" + target_key + ":with=" + send_with + ":url=" + event.validate_url
      console.log("set_validation: ev_s="+ev_s)
      elem.setAttribute("ezevent", ev_s)
      elem.addEventListener(on, function(ev) {
        execute_event(ev.srcElement)
      })
    }
  },
  redirect: function(event) {
    console.log("redirect:" + event.url)
    location.href = event.url
  }
}

// サーバからのレスポンスを処理する関数
var response_funcs = {
  inject: function(res, obj) {
    var elem
    console.log("inject: " + res.inject + ", body=" + res.body)
    if (res.inject == "this") {
      elem = obj
    } else {
      elem = document.querySelector(res.inject)
    }
    if (elem) {
      elem.innerHTML = (res.body || "")
      add_event(elem)
      exec_ezload(elem)
    } else {
      console.log("inject: no such element: " + res.inject)
    }
    // URL表示を指定されたURLに変更する
    if (res.set_url) {
      console.log("set_url: "+res.set_url)
      history.pushState(null, res.set_url[1], res.set_url[0])
      document.title = res.set_url[1]
    }
  },
  set_value: function(res, obj) {
    var elem
    console.log("set_value: " + res.set_value + ", value=", res.value)
    if (res.set_value == "this") {
      elem = obj
    } else {
      elem = document.querySelector(res.set_value)
    }
    if (elem) {
      if (res.set_value.indexOf("select") > 0) {
        elem.selectedIndex = res.value
      } else {
        elem.value = res.value
      }
    } else {
      console.log("set_value: no such element: " + res.set_value)
    }
  },
  reset_error: function(res, obj) {
    console.log("reset_error: " + res.reset_error)
    var elems = document.querySelectorAll(res.reset_error)
    if (elems) {
      for(var i=0; i < elems.length; i++) {
        elem = elems[i]
        elem.innerHTML = ""
        elem.classList.add("hide")
      }
    }
  },
  set_error: function(res, obj) {
    var elem;
    console.log("set_error: " + res.set_error + ", value=", res.value)
    elem = document.querySelector(res.set_error)
    if (elem) {
      elem.innerHTML = res.value
      if (!res.value || res.value.length == 0) {
        elem.classList.add("hide")
      } else {
        elem.classList.remove("hide")
      }
    } else {
      console.log("set_error: no such element: " + res.set_error)
    }
  },
  add_class: function(res, obj) {
    var elem;
    console.log("add_class: " + res.add_class + ", value=", res.value)
    if (res.add_class == "this") {
      elem = obj
    } else {
      elem = document.querySelector(res.add_class)
    }
    if (elem) {
      elem.classList.add(res.value)
    }
  },
  remove_class: function(res, obj) {
    var elem;
    console.log("remove_class: " + res.remove_class + ", value=", res.value)
    if (res.remove_class == "this") {
      elem = obj
    } else {
      elem = document.querySelector(res.remove_class)
    }
    if (elem) {
      elem.classList.remove(res.value)
    }
  }
}

// register events included in a object
function add_event(obj) {
  var elems = obj.querySelectorAll('[ezevent]')
  if (elems) {
    console.log("add_event: events=" + elems.length)
    for (var i = 0; i < elems.length; i++) {
      var elem = elems[i]
      var event_s = elem.getAttribute("ezevent")
      var event_a = parse_event(event_s)
      if (event_a.length > 1) {
        console.log("inculde multi events: "+event_a.length)
        console.dir(event_a)
      }
      for(var j = 0; j < event_a.length; j++) {
        var event = event_a[j]
        if (event.on == "load") {
          if (!elem.event_done) {
            console.log("load: "+event_s)
            execute_event(elem, "ezevent")
            elem.event_done = 1
          }
        } else {
          elem.addEventListener(event.on, function (ev) {
            execute_event(this, "ezevent", ev)
          })
        }
      }
    }
  }
  // execute extra event functions
  for(var i=0; i < extra_event_funcs.length; i++) {
    extra_event_funcs[i](obj)
  }
}

function exec_ezload(obj) {
  var elems = obj.querySelectorAll('[ezload]')
  if (elems) {
    console.log("ezload: events=" + elems.length)
    for (var i = 0; i < elems.length; i++) {
      var elem = elems[i]
      if (!elem.event_done) {
        execute_event(elem, "ezload")
        elem.event_done = 1
      }
    }
  }
}

// parse attrite named event
function parse_event(event) {
  var event_a;
  if (!event) { return [] }
  if (event.indexOf(";;") > -1) {
    event_a = event.split(";;")
  } else {
    event_a = [ event ]
  }
  console.log("parse_event:"+event_a.length) // event_a="+JSON.stringify(event_a))
  // console.dir(event_a)
  var parsed_event_a = []
  for(var i = 0; i < event_a.length; i++) {
    var ev = event_a[i]
    parsed_event_a.push(parse_one_event(ev))
  }
  return parsed_event_a
}

function parse_one_event(event) {
  var ev = {}
  var a = event.split(":")
  for (var i = 0; i < a.length; i++) {
    if (a[i].indexOf("=") > 0) {
      var b = a[i].split("=")
      var key = b[0]
      var value = b[1]
      if (value.indexOf(",") > 0) {
        value = value.split(",")
      }
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
  // console.log("parse_one_event: ") 
  // console.dir(ev)
  return ev
}

function execute_event(obj, attr_key = "ezevent", ev = null) {
  var event_s = obj.getAttribute(attr_key)
  console.log("execute_event: "+attr_key+", event="+event_s+", ev="+JSON.stringify(ev))
  var event_a = parse_event(event_s)
  for(var i = 0; i < event_a.length; i++) {
    var event = event_a[i]
    func = event_commands[event.command]
    if (func) {
      func(event, obj)
    }
    with_attr(event, obj)
    if (event.url) {
      post_values(event, obj)
    }
  }
}

function with_attr(event, obj) {
  switch (event.with) {
    case "form":
      var node = obj
      while (node && node.nodeName != 'FORM') {
        node = node.parentNode
      }
      form = collect_form_values(node)
      event.form = form
      break
    case "input":
      event.form = {}
      event.form[obj.name] = obj.value
      break
    default:
      var node = document.querySelector(event.with)
      form = collect_form_values(node)
      event.form = form
      break
  }
}

// サーバーにJSONをPOST
function post_values(event, obj) {
  var xhr = new XMLHttpRequest()
  xhr.onreadystatechange = function () {
    if (this.readyState == 4 && this.status == 200) {
      var res = this.response
      manage_response(res, event, obj)
    }
  }
  console.log("post_values: url="+event.url+",event="+JSON.stringify(event))
  xhr.open("POST", event.url, true)
  xhr.setRequestHeader("Content-Type", "application/json")
  xhr.responseType = 'json'
  send_values = { ezevent: event }
  xhr.send(JSON.stringify(send_values))
}

// サーバーからの返信を処理
function manage_response(res, event, obj) {
  var elem
  // console.log("manage_response: res="+JSON.stringify(res)+", event=" + JSON.stringify(event) +
  //  ", obj=" + JSON.stringify(obj)) 
  if (!res) { return }
  if (Array.isArray(res)) {
    for(var i = 0; i < res.length; i++) {
      manage_one_response(res[i], obj)
    }
  } else {
    manage_one_response(res, obj)
  }
}

// サーバーからの返信を１件処理
function manage_one_response(res, obj) {
  if (res.redirect) {
    console.log("redirect:" + res.redirect)
    location.href = res.redirect
    return 
  }
  // サーバーからの戻り値のハッシュのキーにresponse_funcsのキーに一致するものがあったら、実行する。
  for (var key in response_funcs) {
    if (res[key]) {
      response_funcs[key](res, obj)
    }
  }
}

// 全ての入力要素を集める
function collect_all_input_elements(obj) {
  var inputs = Array.from(obj.querySelectorAll("input"));
  var selects = Array.from(obj.querySelectorAll("select"));
  var textareas = Array.from(obj.querySelectorAll("textarea"));
  inputs = inputs.concat(selects)
  inputs = inputs.concat(textareas)
  return inputs
}

// 入力フォームの値を集収
function collect_form_values(obj) {
  if (!obj) {return}
  var res = {};
  var inputs = collect_all_input_elements(obj)
  for (var i = 0; i < inputs.length; i++) {
    var elem = inputs[i]
    if (!elem.name) { continue }
    // console.log("name,value="+elem.name+","+elem.value)
    if ((elem.type == "checkbox" || elem.type == "radio") && !elem.checked) {
      continue
    }
    var cur_value = res[elem.name]
    var elem_value = elem.value
    if (cur_value) {
      if (Array.isArray(cur_value)) {
        cur_value.push(elem_value)
      } else {
        res[elem.name] = [ cur_value, elem_value ]
      }
    } else {
      res[elem.name] = elem_value
    }
  }
  return res
}

function switch_hide(button) {
  console.log("switch_hide")
  var node = button
  while (node && !node.classList.contains('switch-box')) {
    node = node.parentNode
  }
  var switch_box = node

  var elems = switch_box.querySelectorAll(".switch-element")
  for(var i = 0; i < elems.length; i++) {
    var elem = elems[i]
    var list = elem.classList
    if (list.contains("hide")) {
      elem.classList.remove("hide")
    } else {
      elem.classList.add("hide")
    }
  }
}

document.addEventListener('DOMContentLoaded', function () {
  add_event(document)
  exec_ezload(document)
  window.addEventListener('popstate', function (e) {
    //if (!e.originalEvent.state) return;
    // changeContents(location.pathname)
    console.log("popstate event:"+location.pathname)
    location.replace(location.href)
  })
})