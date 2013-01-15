window.matchMedia = window.matchMedia || (function(e, f) {
    var c, a = e.documentElement, b = a.firstElementChild || a.firstChild, d = e.createElement("body"), g = e.createElement("div");
    g.id = "mq-test-1";
    g.style.cssText = "position:absolute;top:-100em";
    d.style.background = "none";
    d.appendChild(g);
    return function(h) {
        g.innerHTML = '&shy;<style media="' + h + '"> #mq-test-1 { width:42px; }</style>';
        a.insertBefore(d, b);
        c = g.offsetWidth === 42;
        a.removeChild(d);
        return {matches: c,media: h}
    }
}(document));
(function() {
    var b = 0;
    var c = ["ms", "moz", "webkit", "o"];
    for (var a = 0; a < c.length && !window.requestAnimationFrame; ++a) {
        window.requestAnimationFrame = window[c[a] + "RequestAnimationFrame"];
        window.cancelAnimationFrame = window[c[a] + "CancelAnimationFrame"] || window[c[a] + "CancelRequestAnimationFrame"]
    }
    if (!window.requestAnimationFrame) {
        window.requestAnimationFrame = function(h, e) {
            var d = new Date().getTime();
            var f = Math.max(0, 16 - (d - b));
            var g = window.setTimeout(function() {
                h(d + f)
            }, f);
            b = d + f;
            return g
        }
    }
    if (!window.cancelAnimationFrame) {
        window.cancelAnimationFrame = function(d) {
            clearTimeout(d)
        }
    }
}());
if (!Function.prototype.bind) {
    Function.prototype.bind = function bind() {
        if (arguments.length < 2 && typeof (arguments[0]) == undefined) {
            return this
        }
        var a = this, c = AC.Array.toArray(arguments), b = c.shift();
        return function() {
            return a.apply(b, c.concat(AC.Array.toArray(arguments)))
        }
    }
}
if (!Array.isArray) {
    Array.isArray = function isArray(a) {
        return (a && typeof a === "object" && "splice" in a && "join" in a)
    }
}
if (!Array.prototype.forEach) {
    Array.prototype.forEach = function forEach(f, e) {
        var d = Object(this), a = this.length, b = 0, c;
        if (typeof f !== "function") {
            throw "No function object passed to forEach."
        }
        for (b = 0; b < a; b++) {
            c = d[b];
            f.call(e, c, b, d)
        }
    }
}
if (!Array.prototype.indexOf) {
    Array.prototype.indexOf = function(b, c) {
        var d = c || 0;
        var a = 0;
        if (d < 0) {
            d = this.length + c - 1;
            if (d < 0) {
                throw "Wrapped past beginning of array while looking up a negative start index."
            }
        }
        for (a = 0; a < this.length; a++) {
            if (this[a] === b) {
                return a
            }
        }
        return (-1)
    }
}
if (!String.prototype.trim) {
    String.prototype.trim = function trim() {
        return this.replace(/^\s+|\s+$/g, "")
    }
}
if (!Object.keys) {
    Object.keys = function keys(b) {
        var a = [], c;
        if ((!b) || (typeof b.hasOwnProperty !== "function")) {
            throw "Object.keys called on non-object."
        }
        for (c in b) {
            if (b.hasOwnProperty(c)) {
                a.push(c)
            }
        }
        return a
    }
}
if (!Object.create) {
    Object.create = function(b) {
        if (arguments.length > 1) {
            throw new Error("Object.create implementation only accepts the first parameter.")
        }
        function a() {
        }
        a.prototype = b;
        return new a()
    }
}
var AC = window.AC || {};
AC.Array = AC.Array || {};
AC.Array.toArray = function(a) {
    return Array.prototype.slice.call(a)
};
AC.Array.flatten = function(c) {
    var a = [];
    var b = function(d) {
        if (Array.isArray(d)) {
            d.forEach(b)
        } else {
            a.push(d)
        }
    };
    c.forEach(b);
    return a
};
var AC = window.AC || {};
AC.Element = AC.Element || {};
AC.Element.addEventListener = function(d, a, c) {
    if (d.addEventListener) {
        d.addEventListener(a, c, false)
    } else {
        if (d.attachEvent) {
            var b = d.attachEvent("on" + a, c)
        } else {
            d["on" + a] = c
        }
    }
    return d
};
AC.Element.removeEventListener = function(c, a, b) {
    if (c.removeEventListener) {
        c.removeEventListener(a, b, false)
    } else {
        c.detachEvent("on" + a, b)
    }
    return c
};
AC.Element.getElementById = function(a) {
    if (AC.String.isString(a)) {
        return document.getElementById(a)
    } else {
        return a
    }
};
AC.Element.selectAll = function(a, b) {
    if (typeof b === "undefined") {
        b = document.body
    } else {
        if (!AC.Element.isElement(b)) {
            throw "AC.Element.querySelectorAll: Context is not an Element"
        }
    }
    if (typeof a === "string") {
        return Sizzle(a, b)
    } else {
        throw "AC.Element.selectAll: Selector must be a string"
    }
};
AC.Element.select = function(a, b) {
    if (typeof b === "undefined") {
        b = document.body
    } else {
        if (!AC.Element.isElement(b)) {
            throw "AC.Element.querySelector: Context is not an Element"
        }
    }
    if (typeof a === "string") {
        if (Element.prototype.hasOwnProperty("querySelector")) {
            return b.querySelector(a)
        } else {
            return Sizzle(a, b)[0]
        }
    } else {
        throw "AC.Element.select: Selector must be a string"
    }
};
AC.Element.setOpacity = function(a, b) {
    a = AC.Element.getElementById(a);
    a.style.opacity = (b === 1 || b === "") ? "" : (b < 0.00001) ? 0 : b;
    var d;
    if (b === 1) {
        if (a.tagName.toLowerCase() === "img" && a.width) {
            a.width += 1;
            a.width -= 1
        } else {
            try {
                d = document.createTextNode(" ");
                a.appendChild(d);
                a.removeChild(d)
            } catch (c) {
            }
        }
    }
    return a
};
AC.Element.setStyle = function(a, b) {
    a = AC.Element.getElementById(a);
    var d = a.style;
    var c;
    if (typeof b === "string") {
        a.style.cssText += ";" + b;
        return (b.indexOf("opacity") > -1) ? AC.Element.setOpacity(a, b.match(/opacity:\s*(\d?\.?\d*)/)[1]) : a
    } else {
        throw "Style argument must be a CSS style string"
    }
};
AC.Element.getStyle = function(b, c) {
    b = AC.Element.getElementById(b);
    c = c === "float" ? "cssFloat" : c;
    var d = b.style[c];
    if (!d || d === "auto") {
        var a = document.defaultView.getComputedStyle(b, null);
        d = a ? a[c] : null
    }
    if (c === "opacity") {
        return d ? parseFloat(d) : 1
    }
    return d === "auto" ? null : d
};
AC.Element.cumulativeOffset = function(a) {
    var b = [0, 0];
    if (a.parentNode) {
        do {
            b[0] += a.offsetTop || 0;
            b[1] += a.offsetLeft || 0;
            a = a.offsetParent
        } while (a)
    }
    b.top = b[0];
    b.left = b[1];
    return b
};
AC.Element.hasClassName = function(c, b) {
    var a = AC.Element.getElementById(c);
    if (a && a.className) {
        return ((a) && (a.className) && (a.className.match(new RegExp("(\\s|^)" + b + "(\\s|$)")))) || false
    }
};
AC.Element.addClassName = function(c, b) {
    var a = AC.Element.getElementById(c);
    if (!AC.Element.hasClassName(a, b)) {
        a.className += " " + b
    }
};
AC.Element.removeClassName = function(c, b) {
    var a = AC.Element.getElementById(c);
    if (AC.Element.hasClassName(a, b)) {
        var d = new RegExp("(\\s|^)" + b + "(\\s|$)");
        a.className = a.className.replace(d, "")
    }
};
AC.Element.isElement = function(a) {
    return !!(a && a.nodeType === 1)
};
AC.Element.addVendorEventListener = function(b, c, d, a) {
    if (c.match(/^webkit/i)) {
        c = c.replace(/^webkit/i, "")
    } else {
        if (c.match(/^moz/i)) {
            c = c.replace(/^moz/i, "")
        } else {
            if (c.match(/^ms/i)) {
                c = c.replace(/^ms/i, "")
            } else {
                if (c.match(/^o/i)) {
                    c = c.replace(/^o/i, "")
                } else {
                    c = c.charAt(0).toUpperCase() + c.slice(1)
                }
            }
        }
    }
    if (/WebKit/i.test(window.navigator.userAgent)) {
        AC.Element.addEventListener(b, "webkit" + c, d, a)
    } else {
        if (/Opera/i.test(window.navigator.userAgent)) {
            AC.Element.addEventListener(b, "O" + c, d, a)
        } else {
            if (/Gecko/i.test(window.navigator.userAgent)) {
                AC.Element.addEventListener(b, c.toLowerCase(), d, a)
            } else {
                c = c.charAt(0).toLowerCase() + c.slice(1);
                return AC.Element.addEventListener(b, c, d, a)
            }
        }
    }
};
AC.Element.removeVendorEventListener = function(b, c, d, a) {
    if (c.match(/^webkit/i)) {
        c = c.replace(/^webkit/i, "")
    } else {
        if (c.match(/^moz/i)) {
            c = c.replace(/^moz/i, "")
        } else {
            if (c.match(/^ms/i)) {
                c = c.replace(/^ms/i, "")
            } else {
                if (c.match(/^o/i)) {
                    c = c.replace(/^o/i, "")
                } else {
                    c = c.charAt(0).toUpperCase() + c.slice(1)
                }
            }
        }
    }
    AC.Element.removeEventListener(b, "webkit" + c, d, a);
    AC.Element.removeEventListener(b, "O" + c, d, a);
    AC.Element.removeEventListener(b, c.toLowerCase(), d, a);
    c = c.charAt(0).toLowerCase() + c.slice(1);
    return AC.Element.removeEventListener(b, c, d, a)
};
AC.Element.setVendorPrefixStyle = function(c, f, e) {
    var b;
    var a;
    var d;
    if (f.match(/^webkit/i)) {
        f = f.replace(/^webkit/i, "")
    } else {
        if (f.match(/^moz/i)) {
            f = f.replace(/^moz/i, "")
        } else {
            if (f.match(/^ms/i)) {
                f = f.replace(/^ms/i, "")
            } else {
                if (f.match(/^o/i)) {
                    f = f.replace(/^o/i, "")
                } else {
                    if (f.match("-")) {
                        a = f.split("-");
                        d = a.length;
                        f = "";
                        for (b = 0; b < a.length; b += 1) {
                            f += a[b].charAt(0).toUpperCase() + a[b].slice(1)
                        }
                    } else {
                        f = f.charAt(0).toUpperCase() + f.slice(1)
                    }
                }
            }
        }
    }
    if (e.match("-webkit-")) {
        e = e.replace("-webkit-", "-vendor-")
    } else {
        if (e.match("-moz-")) {
            e = e.replace("-moz-", "-vendor-")
        } else {
            if (e.match("-ms-")) {
                e = e.replace("-ms-", "-vendor-")
            } else {
                if (e.match("-o-")) {
                    e = e.replace("-o-", "-vendor-")
                }
            }
        }
    }
    c.style["webkit" + f] = e.replace("-vendor-", "-webkit-");
    c.style["Moz" + f] = e.replace("-vendor-", "-moz-");
    c.style["ms" + f] = e.replace("-vendor-", "-ms-");
    c.style["O" + f] = e.replace("-vendor-", "-o-");
    e = e.replace("-vendor-", "");
    c.style[f] = e;
    f = f.charAt(0).toLowerCase() + f.slice(1);
    c.style[f] = e
};
var AC = window.AC || {};
AC.Event = AC.Event || {};
AC.Event.stop = function(a) {
    if (!a) {
        a = window.event
    }
    if (a.stopPropagation) {
        a.stopPropagation()
    } else {
        a.cancelBubble = true
    }
    if (a.preventDefault) {
        a.preventDefault()
    }
    a.stopped = true;
    a.returnValue = false
};
AC.Event.target = function(a) {
    return (typeof a.target != "undefined") ? a.target : a.srcElement
};
var AC = window.AC || {};
AC.Function = AC.Function || {};
AC.Function.emptyFunction = function() {
};
AC.Function.bindAsEventListener = function(a, c) {
    var b = AC.Array.toArray(arguments).slice(2);
    return function(d) {
        return a.apply(c, [d || window.event].concat(b))
    }
};
AC.Function.getParamNames = function(b) {
    var a = b.toString();
    return a.slice(a.indexOf("(") + 1, a.indexOf(")")).match(/([^\s,]+)/g) || []
};
var AC = window.AC || {};
AC.Object = AC.Object || {};
if (Object.extend) {
    AC.Object.extend = Object.extend
} else {
    AC.Object.extend = function extend(a, c) {
        var b;
        for (b in c) {
            if (c.hasOwnProperty(b)) {
                a[b] = c[b]
            }
        }
        return a
    }
}
if (Object.clone) {
    AC.Object.clone = Object.clone
} else {
    AC.Object.clone = function clone(a) {
        return AC.Object.extend({}, a)
    }
}
if (Object.getPrototypeOf) {
    AC.Object.getPrototypeOf = Object.getPrototypeOf
} else {
    if (typeof this["__proto__"] === "object") {
        AC.Object.getPrototypeOf = function getPrototypeOf(a) {
            return a.__proto__
        }
    } else {
        AC.Object.getPrototypeOf = function getPrototypeOf(c) {
            var a = c.constructor;
            var b;
            if (Object.prototype.hasOwnProperty.call(c, "constructor")) {
                b = a;
                if (!(delete c.constructor)) {
                    return null
                }
                a = c.constructor;
                c.constructor = b
            }
            return a ? a.prototype : null
        }
    }
}
var AC = window.AC || {};
AC.RegExp = AC.RegExp || {};
AC.RegExp.isRegExp = function(a) {
    return (a.constructor.name === "RegExp")
};
var AC = window.AC || {};
AC.String = AC.String || {};
AC.String.isString = function(a) {
    return typeof a == "string"
};
var AC = window.AC || {};
AC.Object.extend(AC, {uid: function ac_uid() {
        if (!AC._uid) {
            AC._uid = 0
        }
        return AC._uid++
    },log: function ac_log(a) {
        if (window.console && console.log) {
            console.log(a)
        }
    },namespace: function ac_namespace(b) {
        if (!(b && b.match && b.match(/\S/))) {
            throw "Attempt to create AC.namespace with no name."
        }
        var a = b.split(/\./), c = window;
        for (i = 0; i < a.length; i++) {
            c[a[i]] = c[a[i]] || {};
            c = c[a[i]]
        }
    },bindEventListeners: function ac_bindEventListeners(c, d, b) {
        d = AC.Element.getElementById(d);
        if (!AC.Element.isElement(d)) {
            throw "Invalid or non-existent element passed to bindEventListeners."
        }
        for (aKey in b) {
            var a = b[aKey];
            if (typeof a == "function") {
                AC.Element.addEventListener(d, aKey, AC.Function.bindAsEventListener(a, c))
            } else {
                if (typeof a == "string") {
                    AC.Element.addEventListener(d, aKey, AC.Function.bindAsEventListener(c[a], c))
                }
            }
        }
    }});
