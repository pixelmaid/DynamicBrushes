//AngleChart.js
'use strict';
define(["d3", "app/BaseChart", "app/SignalProcessUtils", "app/ConditionalCircle"],
	function(d3, BaseChart, SignalUtils, ConditionalCircle) {
		var AngleChart = function() {
			BaseChart.call(this);
			this.type = "g";
			this.xDomain = [0, 360];
			this.width = 50;
			this.height = 50;
			this.conditionType = ConditionalCircle;

			console.log("angle condition type",this.conditionType);


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
				.transition().duration(500)
				.attr("width", this.width)
				.attr("height", this.height)
				.attr("transform", "translate(" + this.x + "," + (this.y + this.height / 2) + ")");
			var circles = this.container.selectAll("circle").filter(function() {
				return this.parentNode === self.container.node();
			});
			if (circles[0].length < 1) {
				this.container.append("circle")
					.attr("r", this.width / 2)
					.attr("fill", "white")
					.attr("stroke", "black");
			} else {
				circles
					.transition().duration(500)
					.attr("r", this.width / 2);

			}
			console.log("p2 =", this.data);
			var p2 = new SignalUtils().polarToCart(this.width / 2, this.data[0].x);

			if (this.container.selectAll("line")[0].length < 1) {
				this.container.append("line")
					.attr("x1", 0)
					.attr("y1", 0)
					.attr("x2", p2.x)
					.attr("y2", p2.y)
					.attr("stroke-width", 2)
					.attr("stroke", "black");

			} else {
				this.container.selectAll("line")
					.transition().duration(500)
					.attr("x2", p2.x)
					.attr("y2", p2.y);

			}

			if (this.container.selectAll(".condGroup")[0].length < 1) {

				for (var i = 0; i < this.conditions.length; i++) {
					var condGroup = this.container.append("g")
						.attr("class", "condGroup")
						.attr("id", "cond_" + this.id);
					this.conditions[i].setTarget(condGroup)
						.setWidth(this.width)
						.setHeight(this.height);
				}
			}
			for (var j = 0; j < this.conditions.length; j++) {
				console.log("rendering condition",this.conditions[j].name);
				this.conditions[j].render();
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