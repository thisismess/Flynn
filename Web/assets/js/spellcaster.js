var Spellcaster = AC.Class({
    
    initialize: function(d, f, e)
    {
        if (AC.Environment.Feature.supportsCanvas()) {
            this._element = $(d);
            this._mask = null;
            this._showOnScroll = null;
            this._flow = null;
            AC.Synthesize.synthesize(this);
            this.setup(f, e)
        }
    },

    setup: function(f, d) 
    {
        if (AC.Detector.isiPad()) {
            if (typeof AC.Detector.isiPadWithGyro() !== "boolean") {
                var e = this;
                window.setTimeout(function() {
                    e.setup.apply(e, [f, d])
                }, 20)
            } else {
                if (AC.Detector.isiPadWithGyro() === true) {
                    this.__setup(f, d)
                }
            }
        } else {
            this.__setup(f, d)
        }
    },

    __setup: function(j, k) 
    {
        if (AC.Detector.iOSVersion() && AC.Detector.iOSVersion() < 5) {
            return false
        }
        var h;
        var l = "p";
        var i = "ng";
        var g = "son";
        this.setMask(new Element("div"));
        this.mask().setAttribute("data-hires", "false");
        Element.addClassName(this.mask(), "mask");
        Element.insert(this.element(), this.mask());
        h = new AC.Flow.Ambient(this.mask(), j + k + "_###.png", j + k + "_manifest.json", j + k + "_keyframe.png", {autoplay: true, endState: j + k + "_endframe.png",fps: 1, continuous:true});
        this.setFlow(h);
        this.flow().setDelegate(this);
    },

    enhance: function(h) 
    {
        AC.Element.addClassName(h, "enhanced");
        var e = h.down("img").src;
        var g = function() {
            h.setStyle("background-image:url(" + e + ")")
        };
        var f = new Image();
        f.onload = g;
        f.src = e
    },

    visitorEngaged: function() 
    {
        //this.showOnScroll().stopObserving();
        this.flow().play()
    },

    onWillPlay: function() 
    {
        this.flow().play();  
    }

});