var ac_domready = function(c) {
    var b = false;
    var h = true;
    var k = window.document;
    var j = k.documentElement;
    var n = k.addEventListener ? "addEventListener" : "attachEvent";
    var l = k.addEventListener ? "removeEventListener" : "detachEvent";
    var a = k.addEventListener ? "" : "on";
    var m = function(f) {
        if (f.type == "readystatechange" && k.readyState != "complete") {
            return
        }
        (f.type == "load" ? window : k)[l](a + f.type, m, false);
        if (!b && (b = true)) {
            c.call(window, f.type || f)
        }
    };
    var g = function() {
        try {
            j.doScroll("left")
        } catch (f) {
            setTimeout(g, 50);
            return
        }
        m("poll")
    };
    if (k.readyState == "complete") {
        c.call(window, "lazy")
    } else {
        if (k.createEventObject && j.doScroll) {
            try {
                h = !window.frameElement
            } catch (d) {
            }
            if (h) {
                g()
            }
        }
        k[n](a + "DOMContentLoaded", m, false);
        k[n](a + "readystatechange", m, false);
        window[n](a + "load", m, false)
    }
};
AC.Object.extend(AC, {onDOMReady: ac_domready});
AC.windowHasLoaded = false;
AC.Element.addEventListener(window, "load", function() {
    AC.windowHasLoaded = true
});
AC.namespace("AC.Synthesize");
AC.Synthesize.synthesize = function(c) {
    if (typeof c !== "object") {
        c = this
    }
    var b, a;
    for (a in c) {
        if (c.hasOwnProperty(a)) {
            if (a.charAt(0) === "_" && !(a.charAt(1) === "_")) {
                if (typeof c[a] !== "function") {
                    this.__synthesizeGetter(a, c);
                    this.__synthesizeSetter(a, c)
                }
            }
        }
    }
};
AC.Synthesize.__synthesizeGetter = function(a, b) {
    var c = a.slice(1, a.length);
    if (typeof b[c] === "undefined") {
        b[c] = function() {
            return b[a]
        }
    }
};
AC.Synthesize.__synthesizeSetter = function(a, b) {
    var c = a.slice(1, a.length);
    c = "set" + c.slice(0, 1).toUpperCase() + c.slice(1, c.length);
    if (typeof b[c] === "undefined") {
        b[c] = function(d) {
            b[a] = d
        }
    }
};
AC.namespace("AC.Object");
AC.Object.synthesize = function(a) {
    if (typeof a === "object") {
        AC.Object.extend(a, AC.Object.clone(AC.Synthesize));
        a.synthesize();
        return a
    } else {
        throw "Argument supplied was not a valid object.";
        return a
    }
};
AC.Class = function() {
    var a = AC.Array.toArray(arguments);
    var e = (typeof a[0] === "function") ? a.shift() : null;
    var d = a.shift() || {};
    var c;
    var b = function() {
        var f;
        var g;
        f = ((typeof this.initialize === "function" && b.__shouldInitialize !== false) ? this.initialize.apply(this, arguments) : false);
        if (f === AC.Class.Invalidate) {
            g = function() {
                try {
                    if (this && this._parentClass && this._parentClass._sharedInstance === this) {
                        this._parentClass._sharedInstance = null
                    }
                } catch (h) {
                    throw h
                }
            };
            window.setTimeout(g.bind(this), 200)
        }
    };
    if (e) {
        if (e.__superclass) {
            c = AC.Class(e.__superclass, e.prototype)
        } else {
            c = AC.Class(e.prototype)
        }
        c.__shouldInitialize = false;
        b.prototype = new c();
        AC.Object.extend(b.prototype, d);
        AC.Class.__wrapSuperMethods(b)
    } else {
        b.prototype = d
    }
    b.sharedInstance = function() {
        if (!b._sharedInstance) {
            b._sharedInstance = new b();
            b._sharedInstance._parentClass = b
        }
        return b._sharedInstance
    };
    b.__superclass = e;
    AC.Object.synthesize(b.prototype);
    b.autocreate = d.__instantiateOnDOMReady || false;
    delete d.__instantiateOnDOMReady;
    if (b.autocreate) {
        AC.onDOMReady(function() {
            if (b.autocreate) {
                b.sharedInstance()
            }
        })
    }
    return b
};
AC.Class.__wrapSuperMethods = function(d) {
    var c = d.prototype;
    var b = AC.Object.getPrototypeOf(c);
    var e;
    for (e in c) {
        if (c.hasOwnProperty(e)) {
            if (typeof c[e] === "function") {
                var a = c[e];
                var f = AC.Function.getParamNames(a);
                if (f[0] === "$super") {
                    c[e] = (function(h, g) {
                        var j = b[h];
                        return function k() {
                            var l = AC.Array.toArray(arguments);
                            return g.apply(this, [j.bind(this)].concat(l))
                        }
                    }(e, a))
                }
            }
        }
    }
    return this
};
AC.Class.Invalidate = function() {
    return false
};
AC.namespace("AC.Ajax");
AC.Ajax.getTransport = function() {
    var a = false;
    try {
        a = new XMLHttpRequest()
    } catch (b) {
        try {
            a = new ActiveXObject("Msxml2.XMLHTTP")
        } catch (b) {
            try {
                a = new ActiveXObject("Microsoft.XMLHTTP")
            } catch (b) {
                a = false
            }
        }
    }
    return a
};
AC.Ajax.AjaxTracker = AC.Class();
AC.Ajax.AjaxTracker.prototype = {_responders: [],initialize: function ac_initialize() {
    },addResponder: function ac_addResponder(a) {
        this._responders.push(a)
    },removeResponder: function ac_removeResponder(a) {
        var c = 0, b = this._responders.length;
        for (c = 0; c < b; c += 1) {
            if (this._responders[c] === a) {
                a = null;
                this._responders.splice(c, 1);
                return true
            }
        }
        return false
    }};
