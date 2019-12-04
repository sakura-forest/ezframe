function join_attr(elem) {
  var attr_s = ""
  for (var i = 0; i < Object.keys(elem).length; i++) {
    var key = Object.keys(elem)[i];
    switch (key) {
      case 'child':
      case 'tag':
      case 'final':
        break;
      default:
        var value = elem[key];
        if (Array.isArray(value)) {
          attr_s += key + "=\"" + value.join(" ") + "\" ";
        } else {
          attr_s += key + "=\"" + value + "\" ";
        }
    }
  }
  var child = elem.child;
  if (child) {
    child = _htmlgen(child);
    return "<" + elem.tag + " " + attr_s + ">" + child + "</" + elem.tag + ">";
  } else {
    return "<" + elem.tag + " " + attr_s + "/>";
  }
}

function select_element(elem) {
  console.log("select_element")
  // console.dir(elem.items)
  outstr = ""
  var items = elem.items
  if (Array.isArray(items)) {
    for (var i = 0; i < items.length; i++) {
      var a = items[i]
      outstr += "<option value=\"" + a[0] + "\">" + a[1] + "</option>"
    }
  } else {
    keys = Object.keys(items)
    for (var i = 0; i < keys.length; i++) {
      var k = keys[i]
      var v = items[k]
      var selected = ""
      console.log("elem.value="+elem.value)
      if (elem.value && k == elem.value) {
        selected=" selected=selected "
      }
      outstr += "<option value=\"" + k + "\" "+selected+">" + v + "</option>"
    }
  }
  //console.log(outstr)
  delete elem.items
  if (!elem.name) {
    elem.name = elem.key
  }
  elem.child = outstr
}

function _htmlgen(elem) {
  if (Array.isArray(elem)) {
    var outstr = "";
    for (var i = 0; i < elem.length; i++) {
      outstr += _htmlgen(elem[i]);
    }
    return outstr;
  } else if ((typeof elem === 'string') || (typeof elem === 'integer')) {
    return elem;
  } else {
    if (elem.tag == "select") {
      select_element(elem)
    }
    return join_attr(elem)
  }
}

function htmlgen(elem) {
  var res = _htmlgen(elem)
  return res
}
