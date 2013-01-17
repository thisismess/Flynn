(function($){
  
  function lpad(value, padding)
  {
      var zeroes = "0";
      for (var i = 0; i < padding; i++) { zeroes += "0"; }
      return (zeroes + value).slice(padding * -1);
  };
  
  function base64ValueForCharAt(c, a) 
  {
    var b = c.charCodeAt(a);
    if(b > 64 && b < 91)  return b - 65;
    if(b > 96 && b < 123) return b - 71;
    if(b > 47 && b < 58)  return b + 4;
    if(b === 43) return 62;
    if(b === 47) return 63;
    throw "Invalid Bas64 character: " + c.charAt(a);
  };
  
  function base64DecodeValue(e, a, d) 
  {
    var c = 0;
    var b;
    while(d--)
    {
      b = base64ValueForCharAt(e, a++);
      c += (b << d * 6);
    }
    return c;
  };
  
  $.fn.spellcaster = function(options){ 
    
    return this.each(function(){
      
      var ele = this;
      
      // Defaults
      ele.options = $.extend({
        'fps': 24,
        'loop': false,
        'continous': false,
        'autoplay': true,
      }, options);
      
      // Set all counters to 0
      ele.current_frame = 0;
      ele.keyframe_width = 0;
      ele.keyframe_height = 0;
      ele.current_sequence = 0;
      ele.current_source = 0;
      ele.canvas = null;
      ele.actual_canvas = null;
      ele.actual_debug = null;
      
      ele.frames = [];
      ele.images = [];
      ele.image_count = null;
      ele.images_loaded = 0;
      ele.debug  = false;
      
      ele.timeout = null;
      ele.source = null;
      ele.started = new Date();
      ele.delay = Math.max((ele.options.fps/1000) - (new Date() - ele.started), 10);
      
      // source info storage
      ele.source_position = 0;
      ele.source_offset   = 0;
      
      // Files we care about
      ele.manifest 		= null;
      ele.manifest_file   = $(ele).attr('data-manifest');
      ele.image_directory = $(ele).attr('data-frame-directory');
      
      // Scale factor
      ele.scale = $(ele).attr('scale')
      if(ele.scale != null) ele.scale = parseInt(ele.scale);
      
      /**
       * Obtain the name of a frame with the specified index
       */
      ele.streamImageNameForIndex = function(prefix, index, type) {
        index += 1; // base 1
        if(index < 10)   return prefix +"_00"+ index +"."+ type;
        if(index < 100)  return prefix +"_0"+ index +"."+ type;
        else             return prefix +"_"+ index +"."+ type;
      }
      
      ele.setup_canvas = function()
      {
        ele.canvas = $('<canvas></canvas>').appendTo(ele).attr({'width':parseInt($(ele).width(), 10), 'height':parseInt($(ele).height(), 10)});
        ele.actual_canvas = ele.canvas[0];
        if(ele.scale != null) ele.actual_canvas.getContext("2d").scale(ele.scale, ele.scale);
      };
      
      ele.setup_debug_canvas = function()
      {
        ele.debug = $('<canvas class="debug"></canvas>').appendTo(ele).attr({'width':ele.source.width, 'height':ele.source.height}).css("background", "#00ff00");
        ele.actual_debug = ele.debug[0];
      };
      
      ele.load_manifest = function()
      {
        $.getJSON(ele.manifest_file, function(data){
          ele.manifest = data;
          ele.parse_header();
        });
      };
      
      ele.parse_header = function()
      {
        if (ele.manifest === null) throw("No manifest loaded");
        ele.frames = ele.manifest.frames;
        ele.block_size = ele.manifest.blockSize;
        ele.image_count = ele.manifest.imagesRequired;
        ele.images_loaded = 0;
        ele.images = new Array(ele.image_count);
        ele.load_frames();
      };
      
      ele.load_frames = function()
      {
        if (ele.image_directory === undefined || ele.image_directory === null) throw("No image directory set.");
        for(var i = 0; i < ele.manifest.imagesRequired; i++)
        {
          var src = ele.image_directory + ele.streamImageNameForIndex('spellcaster', i, 'png');
          $(new Image()).attr('src', src).load(function(){
            var sour = $(this).attr('src');
            var frame = parseInt(sour.split('/').slice(-1)[0].split('.').slice(0)[0].split('_').slice(-1)[0], 10) - 1;
            ele.images[frame] = this;
            ele.images_loaded++;
            if(ele.images_loaded >= ele.manifest.imagesRequired && ele.options.autoplay === true) ele.start();
          });
        }
      };
      
      ele.start = function()
      {
        var src = ele.image_directory + 'spellcaster_keyframe.png';
        $(new Image()).attr('src', src).load(function(){
          var context = ele.actual_canvas.getContext("2d");
          context.drawImage(this, 0, 0, this.width, this.height);
          ele.keyframe_width = this.width;
          ele.keyframe_height = this.height;
          ele.source = ele.images[ele.current_source];
          ele.play();
        });
      };
      
      ele.play = function() {
        ele.timeout = window.setTimeout(ele.next_frame, (ele.options.fps / 1000.0));
      };
      
      ele.update_frame = function(sequence) {
        var position = sequence.position;
        var count = sequence.count;
        var srcWidth = ele.source.width;
        var context = ele.actual_canvas.getContext("2d");
        var srcUpperBound = ele.source_offset + (ele.source.width * ele.source.width / ele.block_size / ele.block_size);
        
        while(count > 0){
          
          // compute our update geometry
          var srcOrigin = ele.originForPosition(ele.source_position - ele.source_offset, srcWidth);
          var dstOrigin = ele.originForPosition(position, ele.keyframe_width);
          var strip = Math.min(count, (ele.source.width - srcOrigin.x) / ele.block_size);
          
          // clear and update the block strip
          context.clearRect(dstOrigin.x, dstOrigin.y, strip * ele.block_size, ele.block_size);
          context.drawImage(ele.source, srcOrigin.x, srcOrigin.y, strip * ele.block_size, ele.block_size, dstOrigin.x, dstOrigin.y, strip * ele.block_size, ele.block_size);
          
          // increment the destintation position and count
          position += strip;
          count -= strip;
          
          // if we've copied the last block in the image, swap to the next one
          if((ele.source_position += strip) >= srcUpperBound){
            ele.current_source++;
            ele.source = ele.images[ele.current_source];
            ele.source_offset = srcUpperBound;
            srcUpperBound = ele.source_offset + (ele.source.width * ele.source.width / ele.block_size / ele.block_size);
            srcWidth = ele.source.width;
            console.log("NEXT: "+ ele.current_source);
          }
          
        }
        
      };
      
      ele.originForPosition = function(position, width) {
        var wblocks = width / ele.block_size;
        return { x: (position % wblocks) * ele.block_size, y: Math.floor(position / wblocks) * ele.block_size };
      };
      
      ele.next_frame = function() {
        
        var frame = ele.frames[ele.current_frame];
        for(i = 0; i <= frame.length - 5; i += 5){
          ele.update_frame({'position':base64DecodeValue(frame, i, 3), 'count':base64DecodeValue(frame, i + 3, 2)});
        }
        
        ele.delay = 1000 / ele.options.fps;
        
        if(++ele.current_frame < ele.frames.length){
          ele.timeout = window.setTimeout(ele.next_frame, ele.delay);
        }
        
      };
      
      if (ele.options.autoplay) ele.setup_canvas();
      if (ele.options.autoplay) ele.load_manifest();
      
    });
  };
  
})(jQuery);