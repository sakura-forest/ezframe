function add_event(obj) {
  var elems = obj.querySelectorAll('[event]')
  if (elems) {
    console.log("events=" + elems.length)
    for (var i = 0; i < elems.length; i++) {
      var elem = elems[i]
      var event_s = elem.getAttribute("event")
      // console.log(event_s)
      var event = parse_event(event_s)
      if (event.on == "load" && !elem.event_done) {
        console.log("load: "+event_s)
        execute_event(elem)
        elem.event_done = 1
      } else {
        elem.addEventListener(event.on, function () {
          execute_event(this)
        })
      }
    }
  }
  register_switch_event(obj)
  register_hover_button(obj)
  initialize_materialize()
  var elems = document.querySelectorAll('.dropdown-trigger')
  var instances = M.Dropdown.init(elems, {})
}

function parse_event(event) {
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
  /*if (!ev.url) {
    ev.url = location.pathname
  }*/
  return ev
}

function execute_event(obj) {
  console.log("execute_event")
  // console.dir(obj)
  var event_s = obj.getAttribute("event")
  var event = parse_event(event_s)
  switch(event.command) {
    case "switch":
      var a = event.between
      for(var i = 0; i < a.length; i++) {
        switch_hide(a[i])
      }
      return
    case "set_global":
      if (!window.ezframe) { window.ezframe = {} }
      for(key in event) {
        if ([ "command", "branch", "on", "url" ].indexOf(key) >= 0) { continue }
        window.ezframe[key] = event[key]
      }
      // console.log("set_global:" + JSON.stringify(window.ezframe))
      return
    case "redirect":
      console.log("redirect:" + event.url)
      location.href = event.url
      return
    case "enable_datatable":
      enable_datatable(event)
      return
  }
  with_attr(event, obj)
  post_values(event, obj)
}

function enable_datatable(event) {
  // $("#enable_datatable").DataTable();
  console.log("enable_datatable: target="+event.target)
  // console.log($(tevent.arget))
  var list_size = event.size || 5
  $(event.target).DataTable({
    lengthChange: false,
    displayLength: parseInt(list_size),
    columnDefs: [{ targets: '_all', className: 'ellipsis' }],
    language: {
      "decimal": ".",
      "thousands": ",",
      "sProcessing": "処理中...",
      "sLengthMenu": "_MENU_ 件表示",
      "sZeroRecords": "データはありません。",
      "sInfo": " _TOTAL_ 件中 _START_ から _END_ まで表示",
      "sInfoEmpty": " 0 件中 0 から 0 まで表示",
      "sInfoFiltered": "（全 _MAX_ 件より抽出）",
      "sInfoPostFix": "",
      "sSearch": "検索:",
      "sUrl": "",
      "oPaginate": {
        "sFirst": "<< 先頭",
        "sPrevious": "< 前",
        "sNext": "次 > ",
        "sLast": "最終 >>"
      }
    }
  })
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
  send_values = { event: event }
  if (window.ezframe) {
    send_values.global = window.ezframe
  }
  xhr.send(JSON.stringify(send_values))
}

function manage_response(res, event, obj) {
  var elem
  console.log("manage_response: res="+JSON.stringify(res)+", event=" + JSON.stringify(event) +
    ", obj=" + JSON.stringify(obj)) 
  if (!res) { return }
  if (Array.isArray(res)) {
    for(var i = 0; i < res.length; i++) {
      exec_one_response(res[i])
    }
  } else {
    exec_one_response(res)
  }
}

function exec_one_response(res) {
  if (res.inject) {
    console.log("inject: " + res.inject)
    elem = document.querySelector(res.inject)
    if (elem) {
      elem.innerHTML = res.body.replace(/<br>/g, "\n")
      add_event(elem)
    } else {
      console.log("no such element: "+res.inject)
    }
  }
  if (res.redirect) {
    console.log("redirect:" + res.redirect)
    location.href = res.redirect
    return
  }
  if (res.reset) {
    elem = document.querySelector(res.reset)
    if (event.reset == "form") {
      while (node && node.nodeName != 'FORM') {
        node = node.parentNode
      }
      node.reset();
    }
  }
}

function collect_form_values(obj) {
  var res = {};
  var inputs = Array.from(obj.querySelectorAll("input"));
  var selects = Array.from(obj.querySelectorAll("select"));
  var textareas = Array.from(obj.querySelectorAll("textarea"));
  // console.dir(inputs)
  inputs = inputs.concat(selects)
  inputs = inputs.concat(textareas)
  for (var i = 0; i < inputs.length; i++) {
    var elem = inputs[i]
    if (!elem.name) { continue }
    // console.log("name,value="+elem.name+","+elem.value)
    if ((elem.type == "checkbox" || elem.type == "radio") && !elem.checked) {
      continue
    }
    var cur_value = res[elem.name]
    var elem_value = elem.value
    elem_value = elem_value.replace(/\n/g, '<br>')
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

function register_switch_event(elem) {
  var boxes = elem.querySelectorAll(".switch-box")
  for(var i = 0; i < boxes.length; i++) {
    var box = boxes[i]
    var buttons = box.querySelectorAll(".switch-button")
    for(var j = 0; j < buttons.length; j++) {
      var button = buttons[j]
      button.addEventListener('click', function() { switch_hide(this) })
    }
  }
}

function register_hover_button(obj) {
  var elems = obj.querySelectorAll(".hover-button")
  for(var i = 0; i < elems.length; i++) {
    var node = elems[i]
    while(node && !node.classList.contains("hover-button-box") ) { node = node.parentNode  }
    //var parent = elems[i].parentNode.parentNode
    node.addEventListener('mouseenter', function() {
      console.log("show button")
      var btns = this.querySelectorAll(".hover-button")
      for (var j = 0; j < btns.length; j++) {
        btns[j].classList.remove("hide")
      }
    })
    node.addEventListener('mouseleave', function() { 
      console.log("hide button")
      var btns = this.querySelectorAll(".hover-button")
      for (var j = 0; j < btns.length; j++) {
        btns[j].classList.add("hide") 
      }
    })
  }
}

/*
document.addEventListener('DOMContentLoaded', function () {
  add_event(document)
})
*/
$(document).ready(function () {
  add_event(document)
})