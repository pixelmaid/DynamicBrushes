//PositionSeries.js
'use strict';
define(["d3", "app/BaseChart"],
	function(d3, BaseChart) {
		var PositionChart = function() {
			BaseChart.call(this);
			this.type = "g";
			this.xDomain = [0, 1366];
			this.yDomain = [0, 1024];
			this.width = 75;
			this.height = 56.5;


		};

		PositionChart.prototype = new BaseChart();

		PositionChart.prototype.constructor = PositionChart;


		PositionChart.prototype.generate = function() {
			BaseChart.prototype.generate.call(this);

			var self = this;

			this.container.on('mouseenter', function() {
				self.setWidth(200).setHeight(150).render();
				self.target.node().appendChild(self.container.node());


			});
			this.container.on('mouseleave', function() {
				self.setWidth(75).setHeight(56.5).render();
			});

		};


		// if no axis exists, create one, otherwise update it

		PositionChart.prototype.render = function() {
			var self = this;
			this.container
				.transition().duration(1000).ease("sin-in-out")
				.attr("width", this.width)
				.attr("height", this.height)
				.attr("transform", "translate(" + this.x + "," + this.y + ")");

			var xAxis = d3.svg.axis()
				.scale(this.xScale())
				.orient("bottom")
				.innerTickSize(-this.height)
				.outerTickSize(0)
				.ticks(19)
				.tickFormat("");


			var yAxis = d3.svg.axis()
				.scale(this.yScale())
				.orient("left")
				.innerTickSize(-this.width)
				.outerTickSize(0)
				.ticks(14)
				.tickFormat("");
			if (this.container.selectAll("rect")[0].length < 1) {
				this.container.append("rect")
					.attr("width", this.width)
					.attr("height", this.height)
					.attr("fill", "white")
					.attr("stroke", "black");
			} else {
				this.container.selectAll("rect")
					.transition().duration(1000).ease("sin-in-out")
					.attr("width", this.width)
					.attr("height", this.height);

			}

			// if no axis exists, create one, otherwise update it
			if (this.container.selectAll(".y.axis")[0].length < 1) {
				this.container.append("g")
					.attr("class", "y axis")
					.call(yAxis);
			} else {
				this.container.selectAll(".y.axis")
					.transition().duration(1000).ease("sin-in-out")
					.call(yAxis);
			}


			// if no axis exists, create one, otherwise update it
			if (this.container.selectAll(".x.axis")[0].length < 1) {
				this.container.append("g")
					.attr("class", "x axis")
					.attr("transform", "translate(0," + this.height + ")")
					.call(xAxis);
			} else {
				this.container.selectAll(".x.axis")
					.transition().duration(1000).ease("sin-in-out")
					.attr("transform", "translate(0," + this.height + ")")
					.call(xAxis);
			}


			//if (dots[0].length < 1) {
		if (this.container.selectAll(".dot")[0].length < 1) {
				this.container.selectAll(".dot").data(this.data)
				.enter().append("circle")
				.attr("class", "dot")
					.attr("r", function(d, i) {
						if (i == self.data.length - 1) {
							return 2.5;
						} else {
							return 1;
						}
					})
					.attr("cx", self.xMap(self))
					.attr("cy", self.yMap(self))

				.style("fill", function(d, i) {
					if (i == self.data.length - 1) {
						return "rgb(255,0,0)";
					} else {
						return "rgb(255,192,192)";
					}

				});
			}
			else{
				var dots = this.container.selectAll(".dot")
				.transition().duration(1000).ease("sin-in-out")
				.attr("cx", self.xMap(self))
				.attr("cy", self.yMap(self))
				.attr("r", self.xScale()(25));

			}

		};

		PositionChart.prototype.xMap = function(target) {
			return function(d) {
				var s = target.xValue(d);
				var m = target.xScale()(s);
				return target.xScale()(s);
			};

		};



		return PositionChart;

	});