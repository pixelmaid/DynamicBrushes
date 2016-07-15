//PositionChart.js
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
			this.yMargin = 0;
			this.xMargin= 0;
			this.formerHeight = 0;


		};

		PositionChart.prototype = new BaseChart();

		PositionChart.prototype.constructor = PositionChart;


		PositionChart.prototype.generate = function() {
			BaseChart.prototype.generate.call(this);

			var self = this;

			this.container.on('mouseenter', function() {
				self.formerHeight = self.height;
				self.setWidth(200).setHeight(150).setY(self.parent.yMargin).render();
				self.target.node().appendChild(self.container.node());


			});
			this.container.on('mouseleave', function() {
				self.setWidth(75).setHeight(56.5).setY(self.parent.yMargin+self.parent.height/2-self.formerHeight/2).render();
			});

		};


		// if no axis exists, create one, otherwise update it

		PositionChart.prototype.render = function() {
			var self = this;
			this.container
				.transition().duration(500)
				.attr("width", this.width)
				.attr("height", this.height)
				.attr("transform", "translate(" + (this.x-this.width/2) + "," + this.y + ")");



			if (this.container.selectAll("#background")[0].length < 1) {
				this.container.append("rect")
				.attr("id","background")
					.attr("width", this.width)
					.attr("height", this.height)
					.attr("fill", "white")
					.attr("stroke", "black");
			} else {
				this.container.selectAll("#background")
					.transition().duration(500)
					.attr("width", this.width)
					.attr("height", this.height);

			}

			this.renderAxes();



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
			} else {
				var dots = this.container.selectAll(".dot")
					.transition().duration(500)
					.attr("cx", self.xMap(self))
					.attr("cy", self.yMap(self))
					.attr("r", function(d, i) {
						if (i == self.data.length - 1) {
							return self.xScale()(45);
						}
						return self.xScale()(25);

					});

			}

		};

		PositionChart.prototype.xMap = function(target) {
			return function(d) {
				var s = target.xValue(d);
				var m = target.xScale()(s);
				return target.xScale()(s);
			};

		};

		PositionChart.prototype.yScale = function() {
			return d3.scale.linear()
				.domain(this.yDomain)
				.range([this.yMargin,this.height]);
		};


		PositionChart.prototype.xAxis = function() {
			var xAxis = d3.svg.axis()
				.scale(this.xScale())
				.orient("bottom")
				.innerTickSize(-this.height)
				.outerTickSize(0)
				.ticks(19)
				.tickFormat("");
			return xAxis;
		};

		PositionChart.prototype.yAxis = function() {

			var yAxis = d3.svg.axis()
				.scale(this.yScale())
				.orient("left")
				.innerTickSize(-this.width)
				.outerTickSize(0)
				.ticks(4)
				.tickFormat("");
			return yAxis;
		};

PositionChart.prototype.xAxisTranslation = function(){
			return [0, this.height];
		};
		

		return PositionChart;

	});