AC.Ajax.AjaxRequest = AC.Class();
AC.Ajax.AjaxRequest.prototype = {__defaultOptions: {method: "get"},initialize: function ac_initialize(b, a) {
        this._transport = AC.Ajax.getTransport();
        this._mimeTypeOverride = null;
        this._options = null;
        AC.Object.synthesize(this);
        this.setOptions(AC.Object.extend(AC.Object.clone(this.__defaultOptions), a || {}));
        AC.Ajax.AjaxTracker.sharedInstance().addResponder(this);
        this.transport().onreadystatechange = this._handleTransportStateChange.bind(this);
        this.transport().open(this.options().method, b, true);
        this.transport().setRequestHeader("Content-Type", this.options().contentType);
        this.transport().send(null)
    },_handleTransportStateChange: function ac__handleTransportStateChange() {
        if (this.transport().readyState === 4) {
            var a = new AC.Ajax.AjaxResponse(this)
        }
    },overrideMimeType: function ac_overrideMimeType(a) {
        this._mimeTypeOverride = a;
        if (this.transport().overrideMimeType) {
            this.transport().overrideMimeType(a)
        }
    }};
AC.Ajax.AjaxResponse = AC.Class();
AC.Ajax.AjaxResponse.prototype = {_request: null,_transport: null,initialize: function ac_initialize(b) {
        var a = false, c = b.transport();
        this._transport = c;
        this._request = b;
        if (c.readyState === 4) {
            if (c.status == 0 || (c.status >= 200 && c.status < 300)) {
            	console.log(b.options().onSuccess);
                b.options().onSuccess ? b.options().onSuccess(this) : AC.Function.emptyFunction();
                a = true
            }
        } else {
            if (c.status >= 400 && c.status < 500) {
                b.options().onFailure ? b.options().onFailure(this) : AC.Function.emptyFunction();
                a = true
            } else {
                if (c.status >= 300 && c.status < 400) {
                    a = true
                } else {
                    if (c.status >= 500 && c.status < 600) {
                        b.options().onError ? b.options().onError(this) : AC.Function.emptyFunction();
                        a = true
                    }
                }
            }
        }
        if (a === true) {
            b.options().onComplete ? b.options().onComplete(this) : AC.Function.emptyFunction();
            AC.Ajax.AjaxTracker.sharedInstance().removeResponder(b)
        }
    },responseText: function ac_responseText() {
        return this._transport.responseText
    },responseXML: function ac_responseXML() {
        return this._transport.responseXML
    },responseJSON: function ac_responseJSON() {
        return JSON.parse ? JSON.parse(this._transport.responseText) : (new Function("return " + this._transport.responseText)())
    }};
