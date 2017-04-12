//ConditionalLines.js
'use strict';
define(["svg", "jquery"],
	function(svg, $, BaseChart) {
		var ConditionalLines = function() {
			this.rect = null; //svg rectangle
			this.selectionUIs = null;
			this.draw = null; //svg.js drawing object
			this.rectX1 = 0;
			this.rectY1 = 0;
			this.rectX2 = 100;
			this.rectY2 = 100;
			this.target = null;
			this.name = "line";



		};


		ConditionalLines.prototype.render = function() {
			var self = this;
			if (!this.rect) {
				this.draw = svg(this.target.attr("id")).size(this.width, this.height);
				this.rect = this.draw.rect(1, 1).attr({
					fill: '#f06',
					opacity: 0.5
				});
				this.selectionUI = this.draw.group();
				var c0 = this.draw.rect(5, 5).attr({
					fill: 'white',
					stroke: 'blue'
				}).id("c1").mousedown(function() {
					this.attr("class", "selected");
				});
				var c1 = c0.clone().id("c2").mousedown(function() {
					this.attr("class", "selected");
				});
				var c2 = c0.clone().id("c3").mousedown(function() {
					this.attr("class", "selected");
				});
				var c3 = c0.clone().id("c4").mousedown(function() {
					this.attr("class", "selected");
				});
				this.selectionUI.add(c0).add(c1).add(c2).add(c3);
				$(document).mousemove(function(data) {
					var x = self.parent.inverseXScale()(data.offsetX);
					var y = self.parent.inverseYScale()(data.offsetY);

					if (c0.attr("class") == "selected"){
						self.rectX1 = x;
						self.rectY1 = y;
						self.render();
					}
					else if (c1.attr("class") == "selected"){
						self.rectX1=x;
						self.rectY2=y;
						self.render();
					}
					else if (c2.attr("class") == "selected"){
						self.rectX2=x;
						self.rectY2=y;
						self.render();
					}
					else if (c3.attr("class") == "selected"){
						self.rectX2=x;
						self.rectY1=y;
						self.render();
					}
				});

				$(document).mouseup(function() {
					self.selectionUI.each(function(i, children) {
						this.attr("class", "");
					});
				});
			}

			var x = this.parent.xScale()(this.rectX1);
			var y = this.parent.yScale()(this.rectY1);
			var x2 =this.parent.xScale()(this.rectX2);
			var y2 =this.parent.yScale()(this.rectY2);
			var width =  x2-x;
			var height = y2-y;
			console.log("rect dimensions: x1=",this.rectX1,"x2=",this.rectX2,"y1=",this.rectY1,"y2=",this.rectY2);

			console.log("screen dimensions: x1=",x,"x2=",x2,"y1=",y,"y2=",y2,"width=",width,"height=",height,"\n============================\n\n");
			

		
			this.rect.size(width, height)
				.x(x)
				.y(y);
			this.selectionUI.children()[0].cx(x).cy(y);
			this.selectionUI.children()[1].cx(x).cy(y2);
			this.selectionUI.children()[2].cx(x2).cy(y2);
			this.selectionUI.children()[3].cx(x2).cy(y);


		};

		ConditionalLines.prototype.setRectDimensions = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.rectX1 = this.parent.inverseXScale()(value.x);
			this.rectY1 = this.parent.inverseYScale()(value.y);

			this.rectX2 = this.parent.inverseXScale()(value.x+value.width);

			this.rectY2 = this.parent.inverseYScale()(value.y+value.height);

			return this;
		};

		ConditionalLines.prototype.setTarget = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.target = value;
			return this;
		};

		ConditionalLines.prototype.setWidth = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.width = value;
			return this;
		};

		ConditionalLines.prototype.setHeight = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.height = value;
			return this;
		};


		ConditionalLines.prototype.setX = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.x = value;
			return this;
		};

		ConditionalLines.prototype.setY = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.y = value;
			return this;
		};

		return ConditionalLines;

	});