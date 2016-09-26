//ConditionalCircle.js
'use strict';
define(["svg", "jquery", "app/SignalProcessUtils", "app/ConditionalLines"],
	function(svg, $, SignalUtils, ConditionalLines) {
		var signalUtils = new SignalUtils();
		var ConditionalCircle = function() {
			ConditionalLines.call(this);
			this.circle = null; //svg circle
			this.name = "circle";
			this.a1 = 0;
			this.a2 = 0;
		};

		ConditionalCircle.prototype = new ConditionalLines();

		ConditionalCircle.prototype.constructor = ConditionalCircle;

		ConditionalCircle.prototype.render = function() {
			var self = this;
			
			if (!this.circle) {
				console.log("rendering cond circle")
				var r = this.width / 2;
				this.draw = svg(this.target.attr("id"))
					.size(this.width+10, this.height+10)
					.x(-r)
					.y(-RegExp());

				var p1 = signalUtils.polarToCart(r, this.a1);
				var p2 = signalUtils.polarToCart(r, this.a2);


				//this.circle = this.draw.path("M"+p1.x+" " +p1.y+" A "+r+" "+r+", 0, 1, 1, "+p2.x+" "+p2.y+", L "+this.width/2+" "+this.height/2+" Z ")
				this.circle = this.draw.path("M50 25 A 25 25, 0, 1, 0, 25 50 L 25 25 Z")
					.attr({
						fill: '#f06',
						opacity: 0.5
					});
				this.selectionUI = this.draw.group();
				var c1 = this.draw.circle(5).cx(50).cy(25).fill("white").stroke("blue");
				var c1 = this.draw.circle(5).cx(25).cy(50).fill("white").stroke("blue");
			}
		};

		return ConditionalCircle;
	});