AC.Ajax.checkURL = function(a, c) {
    var b = AC.Ajax.getTransport();
    b.onreadystatechange = function() {
        if (this.readyState === 4) {
            if (typeof c === "function") {
                c(this.status === 200)
            }
        }
    };
    b.open("HEAD", a, true);
    b.send(null)
};
AC.Ajax.AjaxRequest.prototype._overrideMimeType = null;
AC.Ajax.AjaxRequest.prototype.overrideMimeType = function(a) {
    this._overrideMimeType = a;
    if (this.transport.overrideMimeType) {
        this.transport.overrideMimeType(a)
    }
};
AC.namespace("AC.Environment");
AC.namespace("AC.Environment.Browser");
(function(c) {
    var e;
    var f;
    var b;
    var a;
    var d;
    e = [{string: window.navigator.userAgent,subString: "Chrome",identity: "Chrome"}, {string: window.navigator.userAgent,subString: "OmniWeb",versionSearch: "OmniWeb/",identity: "OmniWeb"}, {string: window.navigator.userAgent,subString: /mobile\/[^\s]*\ssafari\//i,identity: "Safari Mobile",versionSearch: "Version"}, {string: window.navigator.vendor,subString: "Apple",identity: "Safari",versionSearch: "Version"}, {prop: window.opera,identity: "Opera",versionSearch: "Version"}, {string: window.navigator.vendor,subString: "iCab",identity: "iCab"}, {string: window.navigator.vendor,subString: "KDE",identity: "Konqueror"}, {string: window.navigator.userAgent,subString: "Firefox",identity: "Firefox"}, {string: window.navigator.vendor,subString: "Camino",identity: "Camino"}, {string: window.navigator.userAgent,subString: "Netscape",identity: "Netscape"}, {string: window.navigator.userAgent,subString: "MSIE",identity: "IE",versionSearch: "MSIE"}, {string: window.navigator.userAgent,subString: "Gecko",identity: "Mozilla",versionSearch: "rv"}, {string: window.navigator.userAgent,subString: "Mozilla",identity: "Netscape",versionSearch: "Mozilla"}];
    f = [{string: window.navigator.platform,subString: "Win",identity: "Windows"}, {string: window.navigator.platform,subString: "Mac",identity: "OS X"}, {string: window.navigator.userAgent,subString: "iPhone",identity: "iOS"}, {string: window.navigator.userAgent,subString: "iPad",identity: "iOS"}, {string: window.navigator.platform,subString: "Linux",identity: "Linux"}];
    b = function(k) {
        var h;
        var j;
        var g;
        for (g = 0; g < k.length; g += 1) {
            h = k[g].string;
            j = k[g].prop;
            d = k[g].versionSearch || k[g].identity;
            if (h) {
                if (AC.RegExp.isRegExp(k[g].subString) && !!h.match(k[g].subString)) {
                    return k[g].identity
                } else {
                    if (h.indexOf(k[g].subString) !== -1) {
                        return k[g].identity
                    }
                }
            } else {
                if (j) {
                    return k[g].identity
                }
            }
        }
    };
    a = function(h) {
        var g = h.indexOf(d);
        if (g === -1) {
            return
        }
        return parseFloat(h.substring(g + d.length + 1))
    };
    c.name = b(e) || undefined;
    c.version = a(window.navigator.userAgent) || a(window.navigator.appVersion) || undefined;
    c.os = b(f) || undefined;
    return c
}(AC.Environment.Browser));
AC.namespace("AC.Environment.Feature");
(function() {
    var c = null;
    var d = null;
    var a = null;
    var b = null;
    AC.Environment.Feature.isCSSAvailable = function(o) {
        if (c === null) {
            c = document.createElement("browserdetect").style
        }
        if (d === null) {
            d = ["-webkit-", "-moz-", "-o-", "-ms-", "-khtml-", ""]
        }
        if (a === null) {
            a = ["Webkit", "Moz", "O", "ms", "Khtml", ""]
        }
        if (b === null) {
            b = {}
        }
        o = o.replace(/([A-Z]+)([A-Z][a-z])/g, "$1-$2").replace(/([a-z\d])([A-Z])/g, "$1-$2").replace(/^(\-*webkit|\-*moz|\-*o|\-*ms|\-*khtml)\-/, "").toLowerCase();
        switch (o) {
            case "gradient":
                if (b.gradient !== undefined) {
                    return b.gradient
                }
                o = "background-image:";
                var m = "gradient(linear,left top,right bottom,from(#9f9),to(white));";
                var l = "linear-gradient(left top,#9f9, white);";
                c.cssText = (o + d.join(m + o) + d.join(l + o)).slice(0, -o.length);
                b.gradient = (c.backgroundImage.indexOf("gradient") !== -1);
                return b.gradient;
            case "inset-box-shadow":
                if (b["inset-box-shadow"] !== undefined) {
                    return b["inset-box-shadow"]
                }
                o = "box-shadow:";
                var n = "#fff 0 1px 1px inset;";
                c.cssText = d.join(o + n);
                b["inset-box-shadow"] = (c.cssText.indexOf("inset") !== -1);
                return b["inset-box-shadow"];
            default:
                var k = o.split("-");
                var e = k.length;
                var h;
                var g;
                var f;
                if (k.length > 0) {
                    o = k[0];
                    for (g = 1; g < e; g += 1) {
                        o += k[g].substr(0, 1).toUpperCase() + k[g].substr(1)
                    }
                }
                h = o.substr(0, 1).toUpperCase() + o.substr(1);
                if (b[o] !== undefined) {
                    return b[o]
                }
                for (f = a.length - 1; f >= 0; f -= 1) {
                    if (c[a[f] + o] !== undefined || c[a[f] + h] !== undefined) {
                        b[o] = true;
                        return true
                    }
                }
                return false
        }
    }
}());
AC.Environment.Feature.supportsThreeD = function() {
    if (typeof this._supportsThreeD !== "undefined") {
        return this._supportsThreeD
    }
    var c;
    try {
        this._supportsThreeD = false;
        if (window.hasOwnProperty("styleMedia")) {
            this._supportsThreeD = window.styleMedia.matchMedium("(-webkit-transform-3d)")
        } else {
            if (window.hasOwnProperty("media")) {
                this._supportsThreeD = window.media.matchMedium("(-webkit-transform-3d)")
            }
        }
        if (!this._supportsThreeD) {
            if (!document.getElementById("supportsThreeDStyle")) {
                var a = document.createElement("style");
                a.id = "supportsThreeDStyle";
                a.textContent = "@media (transform-3d),(-o-transform-3d),(-moz-transform-3d),(-ms-transform-3d),(-webkit-transform-3d) { #supportsThreeD { height:3px } }";
                document.querySelector("head").appendChild(a)
            }
            if (!(c = document.querySelector("#supportsThreeD"))) {
                c = document.createElement("div");
                c.id = "supportsThreeD";
                document.body.appendChild(c)
            }
            this._supportsThreeD = (c.offsetHeight === 3)
        }
        return this._supportsThreeD
    } catch (b) {
        return false
    }
};
(function() {
    var a = null;
    AC.Environment.Feature.supportsCanvas = function() {
        if (a !== null) {
            return a
        }
        var b = document.createElement("canvas");
        a = !!(typeof b.getContext === "function" && b.getContext("2d"));
        return a
    }
}());
AC.Registry = AC.Class();
AC.Registry.prototype = {__defaultOptions: {contextInherits: []},initialize: function ac_initialize(b, a) {
        if (typeof b !== "string") {
            throw "Prefix not defined for Component Registry"
        }
        if (typeof a !== "object") {
            a = {}
        }
        this._options = AC.Object.extend(AC.Object.clone(this.__defaultOptions), a);
        this._prefix = b;
        this._reservedNames = [];
        this.__model = [];
        this.__lookup = {};
        AC.Object.synthesize(this)
    },addComponent: function ac_addComponent(b, d, f, g, c) {
        var e = null;
        var a;
        if (!this.__isReserved(b)) {
            if (typeof b === "string") {
                if (typeof g === "string") {
                    e = this.lookup(g)
                }
                if (!e && b !== "_base") {
                    e = this.lookup("_base") || this.addComponent("_base")
                }
                if (this.lookup(b)) {
                    throw "Cannot overwrite existing Component: " + b
                }
                if (typeof c !== "object") {
                    c = {}
                }
                if (typeof c.inherits === "undefined" && Array.isArray(this._options.contextInherits)) {
                    c.inherits = this._options.contextInherits
                }
                a = this.__lookup[b] = new AC.Registry.Component(b, d, f, e, c);
                this.__addToModel(a);
                return a
            }
        }
        return null
    },match: function ac_match(b) {
        var a;
        if (a = this.__matchName(b)) {
            return a
        }
        if (a = this.__matchQualifier(b)) {
            return a
        }
        return null
    },__matchName: function ac___matchName(b) {
        var a, c;
        if (!AC.Element.isElement(b)) {
            return null
        }
        for (a = this.__model.length - 1; a >= 0; a--) {
            if (Array.isArray(this.__model[a])) {
                for (c = this.__model[a].length - 1; c >= 0; c--) {
                    if (AC.Element.hasClassName(b, this._prefix + this.__model[a][c].name())) {
                        return this.__model[a][c]
                    }
                }
            }
        }
        return null
    },__matchQualifier: function ac___matchQualifier(b) {
        var a, c;
        if (!AC.Element.isElement(b)) {
            return null
        }
        for (a = this.__model.length - 1; a >= 0; a--) {
            if (Array.isArray(this.__model[a])) {
                for (c = this.__model[a].length - 1; c >= 0; c--) {
                    if (typeof this.__model[a][c].qualifier === "function") {
                        if (this.__model[a][c].qualifier.apply(this.__model[a][c], [b, this._prefix]) === true) {
                            return this.__model[a][c]
                        }
                    }
                }
            }
        }
        return null
    },__addToModel: function ac___addToModel(a) {
        if (AC.Registry.Component.isComponent(a)) {
            if (typeof this.__model[a.level()] === "undefined") {
                this.__model[a.level()] = []
            }
            this.__model[a.level()].push(a)
        }
    },lookup: function ac_lookup(a) {
        if (typeof a === "string") {
            if (typeof this.__lookup[a] !== "undefined") {
                return this.__lookup[a]
            }
        }
        return null
    },hasComponent: function ac_hasComponent(a) {
        var b;
        if (typeof a === "object" && typeof a.name === "function") {
            if (b = this.lookup(a.name())) {
                return b === a
            }
        }
        return false
    },reserveName: function ac_reserveName(a) {
        if (typeof a === "string") {
            if (this.lookup(a)) {
                this._reservedNames.push(a)
            } else {
                throw "Cannot reserve name: Component with name already exists."
            }
        } else {
            throw "Cannot reserve name: Name must be a string"
        }
    },__isReserved: function ac___isReserved(a) {
        if (typeof a === "string") {
            return (this._reservedNames.indexOf(a) !== -1)
        } else {
            throw "Cannot check if this name is reserved because it is not a String."
        }
    }};
AC.Registry.Component = AC.Class();
AC.Registry.Component.prototype = {initialize: function ac_initialize(a, c, e, d, b) {
        if (typeof a !== "string") {
            throw "Cannot create Component without a name"
        }
        this._name = a;
        this._properties = c || {};
        this.qualifier = typeof e === "function" ? e : AC.Function.emptyFunction;
        this._parent = d;
        this._context = b || {};
        AC.Object.synthesize(this)
    },properties: function ac_properties() {
        var a = (typeof this._parent === "undefined" || this._parent === null) ? {} : this._parent.properties();
        return AC.Object.extend(a, this._properties)
    },context: function ac_context(a) {
        if (this._context[a]) {
            return this._context[a]
        } else {
            if (Array.isArray(this._context.inherits) && this._context.inherits.indexOf[a] !== -1) {
                return (this.parent()) ? this.parent().context(a) : null
            }
        }
        return null
    },level: function ac_level() {
        if (typeof this._level !== "undefined") {
            return this._level
        }
        if (this._name === "_base") {
            return 0
        } else {
            if (typeof this._parent === "undefined" || this._parent.name() === "_base") {
                return 1
            } else {
                return this._parent.level() + 1
            }
        }
    }};
AC.Registry.Component.isComponent = function(a) {
    return (a instanceof AC.Registry.Component)
};
AC.namespace("AC.NotificationCenter");
AC.NotificationCenter = (function() {
    var e = {};
    return {publish: function b(j, g, f) {
            g = g || {};
            var h = function() {
                if ((!e[j]) || e[j].length < 1) {
                    return
                }
                e[j].forEach(function(k) {
                    if (k.target && g.target) {
                        if (k.target === g.target) {
                            k.callback(g.data)
                        }
                    } else {
                        k.callback(g.data)
                    }
                })
            };
            if (typeof window.testtool === "object" && typeof testtool.publishMessage === "function") {
                if (typeof testtool.mDefaults === "object") {
                    testtool.mDefaults.messageData = g
                }
                testtool.publishMessage(j)
            }
            if (f === true) {
                window.setTimeout(h, 10)
            } else {
                h()
            }
        },subscribe: function c(f, h, g) {
            if (!e[f]) {
                e[f] = []
            }
            e[f].push({callback: h,target: g})
        },unsubscribe: function d(f, h, g) {
            e[f].forEach(function(k, j) {
                if (g) {
                    if (h === k.callback && k.target === g) {
                        e[f].splice(j, 1)
                    }
                } else {
                    if (h === k.callback) {
                        e[f].splice(j, 1)
                    }
                }
            })
        },hasSubscribers: function a(f, g) {
            if ((!e[f]) || e[f].length < 1) {
                return false
            }
            if (!g) {
                return true
            }
            e[f].forEach(function(h) {
                if (h.target && g) {
                    if (h.target === g) {
                        return true
                    }
                }
            });
            return false
        }}
}());
AC.namespace("AC.Canvas");
AC.Canvas.imageDataFromFile = function(b, c) {
    if (typeof c !== "function") {
        throw "Need callback method to call when imageData is retrieved."
    }
    if (typeof b !== "string" || b === "") {
        throw "Src for imageData must be an Image Node with a src attribute or a string."
    }
    var a = new Image();
    a.onload = function() {
        c(AC.Canvas.imageDataFromNode(a))
    };
    a.src = b
};
AC.Canvas.imageDataFromNode = function(a) {
    if (!AC.Element.isElement(a) || a.getAttribute("src") === "null" || a.width === 0) {
        throw "Source node must be an IMG tag and must have already loaded."
    }
    var d;
    var b = document.createElement("canvas");
    var c = b.getContext("2d");
    b.width = a.width;
    b.height = a.height;
    c.drawImage(a, 0, 0);
    d = c.getImageData(0, 0, a.width, a.height);
    return d
};
