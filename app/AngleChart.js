//AngleChart.js
'use strict';
define(["d3", "app/BaseChart", "app/SignalProcessUtils"],
	function(d3, BaseChart, SignalUtils) {
		var AngleChart = function() {
			BaseChart.call(this);
			this.type = "g";
			this.xDomain = [0, 360];
			this.width = 50;
			this.height = 50;


		};

		AngleChart.prototype = new BaseChart();

		AngleChart.prototype.constructor = AngleChart;


		AngleChart.prototype.generate = function() {
			BaseChart.prototype.generate.call(this);

			var self = this;

		};


		// if no axis exists, create one, otherwise update it

		AngleChart.prototype.render = function() {
			var self = this;
			this.container
				.transition().duration(500).ease("sin-in-out")
				.attr("width", this.width)
				.attr("height", this.height)
				.attr("transform", "translate(" + this.x + "," + (this.y + this.height / 2) + ")");

			if (this.container.selectAll("circle")[0].length < 1) {
				this.container.append("circle")
					.attr("r", this.width / 2)
					.attr("fill", "white")
					.attr("stroke", "black");
			} else {
				this.container.selectAll("circle")
					.transition().duration(500).ease("sin-in-out")
					.attr("r", this.width / 2);

			}
				console.log("p2 =",this.data);
		var p2 = new SignalUtils().polarToCart(this.width/2,this.data[0].x);

			if (this.container.selectAll("line")[0].length < 1) {
				this.container.append("line")
					.attr("x1", 0)
					.attr("y1",0)
					.attr("x2", p2.x)
					.attr("y2", p2.y)
					.attr("stroke-width", 2)
					.attr("stroke", "black");

			}
			else{
				this.container.selectAll("line")
				.transition().duration(500).ease("sin-in-out")
				.attr("x2", p2.x)
				.attr("y2", p2.y);

			}

		};

		AngleChart.prototype.xMap = function(target) {
			return function(d) {
				var s = target.xValue(d);
				var m = target.xScale()(s);
				return target.xScale()(s);
			};

		};



		return AngleChart;

	});