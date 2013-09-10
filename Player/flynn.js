/* 
 * Flynn Player
 * 
 * Copyright 2013 Mess, all rights reserved.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 * 
 * Made by Mess - http://thisismess.com/
 */
 
(function($){
  
  function base64ValueForCharAt(c, a) {
    var b = c.charCodeAt(a);
    if(b > 64 && b < 91)  return b - 65;
    if(b > 96 && b < 123) return b - 71;
    if(b > 47 && b < 58)  return b + 4;
    if(b === 43) return 62;
    if(b === 47) return 63;
    throw "Invalid Bas64 character: " + c.charAt(a);
  };
  
  function base64DecodeValue(e, a, d) {
    var c = 0;
    var b;
    while(d--) {
      b = base64ValueForCharAt(e, a++);
      c += (b << d * 6);
    }
    return c;
  };
  
  $.fn.flynn = function(options){ 
    return this.each(function(){
      var ref = this;
      var temp;
      
      // default options
      ref.options = $.extend({
        'fps': 30, 'loop': false, 'autoplay': true, 'delay': 0
      }, options);
      
      // take options from the container element
      if((temp = $(ref).attr('fps')) != null) ref.options.fps = Number(temp);
      if((temp = $(ref).attr('loop')) != null) ref.options.loop = true;
      if((temp = $(ref).attr('autoplay')) != null) ref.options.autoplay = true;
      if((temp = $(ref).attr('delay')) != null) ref.options.delay = Number(temp);
      
      // initialize all counters to 0
      ref.current_frame = 0;
      ref.keyframe_width = 0;
      ref.keyframe_height = 0;
      ref.keyframe_image = null;
      ref.current_sequence = 0;
      ref.current_source = 0;
      ref.canvas = null;
      ref.actual_canvas = null;
      ref.actual_debug = null;
      
      ref.frames = [];
      ref.images = [];
      ref.image_count = null;
      ref.images_loaded = 0;
      ref.debug  = false;
      
      ref.timeout = null;
      ref.source = null;
      
      // source info storage
      ref.source_position = 0;
      ref.source_offset   = 0;
      
      // Files we care about
      ref.manifest = null;
      ref.animation_base = $(ref).attr('base');
      ref.animation_name = $(ref).attr('name');
      ref.manifest_file = ref.animation_base +"/"+ ref.animation_name +"_manifest.json";
      ref.image_directory = ref.animation_base;
      
      // Scale factor
      ref.scale = $(ref).attr('scale')
      ref.scale = (ref.scale != null) ? Math.floor(Number(ref.scale)) : 1;
      
      /**
       * Obtain the name of a frame with the specified index
       */
      ref.streamImageNameForIndex = function(prefix, index, type) {
        index += 1; // base 1
        if(index < 10)   return prefix +"_00"+ index +"."+ type;
        if(index < 100)  return prefix +"_0"+ index +"."+ type;
        else             return prefix +"_"+ index +"."+ type;
      }
      
      /**
       * Initialize the canvas into which we'll draw our animation frames. If scaling is required
       * we set it up in the graphics context here.
       */
      ref.setup_canvas = function() {
        ref.canvas = $('<canvas></canvas>').appendTo(ref).attr({'width':parseInt($(ref).width(), 10), 'height':parseInt($(ref).height(), 10)});
        ref.actual_canvas = ref.canvas[0];
        if(ref.scale != null && ref.scale != 1) ref.actual_canvas.getContext("2d").scale(ref.scale, ref.scale);
      };
      
      /**
       * Setup our debugging canvas. This displays a visual representation of the annimation which
       * can be useful when debugging the Flynn player.
       */
      ref.setup_debug_canvas = function() {
        ref.debug = $('<canvas class="debug"></canvas>').appendTo(ref).attr({'width':ref.source.width, 'height':ref.source.height}).css("background", "#00ff00");
        ref.actual_debug = ref.debug[0];
        if(ref.scale != null && ref.scale != 1) ref.actual_debug.getContext("2d").scale(ref.scale, ref.scale);
      };
      
      ref.load_manifest = function() {
        $.getJSON(ref.manifest_file, function(data){
          ref.manifest = data;
          ref.parse_header();
        });
      };
      
      ref.parse_header = function() {
        if (ref.manifest === null) throw("No manifest loaded");
        ref.frames = ref.manifest.frames;
        ref.block_size = ref.manifest.blockSize;
        ref.image_count = ref.manifest.imagesRequired;
        ref.images_loaded = 0;
        ref.images = new Array(ref.image_count);
        ref.load_frames();
      };
      
      ref.load_frames = function() {
        if (ref.image_directory === undefined || ref.image_directory === null) throw("No image directory set.");
        for(var i = 0; i < ref.manifest.imagesRequired; i++){
          var src = ref.image_directory +'/'+ ref.streamImageNameForIndex(ref.animation_name, i, ref.manifest.format);
          $(new Image()).attr('src', src).load(function(){
            var sour = $(this).attr('src');
            var frame = parseInt(sour.split('/').slice(-1)[0].split('.').slice(0)[0].split('_').slice(-1)[0], 10) - 1;
            ref.images[frame] = this;
            ref.images_loaded++;
            if(ref.images_loaded >= ref.manifest.imagesRequired && ref.options.autoplay === true) ref.start();
          });
        }
      };
      
      ref.start = function() {
        var src = ref.image_directory +'/'+ ref.animation_name +'_keyframe.'+ ref.manifest.format;
        $(new Image()).attr('src', src).load(function(){
          var context = ref.actual_canvas.getContext("2d");
          context.drawImage(this, 0, 0, this.width, this.height);
          ref.keyframe_width = this.width;
          ref.keyframe_height = this.height;
          ref.keyframe_image = this;
          ref.source = ref.images[ref.current_source];
          ref.play(ref.options.delay);
        });
      };
      
      ref.play = function(initial_delay) {
        ref.delay = 1.0 / ref.options.fps * 1000.0;
        ref.timeout = window.setTimeout(ref.next_frame, ref.delay + ((initial_delay != null) ? Number(initial_delay) : 0));
      };
      
      ref.update_frame = function(sequence) {
        var position = sequence.position;
        var count = sequence.count;
        var srcWidth = ref.source.width;
        var context = ref.actual_canvas.getContext("2d");
        var srcUpperBound = ref.source_offset + (ref.source.width * ref.source.width / ref.block_size / ref.block_size);
        
        while(count > 0){
          
          // compute our update geometry
          var srcOrigin = ref.originForPosition(ref.source_position - ref.source_offset, srcWidth);
          var dstOrigin = ref.originForPosition(position, ref.keyframe_width);
          var strip = Math.min(Math.min(count, (ref.keyframe_width - dstOrigin.x) / ref.block_size), (ref.source.width - srcOrigin.x) / ref.block_size);
          var dstFrame = { x: Math.round(dstOrigin.x), y: Math.round(dstOrigin.y), width: Math.round(strip * ref.block_size), height: Math.round(ref.block_size) };
          
          // clear and update the block strip
          context.clearRect(dstFrame.x, dstFrame.y, dstFrame.width, dstFrame.height);
          context.drawImage(ref.source, srcOrigin.x, srcOrigin.y, strip * ref.block_size, ref.block_size, dstFrame.x, dstFrame.y, dstFrame.width, dstFrame.height);
          
          // increment the destintation position and count
          position += strip;
          count -= strip;
          
          // if we've copied the last block in the image, swap to the next one
          if((ref.source_position += strip) >= srcUpperBound){
            ref.current_source++;
            ref.source = ref.images[ref.current_source];
            ref.source_offset = srcUpperBound - 1;
            srcUpperBound = ref.source_offset + (ref.source.width * ref.source.width / ref.block_size / ref.block_size);
            srcWidth = ref.source.width;
          }
          
        }
        
      };
      
      ref.originForPosition = function(position, width) {
        var wblocks = width / ref.block_size;
        return { x: (position % wblocks) * ref.block_size, y: Math.floor(position / wblocks) * ref.block_size };
      };
      
      ref.loop = function() {
        var context = ref.actual_canvas.getContext("2d");
        context.clearRect(0, 0, ref.actual_canvas.width, ref.actual_canvas.height);
        context.drawImage(ref.keyframe_image, 0, 0, ref.keyframe_image.width, ref.keyframe_image.height);
        ref.current_source = 0;
        ref.source = ref.images[ref.current_source];
        ref.source_position = 0;
        ref.source_offset = 0;
        ref.current_frame = 0;
      }
      
      ref.next_frame = function() {
        
        // obtain the next frame
        var frame = ref.frames[ref.current_frame];
        // for each copy operation in the frame, process the update blocks
        for(i = 0; i <= frame.length - 5; i += 5){
          ref.update_frame({'position':base64DecodeValue(frame, i, 3), 'count':base64DecodeValue(frame, i + 3, 2)});
        }
        
        // increment our frame count and set the timeout for the next frame
        var hasframes;
        if((hasframes = (++ref.current_frame < ref.frames.length)) || ref.options.loop){
          ref.timeout = window.setTimeout(ref.next_frame, ref.delay);
        }
        
        // if we're out of frames, either loop or stop
        if(!hasframes){
          if(ref.options.loop){
            $(ref).trigger("animationWillLoop");
            ref.loop();
          }else{
            $(ref).trigger("animationDidFinish");
          }
        }
        
      };
      
      if(ref.options.autoplay) ref.setup_canvas();
      if(ref.options.autoplay) ref.load_manifest();
      
    });
  };
  
})(jQuery);