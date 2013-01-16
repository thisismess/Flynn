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
			ele.current_block = 0;
			ele.current_sequence = 0;
			ele.current_source = 0;
			ele.current_source_row = 0;
			ele.current_source_img = 0;
			ele.canvas = null;
			ele.frames = [];
			ele.pixels = [];
			ele.images = [];
			ele.debug  = false;
			ele.timeout = null;
			ele.source = null;
			ele.started = new Date();
			ele.delay = Math.max((ele.options.fps/1000) - (new Date() - ele.started), 10);

			// X/Y storage
			ele.source_x = 0;
			ele.source_y = 0;

			// Files we care about
			ele.manifest 		= null;
			ele.manifest_file   = $(ele).attr('data-manifest');
			ele.image_directory = $(ele).attr('data-frame-directory');

			ele.setup_canvas = function()
			{
				ele.canvas = $('<canvas></canvas>').appendTo(ele).attr({'width':parseInt($(ele).width(), 10), 'height':parseInt($(ele).height(), 10)});
			};

			ele.setup_debug_canvas = function()
			{
				ele.debug = $('<canvas class="debug"></canvas>').appendTo(ele).attr({'width':ele.source.width, 'height':ele.source.height});
				ele.debug.drawImage({ source:ele.source, x:0, y:0, width:ele.source.width, height:ele.source.height, fromCenter: false });

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
				ele.load_frames();
			};


			ele.load_frames = function()
			{
				if (ele.image_directory === undefined || ele.image_directory === null) throw("No image directory set.");

				for(var i = 0; i < ele.manifest.imagesRequired; i++)
				{
					var src = ele.image_directory + (i+1) + '.png';
					$(new Image()).attr('src', src).load(function(){
						ele.images.push(this);
						if (ele.images.length >= ele.manifest.imagesRequired && ele.options.autoplay === true) ele.start();
					});
				}
			};

			ele.start = function()
			{
				var src = ele.image_directory + 'keyframe.png';
				$(new Image()).attr('src', src).load(function(){
					ele.canvas.drawImage({ source: this, x:0, y:0, width:this.width, height:this.height, fromCenter:false });
					ele.keyframe_width = this.width;
					ele.source = ele.images[ele.current_source];
					ele.setup_debug_canvas();
					ele.play();
				});
			};

			ele.play = function()
			{
				ele.timeout = window.setTimeout(ele.next_frame, (ele.options.fps/1000));
			};

			ele.parse_frame = function(frame)
			{

			};

			ele.load_sequence = function(sequence)
			{
				var blocks_to_read = sequence.length;
				var coords = ele.translate_origin(sequence.position, ele.keyframe_width);
				var seq = {};
				var y = ele.source_y;
				var x = ele.source_x;

				while(blocks_to_read > 0)
				{
					var width = (blocks_to_read * ele.block_size);

					if ((ele.source_x + width) <= ele.source.width)
					{
						blocks_we_can_read = blocks_to_read;
					}
					else
					{
						blocks_we_can_read = (ele.source.width - ele.source_x) / ele.block_size;
						width = (blocks_we_can_read * ele.block_size);
					}
					
					var seq = { source:ele.source, x:coords.x * ele.block_size, y:coords.y * ele.block_size, sw:width, sh:ele.block_size, sx:ele.source_x, sy:ele.source_y };
					ele.draw_sequence(seq);
					blocks_to_read -= blocks_we_can_read;

					if (blocks_to_read === 0)
					{	
						ele.source_x += width;
					}
					else
					{
						ele.source_x = 0;
						ele.source_y += ele.block_size;
					}
				}
			};

			ele.translate_origin = function(position, width)
			{
				var wblocks = width / ele.block_size;
				return { x: position % wblocks, y: Math.floor(position / wblocks) };
			};

			ele.draw_sequence = function(seq)
			{
				ele.canvas.clearCanvas({ x:seq.x, y:seq.y, width:seq.sw, height:seq.sh, fromCenter:false });
				ele.canvas.drawImage({ source:seq.source, x:seq.x, y:seq.y, width:seq.sw, height:seq.sh, sWidth:seq.sw, sHeight:seq.sh, sx:seq.sx, sy:seq.sw, fromCenter:false });
			};

			ele.next_frame = function()
			{
				var frame = ele.frames[ele.current_frame];
				// Copy that floppy
				for(i = 0; i <= frame.length - 5; i += 5)
				{
					sequence = {'length':base64DecodeValue(frame, i + 3, 2), 'position':base64DecodeValue(frame, i, 3)};
					ele.load_sequence(sequence);
				}
				// Advance to the next frame. It's fun!
				ele.delay = 1000/ele.options.fps;
				if (++ele.current_frame < ele.frames.length) ele.timeout = window.setTimeout(ele.next_frame, ele.delay);
			};

			ele.next_sequence = function()
			{

			};

			if (ele.options.autoplay) ele.setup_canvas();
			if (ele.options.autoplay) ele.load_manifest();

		});
	};

})(jQuery);