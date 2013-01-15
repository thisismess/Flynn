AC.Flow = AC.Class({
    __defaultOptions: {
        fps: 24,
        diffStart: 1,
        benchmark: false
    },
    initialize: function ac_initialize(f, e, c, a) {
        if (!AC.Environment.Feature.supportsCanvas()) {
            this.__publish("degraded");
            return false
        }
        this.setOptions(a);
        this._delegate = {};
        this._canPlay = false;
        this._width = null;
        this._height = null;
        this._loaded = false;
        this._diff = null;
        this._keyframe = null;
        this._framecount = null;
        this._currentFrame = -1;
        AC.Object.synthesize(this);
        this.__isPlaying = false;
        this.__blocksPerFullDiff = null;
        this.__columnsInCanvas = null;
        this.__frames = null;
        this.__diffSrc = f;
        this.__manifest = new AC.Flow.Manifest(e);
        AC.NotificationCenter.subscribe(AC.Flow.notificationPrefix() + "manifestLoaded", this.__onManifestLoad.bind(this), this.__manifest);
        if (this.options().benchmark === true && typeof Stats !== "undefined" && !AC.Flow.stats) {
            var d = "ac-flow-benchmark-stats";
            var b = AC.Element.selectAll("." + d);
            AC.Flow.stats = new Stats();
            document.body.appendChild(AC.Flow.stats.domElement);
            AC.Element.addClassName(AC.Flow.stats.domElement, d);
            AC.Flow.stats.domElement.id = d + "-" + b.length;
            AC.Flow.stats.domElement.title = c;
            AC.Flow.stats.domElement.style.position = "fixed";
            AC.Flow.stats.domElement.style.top = 0;
            AC.Flow.stats.domElement.style.left = b.length * 80 + "px";
            AC.Flow.stats.domElement.style.zIndex = 10000;
            AC.Flow.stats.setMode(0)
        }
        this.__loadImage(this.__getKeyframeSrc(c), this.__onDidLoadKeyframe.bind(this))
    },
    play: function ac_play(b, a) {
        if (this.__isPlaying === true) {
            return false
        }
        a = typeof a === "object" ? a : {};
        this.__doWhenCanPlay(this.__play, [b, a])
    },
    pause: function ac_pause() {
        if (this.__isPlaying === true) {
            this.__isPlaying = false;
            window.clearTimeout(this.__animationTimeout);
            this.__publish("didPause", true)
        }
    },
    showFrame: function ac_showFrame(c, e, d, b) {
        if (isNaN(e)) {
            return false
        }
        this.pause();
        if (AC.Element.isElement(b) && b.tagName.toLowercase() === "img") {
            b = b.getAttribute("src")
        }
        if (typeof b === "string") {
            var a = this;
            this.__loadImage(b, function (f) {
                a.setCurrentFrame.apply(a, [e]);
                a.__showImage.apply(a, [c, f])
            })
        } else {
            this.__doWhenCanPlay(this.__showFrame, [c, e, d])
        }
    },
    setupCanvas: function ac_setupCanvas(a, c) {
        var b;
        a = AC.Element.getElementById(a);
        if (!AC.Element.isElement(a) || a.tagName.toLowerCase() !== "canvas") {
            throw "Playing a sequence requires a canvas tag to be present."
        }
        b = a.getContext("2d");
        if (a.getAttribute("width") === null) {
            a.setAttribute("width", this.width())
        }
        if (a.getAttribute("height") === null) {
            a.setAttribute("height", this.height())
        }
        if (c === true) {
            this.__showImage(a, this.keyframe())
        }
        return b
    },
    cleanup: function ac_cleanup() {
        this.setCanPlay(false);
        this.setLoaded(false);
        this.setKeyframe(null);
        this._diff = null;
        this.__diffSrcs = null;
        this.__frames = null;
        this.__manifest = null
    }
});
AC.Flow.version = "1.0";
if (typeof document !== "undefined") {
    document.createElement("canvas")
}
AC.Flow.createHighBitNumber = function (b, a) {
    return (b << 8) + a
};
AC.Flow.valueForCharAt = function (c, a) {
    var b = c.charCodeAt(a);
    if (b > 64 && b < 91) {
        return b - 65
    }
    if (b > 96 && b < 123) {
        return b - 71
    }
    if (b > 47 && b < 58) {
        return b + 4
    }
    if (b === 43) {
        return 62
    }
    if (b === 47) {
        return 63
    }
    throw "Invalid Bas64 character: " + c.charAt(a)
};
AC.Flow.createNumberFromBase64Range = function (e, a, d) {
    var c = 0;
    var b;
    while (d--) {
        b = AC.Flow.valueForCharAt(e, a++);
        c += (b << d * 6)
    }
    return c
};
AC.Flow.notificationPrefix = function () {
    return AC.Flow._notificationPrefix
};
AC.Flow._notificationPrefix = "ac-flow-";
AC.Object.extend(AC.Flow.prototype, {
    __applyDiff: function ac___applyDiff(c, f, b, g, d, e) {
        var a;
        if (f) {
            for (a = 0; a < f.length; a += 1) {
                this.__applyDiffRange(c, f[a], b, g, d, e)
            }
        }
    },
    __applyDiffRange: function ac___applyDiffRange(e, m, j, l, p, c) {
        var d = m.block;
        var b = m.length;
        var r = Math.floor(d / this.__blocksPerFullDiff);
        var i = c[r].width;
        var q = d % this.__blocksPerFullDiff;
        var a = i / j;
        var o = (q % a) * j;
        var n = Math.floor(q / (a || 1)) * j;
        var h = (m.location % this.__columnsInCanvas) * j;
        var g = Math.floor(m.location / this.__columnsInCanvas) * j;
        console.log("Writting block");
        console.log(m);
        console.log(n);
        var k;
        var f;
        while (b) {
            k = Math.min((b * j), p - h, i - o);
            f = k / j;
            e.clearRect(h, g, k, j);
            e.drawImage(c[r], o, n, k, j, h, g, k, j);
            b -= f;
            if (b) {
                if ((o += k) >= i) {
                    o = 0;
                    n += j
                }
                if ((q += f) >= this.__blocksPerFullDiff) {
                    q = 0;
                    o = 0;
                    n = 0;
                    r += 1;
                    if (r === l - 1) {
                        i = c[r].width
                    }
                }
                if ((h += k) >= p) {
                    h = 0;
                    g += j
                }
                d += f
            }
        }
    }
});
AC.Object.extend(AC.Flow.prototype, {
    __diffImageLoaded: function ac___diffImageLoaded() {
        if (isNaN(this.__diffLoadedCount)) {
            this.__diffLoadedCount = 0
        }
        this.__diffLoadedCount += 1;
        if (this.__diffLoadedCount === this.__manifest.diffImageCount()) {
            this.__onDiffLoaded();
            this.setLoaded(true);
            this.__publish("didLoad", true);
            this.__canPlay();
            delete this.__diffLoadedCount
        }
    },
    __frameStringFromNumber: function ac___frameStringFromNumber(a, b) {
        var c = a + "";
        while (c.length < b) {
            c = "0" + c
        }
        return c
    },
    setDiff: function ac_setDiff(f) {
        if (this._diff !== null) {
            throw "Diff cannot be set more than once"
        }
        var e = f.match(/^([^#]*)(#+)([^#]*)$/);
        var c;
        var a;
        var d = 0;
        var b = this.__diffImageLoaded.bind(this);
        this._diff = [];
        this.__diffSrcs = [];
        for (c = this.options().diffStart; c <= (this.__manifest.diffImageCount() + (this.options().diffStart - 1)); c += 1) {
            a = e[1] + this.__frameStringFromNumber(c, e[2].length) + e[3];
            this.__diffSrcs.push(a);
            this._diff.push(this.__loadImage(a, b))
        }
    }
});
AC.namespace("AC.Flow.SharedMethods");
AC.Flow.SharedMethods.setOptions = function (b) {
    if (typeof this._options !== "undefined") {
        throw "Options cannot be set more than once"
    }
    var a = AC.Object.clone(this.__defaultOptions);
    if (typeof b === "object") {
        this._options = AC.Object.extend(a, b)
    } else {
        this._options = a
    }
};
AC.Flow.SharedMethods.__publish = function (c, b, d) {
    d = typeof d === "undefined" ? this : d;
    AC.NotificationCenter.publish(AC.Flow.notificationPrefix() + c, {
        target: this,
        data: d
    }, true);
    var a = "on" + c.slice(0, 1).toUpperCase() + c.slice(1, c.length);
    if (b === true && typeof this.delegate()[a] === "function") {
        this.delegate()[a](d)
    }
};
AC.Flow.SharedMethods.__doWhenCanPlay = function (d, c) {
    if (this.canPlay()) {
        d.apply(this, c)
    } else {
        var b = this;
        var a = function (e) {
            d.apply(b, c)
        };
        AC.NotificationCenter.subscribe(AC.Flow.notificationPrefix() + "canPlay", a, this)
    }
};
AC.Flow.SharedMethods.__setupContainer = function () {
    if (typeof this.setContext !== "function") {
        this._context = null
    }
    if (typeof this.setCanvas !== "function") {
        this._context = null
    }
    AC.Object.synthesize(this);
    this.container().innerHTML = "";
    if (this.container().tagName.toLowerCase() === "canvas") {
        this.setCanvas(this.container())
    } else {
        this.setCanvas(document.createElement("canvas"));
        this.container().appendChild(this.canvas())
    }
    this.setContext(this.canvas().getContext("2d"))
};
AC.Flow.SharedMethods.benchmarkStart = function () {
    if (AC.Flow.stats) {
        if (AC.Flow.stats.__isCounting) {
            AC.Flow.stats.end()
        }
        AC.Flow.stats.begin();
        AC.Flow.stats.__isCounting = true
    }
};
AC.Flow.SharedMethods.benchmarkEnd = function () {
    if (AC.Flow.stats) {
        if (AC.Flow.stats.__isCounting) {
            AC.Flow.stats.end()
        }
        AC.Flow.stats.__isCounting = false
    }
};
AC.Object.extend(AC.Flow.prototype, {
    __onDiffLoaded: function ac___onDiffLoaded() {
        this.__blocksPerFullDiff = (this.diff()[0].width / this.__manifest.size()) * (this.diff()[0].height / this.__manifest.size())
    },
    __onDidLoadKeyframe: function ac___onDidLoadKeyframe(a) {
        this.setKeyframe(a);
        this.setWidth(a.width);
        this.setHeight(a.height);
        this.__publish("didLoadKeyframe", true);
        this.__canPlay()
    },
    __onManifestLoad: function ac___onManifestLoad() {
        this.setDiff(this.__diffSrc);
        delete this.__diffSrc;
        this.setFramecount(this.__manifest.framecount() + 1);
        this.__frames = [null].concat(this.__manifest.frames());
        this.__canPlay()
    },
    __onBeforeCanPlay: function ac___onBeforeCanPlay() {
        this.__columnsInCanvas = this.width() / this.__manifest.size()
    },
    __publish: AC.Flow.SharedMethods.__publish
});
AC.Object.extend(AC.Flow.prototype, {
    __play: function ac___play(g, n) {
        var m = this;
        var i = this.framecount();
        n.fps = !isNaN(n.fps) ? n.fps : this.options().fps;
        n.toFrame = !isNaN(n.toFrame) && n.toFrame >= 0 && n.toFrame < i ? n.toFrame : i - 1;
        var c = 1000 / n.fps;
        var f = this.setupCanvas(g, false);
        var b = this.currentFrame();
        var d = (n.continuous === true) ? Infinity : n.toFrame;
        var l = (d <= this.currentFrame());
        var k = this.__manifest.size();
        var h = this.__manifest.diffImageCount();
        var e = this.width();
        var j = this.diff();
        this.__isPlaying = true;
        this.__publish("willPlay", true);
        var a = function () {
            var p = new Date();
            b += 1;
            AC.Flow.SharedMethods.benchmarkStart();
            if (m.__frames[b]) {
                m.__applyDiff.apply(m, [f, m.__frames[b], k, h, e, j])
            } else {
                m.__showImage(g, m.keyframe())
            }
            if ((b < d || l === true) && m.__isPlaying === true) {
                if (b >= (i - 1)) {
                    l = false;
                    m.__publish("didPlay", true);
                    m.__reset();
                    b = -1
                } else {
                    m.setCurrentFrame(b)
                }
                m.__animationTimeout = window.setTimeout(a, Math.max(c - (new Date() - p), 10))
            } else {
                if (AC.Flow.stats) {
                    var q = ((new Date() - AC.Flow.stats.__benchmarkTimer));
                    var s = q - (c * i);
                    var o = s > 200 ? "warn" : "log";
                    try {
                        console[o]("Benchmark: " + (s >= 0 ? "+" : "") + (s / 1000))
                    } catch (r) {}
                    AC.Flow.stats.__isCounting = false
                }
                m.__isPlaying = false;
                m.setCurrentFrame(b);
                m.__publish("didPlay", true)
            }
        };
        if (AC.Flow.stats) {
            AC.Flow.stats.__benchmarkTimer = new Date()
        }
        this.__animationTimeout = window.setTimeout(a, c)
    },
    __reset: function ac___reset() {
        this.setCurrentFrame(0)
    },
    __showFrame: function ac___showFrame(c, j, f) {
        var b;
        var e;
        var h = this.__manifest.size();
        var d = this.__manifest.diffImageCount();
        var a = this.width();
        var g = this.diff();
        if (j <= this.currentFrame() || f === true) {
            this.__reset();
            b = this.setupCanvas(c, true)
        } else {
            if (this.currentFrame() !== 0) {
                this.setCurrentFrame(this.currentFrame() + 1)
            }
            b = this.setupCanvas(c)
        }
        for (e = this.currentFrame(); e <= Math.min(j, this.__frames.length - 1); e += 1) {
            this.__applyDiff(b, this.__frames[e], h, d, a, g)
        }
        this.setCurrentFrame(j)
    },
    __loadImage: function ac___loadImage(c, b) {
        var a = new Image();
        a.onload = function () {
            if (typeof b === "function") {
                b(a)
            }
        };
        a.onerror = function (d) {
            throw "Image not found: " + c
        };
        a.src = c;
        return a
    },
    __showImage: function ac___showImage(b, a) {
        var c;
        b = AC.Element.getElementById(b);
        c = b.getContext("2d");
        if (b.getAttribute("width") === null) {
            b.setAttribute("width", a.width)
        }
        if (b.getAttribute("height") === null) {
            b.setAttribute("height", a.height)
        }
        c.drawImage(a, 0, 0)
    },
    __getKeyframeSrc: function ac___getKeyframeSrc(a) {
        if (AC.Element.isElement(a) && a.tagName.toLowerCase() === "img") {
            a = a.getAttribute("src")
        }
        if (typeof a !== "string" || a === "") {
            throw "Keyframe provided is not valid IMG tag or src string."
        }
        return a
    },
    __canPlay: function ac___canPlay() {
        if (this.canPlay() !== true) {
            if ((this.__manifest.loaded() === true) && (this.keyframe() !== null) && (this.loaded() === true)) {
                this.__onBeforeCanPlay();
                this.setCanPlay(true);
                this.__publish("canPlay", true);
                return true
            }
            return false
        }
        return true
    },
    __doWhenCanPlay: AC.Flow.SharedMethods.__doWhenCanPlay,
    setOptions: AC.Flow.SharedMethods.setOptions
});
AC.Flow.Ambient = AC.Class();
AC.Flow.Ambient.prototype = {
    __defaultOptions: {
        autoplay: true,
        cleanup: true,
        endState: null
    },
    initialize: function ac_initialize(a, e, d, c, b) {
        if (!AC.Environment.Feature.supportsCanvas()) {
            return false
        }
        this.setOptions(b);
        this._delegate = {};
        this._container = AC.Element.getElementById(a);
        this._canvas = null;
        this._context = null;
        AC.Object.synthesize(this);
        if (!AC.Element.isElement(this.container())) {
            throw "Valid Element required for playing Ambient Sequence."
        }
        if (!c) {
            c = AC.Element.select("img", this.container())
        }
        this.__setupContainer();
        this.__setupSequence(e, d, c)
    },
    play: function ac_play(a) {
        this.__sequence.play(this.canvas(), a)
    },
    cleanup: function ac_cleanup() {
        this.setContainer(null);
        this.setCanvas(null);
        this.setContext(null);
        this.__endState = null;
        this.play = AC.Function.emptyFunction;
        this.__sequence.cleanup()
    }
};
AC.Object.extend(AC.Flow.Ambient.prototype, {
    onDidLoadKeyframe: function ac_onDidLoadKeyframe(a) {
        a.setupCanvas(this.canvas(), true)
    },
    onCanPlay: function ac_onCanPlay(a) {
        if (typeof this.options().endState === "string") {
            this.__preloadEndState()
        }
        this.__publish("canPlay", true)
    },
    onWillPlay: function ac_onWillPlay(a) {
        this.__publish("willPlay", true)
    },
    onDidPlay: function ac_onDidPlay(b) {
        if (typeof this.options().endState === "string") {
            var a = this;
            var c = function () {
                a.context().drawImage(a.__endState, 0, 0, a.__sequence.width(), a.__sequence.height())
            };
            if (this.__endState) {
                c()
            } else {
                this.__preloadEndState(c)
            }
        }
        this.__publish("didPlay", true);
        if (this.options().cleanup) {
            this.cleanup()
        }
    }
});
AC.Object.extend(AC.Flow.Ambient.prototype, {
    __setupSequence: function ac___setupSequence(c, b, a) {
        this.__sequence = new AC.Flow(c, b, a, this.options());
        this.__sequence.setDelegate(this);
        if (this.options().autoplay === true) 
        {
            this.__sequence.play(this.canvas())
        }
    },
    __preloadEndState: function ac___preloadEndState(d) {
        if (this.__preloadedEndState) {
            return
        }
        var b = this;
        var a = new Image();
        if (AC.Retina.sharedInstance().shouldReplace("img-tag") && typeof this.__replacedEndstateWith2x === "undefined") {
            var c = this.options().endState.replace(/(\.[a-z]{3})/, "_2x$1");
            AC.Ajax.checkURL(c, function (e) {
                b.__replacedEndstateWith2x = e;
                if (e === true) {
                    b.options().endState = c
                }
                b.__preloadEndState.call(b, d)
            })
        } else {
            a.onload = function () {
                b.__endState = a;
                if (typeof d === "function") {
                    d(a)
                }
            };
            a.src = this.options().endState;
            this.__preloadedEndState = true
        }
    },
    __setupContainer: AC.Flow.SharedMethods.__setupContainer,
    __publish: AC.Flow.SharedMethods.__publish,
    setOptions: AC.Flow.SharedMethods.setOptions
});
AC.Flow.BiDirectional = AC.Class({
    __defaultOptions: {},
    initialize: function ac_initialize(d, b, c) {
        if (!AC.Environment.Feature.supportsCanvas()) {
            return false
        }
        this.setOptions(c);
        this._forwards = d;
        this._backwards = b;
        this._delegate = {};
        this._canPlay = false;
        this._currentFlow = d;
        this._playing = false;
        AC.Object.synthesize(this);
        this.forwards().setDelegate(this);
        this.backwards().setDelegate(this);
        this.__sync();
        var a = this.__canPlay.bind(this);
        AC.NotificationCenter.subscribe(AC.Flow.notificationPrefix() + "canPlay", a, this.forwards());
        AC.NotificationCenter.subscribe(AC.Flow.notificationPrefix() + "canPlay", a, this.backwards())
    },
    play: function ac_play(b, a) {
        if (this.playing() === true) {
            return false
        }
        this.__doWhenCanPlay(this.__play, [b, a])
    },
    pause: function ac_pause() {
        if (this.playing() === true) {
            this.currentFlow().pause();
            this.setPlaying(false);
            this.__sync()
        }
    },
    showFrame: function ac_showFrame(b, d, c, a) {
        this.pause();
        this.__doWhenCanPlay(this.__showFrame, [b, d, c, a])
    }
});
AC.Object.extend(AC.Flow.BiDirectional.prototype, {
    onWillPlay: function ac_onWillPlay(a) {
        this.__publish("willPlay", true)
    },
    onDidPause: function ac_onDidPause(a) {
        this.__publish("didPause", true)
    },
    onDidPlay: function ac_onDidPlay(a) {
        this.setPlaying(false);
        this.__sync();
        this.__publish("didPlay", true)
    }
});
AC.Object.extend(AC.Flow.BiDirectional.prototype, {
    __play: function ac___play(c, b) {
        var a = (b.direction < 0) ? this.backwards() : this.forwards();
        this.setCurrentFlow(a);
        if (typeof b.toFrame !== "undefined" && this.currentFlow() === this.backwards()) {
            b.toFrame = (this.currentFlow().framecount() - 1) - b.toFrame
        }
        a.play(c, b);
        this.setPlaying(true)
    },
    __showFrame: function ac___showFrame(d, f, e, b) {
        var a;
        var h = this.__determineRelativeDeltaForwards(f);
        var c = this.__determineRelativeDeltaBackwards(f);
        if (typeof b === "string") {
            a = this.forwards()
        } else {
            a = this.__chooseFlowByDelta(h, c)
        }
        var g = (a === this.forwards()) ? f : ((this.currentFlow().framecount() - 1) - f);
        if (this.playing() === true) {
            this.pause()
        }
        a.showFrame(d, g, e, b);
        this.__sync()
    },
    __sync: function ac___sync() {
        var a;
        var c;
        var b;
        if (this.currentFlow() === this.forwards()) {
            a = this.forwards();
            c = this.backwards()
        } else {
            a = this.backwards();
            c = this.forwards()
        }
        b = (c.framecount() - 1) - a.currentFrame();
        c.setCurrentFrame(b)
    },
    __determineRelativeDeltaForwards: function ac___determineRelativeDeltaForwards(a) {
        var b = a - this.forwards().currentFrame();
        if (b < 0) {
            b = a
        }
        return b
    },
    __determineRelativeDeltaBackwards: function ac___determineRelativeDeltaBackwards(a) {
        var b = ((this.backwards().framecount() - 1) - a) - this.backwards().currentFrame();
        if (b < 0) {
            b = ((this.backwards().framecount() - 1) - a)
        }
        return b
    },
    __chooseFlowByDelta: function ac___chooseFlowByDelta(b, a) {
        if (Math.abs(b) <= Math.abs(a)) {
            this.setCurrentFlow(this.forwards())
        } else {
            this.setCurrentFlow(this.backwards())
        }
        return this.currentFlow()
    },
    __canPlay: function ac___canPlay() {
        if (this.canPlay() === true) {
            return true
        } else {
            if (this.forwards().canPlay() && this.backwards().canPlay()) {
                this.setCanPlay(true);
                this.__publish("canPlay", true);
                return true
            }
        }
        return false
    },
    __doWhenCanPlay: AC.Flow.SharedMethods.__doWhenCanPlay,
    __publish: AC.Flow.SharedMethods.__publish,
    setOptions: AC.Flow.SharedMethods.setOptions
});
AC.Flow.Manifest = AC.Class({
    initialize: function ac_initialize(a) {
        if (!AC.Environment.Feature.supportsCanvas()) {
            return false
        }
        this._diffImageCount = null;
        this._framecount = null;
        this._frames = [];
        this._key = null;
        this._loaded = false;
        this._size = null;
        this._version = null;
        AC.Object.synthesize(this);
        this.__loadManifest(a)
    },
    __loadManifest: function ac___loadManifest(a) {
        if (a.match(/\.png((#|\?).*)?$/)) {
            this.__loadManifestImage(a)
        } else {
            this.__loadManifestJSON(a)
        }
    },
    __loadManifestJSON: function ac___loadManifestJSON(f) {
        var c = this.__parseData.bind(this);
        var a = this;
        f = f.replace(/^https?:\/\/[^\/]+\//i, "/");
        var e = new AC.Ajax.AjaxRequest(f, {
            onSuccess: function b(h) {
                c(h);
                a.__storeBlockLocations.call(a)
            },
            onFailure: function g() {
                throw "Manifest file not found at " + f
            },
            onError: function d() {
                throw "Error loading JSON file at " + f
            }
        });
    },
    __parseData: function ac___parseData(a) {
        if (typeof this.__boundReadFrame !== "function") {
            this.__boundReadFrame = this.__readFrame.bind(this)
        }
        if (!isNaN(a)) {
            this.__setKeyFromPixelData.apply(this, arguments)
        } else {
            if (typeof a === "object" && typeof a.responseJSON === "function") {
                a = a.responseJSON();
                this.__setKeyFromJSONData(a)
            }
        }
        if (typeof this.key() === "object" && typeof this.key().parseData === "function") {
            this.key().parseData.apply(this, arguments)
        }
    },
    __setKeyFromJSONData: function ac___setKeyFromJSONData(a) {
        if (typeof a.version !== "undefined") {
            this.setVersion(a.version)
        } else {
            throw "JSON Manifest requires property ‘version’ to be defined."
        }
        this.setKey(AC.Flow.Manifest.Keys[this.version()])
    },
    __readHeader: function ac___readHeader(a) {
        this.key().parseHeader.call(this, a);
        this.__headerRead = true
    },
    __readFrame: function ac___readFrame(a) {
        this.key().parseFrame.call(this, a)
    },
    __storeBlockLocations: function ac___storeBlockLocations() {
        var c = 0;
        var d = this.frames();
        var a;
        var b;
        for (a = 0; a < d.length; a += 1) {
            for (b = 0; b < d[a].length; b += 1) {
                d[a][b].block = c;
                c += d[a][b].length
            }
        }
    },
    setKey: function ac_setKey(a) {
        if (typeof a === "object" && typeof a.parseData === "function") {
            this._key = a
        } else {
            throw "Manifest Version " + this.version() + " not understood by this version of AC.Flow.Manifest."
        }
    },
    setLoaded: function ac_setLoaded(a) {
        if (this._loaded) {
            throw "Already loaded manifest! Cannot load it twice."
        }
        this._loaded = !! a;
        if (this._loaded) {
            AC.NotificationCenter.publish(AC.Flow.notificationPrefix() + "manifestLoaded", {
                target: this,
                data: this
            }, true)
        }
    }
});
AC.Object.extend(AC.Flow.Manifest.prototype, {
    __loadManifestImage: function ac___loadManifestImage(c) {
        var b = this.__parseData.bind(this);
        var a = this;
        AC.Canvas.imageDataFromFile(c, function (d) {
            a.__pixelCount = d.data.length / 4;
            AC.Canvas.iterateImageData(d, b);
            a.__storeBlockLocations.call(a)
        })
    },
    __setKeyFromPixelData: function ac___setKeyFromPixelData(h, f, c, d, e) {
        if (e === 0) {
            this.setVersion(h);
            this.setKey(AC.Flow.Manifest.Keys[this.version()])
        }
    },
    __readUntilNextMarker: function ac___readUntilNextMarker(a, b) {
        if (!Array.isArray(this.__temporaryData)) {
            this.__temporaryData = []
        }
        if (this.key().isMarker.call(this, a)) {
            b(this.__temporaryData);
            delete this.__temporaryData
        } else {
            this.__temporaryData.push(a)
        }
    }
});
AC.Flow.Manifest.Keys = {};
AC.Flow.Manifest.Keys[2] = {
    parseData: function ac_parseData(b) {
        var a;
        this.__readHeader(b);
        for (a = 0; a < b.frames.length; a += 1) {
            this.__readFrame(b.frames[a])
        }
        this.setLoaded(true)
    },
    parseHeader: function ac_parseHeader(a) {
        this.setFramecount(a.frameCount);
        this.setSize(a.blockSize);
        this.setDiffImageCount(a.imagesRequired)
    },
    parseFrame: function ac_parseFrame(a) {
        var c = [];
        var b;
        for (b = 0; b < a.length; b += 5) {
            c.push({
                location: AC.Flow.createNumberFromBase64Range(a, b, 3),
                length: AC.Flow.createNumberFromBase64Range(a, b + 3, 2)
            })
        }
        this.frames().push(c)
    }
};
AC.Flow.VR = AC.Class({
    __defaultOptions: {
        extension: "jpg",
        autoplay: true,
        autoplayDirection: 1,
        continuous: true,
        scrubbable: true,
        scrubRotateDistance: 1000,
        scrubDirection: -1,
        scrubHeartbeat: 0.04,
        playOnScrubEnd: false,
        throwable: true,
        minThrowDuration: 0.5,
        maxThrowDuration: 1.5,
        stopEventThreshold: 10
    },
    initialize: function ac_initialize(a, c, b) {
        this.setOptions(b);
        this._delegate = {};
        this._container = AC.Element.getElementById(a);
        this._canvas = null;
        this._context = null;
        this._scrubbing = false;
        this._throwing = false;
        this._flow = null;
        AC.Object.synthesize(this);
        if (AC.Environment.Feature.supportsCanvas()) {
            if (this.options().playOnScrubEnd === true) {
                this.options().throwable = false
            }
            if (!AC.Element.isElement(this.container())) {
                throw "Valid Element required for a AC.Flow.VR."
            }
            this.__setupContainer();
            this.__setupFlow(c);
            if (this.options().autoplay === true) {
                this.play({
                    direction: this.options().autoplayDirection,
                    fps: this.options().fps
                })
            } else {
                this.flow().showFrame(this.canvas(), 0, true)
            }
            if (this.options().scrubbable === true) {
                this.__enableScrubbing()
            }
            if (this.options().throwable === true) {
                this.__minThrowFrames = Math.floor(this.options().minThrowDuration * this.options().fps);
                this.__maxThrowFrames = Math.floor(this.options().maxThrowDuration * this.options().fps)
            }
        }
    },
    play: function ac_play(a) {
        if (this.scrubbing() === false) {
            a = typeof a === "object" ? a : {};
            a.fps = !isNaN(a.fps) ? a.fps : this.options().fps;
            a.continuous = typeof a.continuous === "boolean" ? a.continuous : this.options().continuous;
            this.__stopThrowing();
            this.flow().play(this.canvas(), a)
        }
    },
    pause: function ac_pause() {
        this.flow().pause()
    }
});
AC.Object.extend(AC.Flow.VR.prototype, {
    onWillPlay: function ac_onWillPlay(a) {
        this.__publish("willPlay", true)
    },
    onDidPause: function ac_onDidPause(a) {
        this.__publish("didPause", true)
    },
    onDidPlay: function ac_onDidPlay(a) {
        this.__publish("didPlay", true)
    }
});
AC.Object.extend(AC.Flow.VR.prototype, {
    __startHeartbeat: function ac___startHeartbeat() {
        if (typeof this.__boundRunHeartbeat === "undefined") {
            this.__boundRunHeartbeat = this.__runHeartbeat.bind(this)
        }
        this.__heartbeatFunction = null;
        this.__heartbeat = window.setInterval(this.__boundRunHeartbeat, this.options().scrubHeartbeat * 1000)
    },
    __endHeartbeat: function ac___endHeartbeat() {
        window.clearInterval(this.__heartbeat);
        delete this.__heartbeat
    },
    __runOnHeartbeat: function ac___runOnHeartbeat(a) {
        this.__heartbeatFunction = a
    },
    __runHeartbeat: function ac___runHeartbeat() {
        if (typeof this.__heartbeatFunction === "function") {
            this.__heartbeatFunction.call(this)
        }
        this.__heartbeatFunction = null
    }
});
AC.Object.extend(AC.Flow.VR.prototype, {
    __setupFlow: function ac___setupFlow(f) {
        var b;
        var d;
        var e;
        var h = "json";
        var a = "jpg";
        var g = this.options().extension.replace(/^(\.)/, "");
        var c = {};
        if (typeof this.options().fps !== "undefined") {
            c.fps = this.options().fps
        }
        f = (f.match(/(\/)$/)) ? f : f + "/";
        d = new AC.Flow(f + "forwards_###." + g, f + "forwards_manifest." + h, f + "forwards_keyframe." + a, c);
        e = new AC.Flow(f + "backwards_###." + g, f + "backwards_manifest." + h, f + "backwards_keyframe." + a, c);
        this.setFlow(new AC.Flow.BiDirectional(d, e));
        this.flow().setDelegate(this);
        if (typeof this.options().fps === "undefined") {
            this.options().fps = this.flow().forwards().options().fps
        }
    },
    __getRelativeEvent: function ac___getRelativeEvent(a) {
        if (a.touches) {
            if (a.touches.length > 1) {
                return false
            }
            if (a.touches.length) {
                a.clientX = a.touches[0].clientX;
                a.clientY = a.touches[0].clientY
            }
            if (typeof a.clientX === "undefined") {
                a.clientX = this.__onScrubMove.clientX
            }
            if (typeof a.clientY === "undefined") {
                a.clientY = this.__onScrubMove.clientY
            }
        }
        return a
    },
    __showFrameFromEvent: function ac___showFrameFromEvent(a) {
        var b = this.__getScrubFrame(a, this.__onScrubStart.frame, this.__onScrubStart.clientX);
        this.__showFrame(b)
    },
    __showFrame: function ac___showFrame(a) {
        this.flow().showFrame(this.canvas(), a)
    },
    __setupContainer: AC.Flow.SharedMethods.__setupContainer,
    __publish: AC.Flow.SharedMethods.__publish,
    setOptions: AC.Flow.SharedMethods.setOptions
});
AC.Object.extend(AC.Flow.VR.prototype, {
    __enableScrubbing: function ac___enableScrubbing() {
        var b = AC.Function.bindAsEventListener(this.__onScrubStart, this);
        var c = AC.Function.bindAsEventListener(this.__onScrubMove, this);
        var a = AC.Function.bindAsEventListener(this.__onScrubEnd, this);
        AC.Element.addEventListener(this.container(), "touchstart", b);
        AC.Element.addEventListener(window, "touchmove", c);
        AC.Element.addEventListener(window, "touchend", a);
        AC.Element.addEventListener(this.container(), "mousedown", b);
        AC.Element.addEventListener(window, "mousemove", c);
        AC.Element.addEventListener(window, "mouseup", a);
        AC.Element.addClassName(this.container(), "grabbable")
    },
    __onScrubStart: function ac___onScrubStart(a) {
        if (this.options().scrubbable !== true) {
            return false
        }
        if (a.touches && a.touches.length > 1) {
            return false
        }
        if (this.options().stopEventThreshold === false || (!a.touches && !isNaN(this.options().stopEventThreshold))) {
            AC.Event.stop(a)
        } else {
            this.__stoppedEvent = false
        }
        this.__stopThrowing();
        this.__onScrubStart.playing = this.flow().playing();
        this.pause();
        this.__endHeartbeat();
        a = this.__getRelativeEvent(a);
        this.__onScrubStart.clientX = a.clientX;
        this.__onScrubStart.clientY = a.clientY;
        this.__onScrubStart.frame = this.flow().forwards().currentFrame();
        this.__updateScrubHistory(a.clientX);
        this.setScrubbing(true);
        this.__publish("scrubStart", true, [this, [a.clientX, a.clientY]])
    },
    __onScrubMove: function ac___onScrubMove(b) {
        if (this.scrubbing() !== true) {
            return false
        }
        b = this.__getRelativeEvent(b);
        this.__onScrubMove.clientX = b.clientX;
        this.__onScrubMove.clientY = b.clientY;
        if (!isNaN(this.options().stopEventThreshold) && Math.abs(this.__onScrubStart.clientX - this.__onScrubMove.clientX) >= this.options().stopEventThreshold) {
            AC.Event.stop(b);
            this.__stoppedEvent = true
        }
        this.__updateScrubHistory(b.clientX);
        var a = function () {
            AC.Flow.SharedMethods.benchmarkStart();
            this.__showFrameFromEvent(b);
            this.__publish("scrubMove", true, this.flow().forwards().currentFrame())
        }.bind(this);
        if (this.options().scrubHeartbeat && !isNaN(this.options().scrubHeartbeat)) {
            if (typeof this.__heartbeat === "undefined") {
                this.__startHeartbeat();
                a()
            } else {
                this.__runOnHeartbeat(a)
            }
        } else {
            window.requestAnimationFrame(a)
        }
    },
    __onScrubEnd: function ac___onScrubEnd(a) {
        if (this.scrubbing() !== true) {
            return false
        }
        a = this.__getRelativeEvent(a);
        if (this.options().scrubHeartbeat && !isNaN(this.options().scrubHeartbeat)) {
            this.__endHeartbeat()
        }
        this.setScrubbing(false);
        if (this.__stoppedEvent === false || this.options().playOnScrubEnd === true) {
            this.flow().play(this.canvas())
        } else {
            if (this.options().throwable === true) {
                this.__throw(a.clientX)
            }
        }
        AC.Flow.SharedMethods.benchmarkEnd();
        this.__publish("scrubEnd", true, [this, [a.clientX, a.clientY]])
    },
    __getScrubFrame: function ac___getScrubFrame(b, d, e) {
        var a = b.clientX - e;
        var g = a / this.options().scrubRotateDistance;
        var c = Math.round((this.flow().forwards().framecount() - 1) * g);
        var f = d + (c * this.options().scrubDirection);
        while (f < 0) {
            if (this.options().continuous === false) {
                f = 0
            } else {
                f += this.flow().forwards().framecount()
            }
        }
        while (f >= this.flow().forwards().framecount()) {
            if (this.options().continuous === false) {
                f = this.flow().forwards().framecount() - 1
            } else {
                f -= this.flow().forwards().framecount()
            }
        }
        return f
    },
    __updateScrubHistory: function ac___updateScrubHistory(a) {
        if (typeof this.__scrubHistory === "undefined") {
            this.__scrubHistory = []
        }
        this.__scrubHistory.unshift(a);
        if (this.__scrubHistory.length > 3) {
            this.__scrubHistory.splice(3)
        }
    },
    setScrubbing: function ac_setScrubbing(a) {
        this._scrubbing = a;
        if (a === true) {
            AC.Element.addClassName(document.body, "grabbing")
        } else {
            AC.Element.removeClassName(document.body, "grabbing")
        }
    }
});
AC.Object.extend(AC.Flow.VR.prototype, {
    __throw: function ac___throw(e) {
        if (!Array.isArray(this.__scrubHistory)) {
            return
        }
        var d = this.__scrubHistory[this.__scrubHistory.length - 1];
        var a = e - d;
        var h = Math.floor(a / 5);
        var b;
        var c;
        var f;
        var g;
        if (a) {
            if (h < this.__minThrowFrames) {
                h = this.__minThrowFrames
            } else {
                if (h > this.__maxThrowFrames) {
                    h = this.__maxThrowFrames
                }
            }
            this.__throwSequence = [];
            for (b = 0; b < h; b += 1) {
                c = b / h;
                f = Math.pow(c - 1, 2);
                d = Math.floor(f * a) + d;
                g = this.__getScrubFrame({
                    clientX: d
                }, this.__onScrubStart.frame, this.__onScrubStart.clientX);
                if (this.__throwSequence.length && g === this.__throwSequence[this.__throwSequence.length - 2]) {
                    break
                }
                this.__throwSequence.push(g)
            }
            this.setThrowing(true);
            this.__publish("willThrow", true, this.__throwSequence);
            this.__throwStep()
        }
    },
    __throwStep: function ac___throwStep() {
        if (!this.throwing()) {
            return
        }
        this.__throwStepTimer = new Date();
        if (typeof this.__boundThrowStep === "undefined") {
            this.__boundThrowStep = this.__throwStep.bind(this)
        }
        AC.Flow.SharedMethods.benchmarkStart();
        this.__showFrame(this.__throwSequence.shift());
        this.__publish("didThrowStep", true, this.__throwSequence);
        if (this.__throwSequence.length) {
            window.setTimeout(this.__boundThrowStep, Math.max((1000 / this.options().fps) - (new Date() - this.__throwStepTimer), 10))
        } else {
            AC.Flow.SharedMethods.benchmarkEnd();
            this.__stopThrowing()
        }
    },
    __stopThrowing: function ac___stopThrowing() {
        if (!this.throwing()) {
            return
        }
        this.setThrowing(false);
        this.__publish("didThrow", true);
        delete this.__scrubHistory
    }
});