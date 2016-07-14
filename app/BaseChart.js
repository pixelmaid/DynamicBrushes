//BaseChart.js
'use strict';
define(["d3"],
	function(d3) {
		var BaseChart = function() {
			this.width = 100;
			this.height = 100;
			this.children = [];
			this.data = [];
			this.target = d3.select("body");
			this.x = 0;
			this.y = 0;
			this.type = "svg";
			this.xDomain = [0, 100];
			this.yDomain = [0, 100];
			this.container = null;
			this.yMargin = 20;
			this.xMargin = 20;
			this.parent = null;
			this.clipPath = null;
			this.id = this.guid();



		};

		BaseChart.prototype.guid = function() {
			function s4() {
				return Math.floor((1 + Math.random()) * 0x10000)
					.toString(16)
					.substring(1);
			}
			return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
				s4() + '-' + s4() + s4() + s4();
		};



		BaseChart.prototype.xAxisTranslation = function() {
			return [this.xMargin, this.height];
		};
		BaseChart.prototype.yAxisTranslation = function() {
			return [this.xMargin, 0];
		};

		BaseChart.prototype.xValue = function(d) {
			return d.x;
		};

		BaseChart.prototype.yValue = function(d) {
			return d.y;
		};

		BaseChart.prototype.xMap = function(target) {
			return function(d) {
				return target.xScale()(target.xValue(d));
			};

		};

		BaseChart.prototype.xAxis = function() {
			var xAxis = d3.svg.axis()
				.scale(this.xScale())
				.orient("bottom");
			return xAxis;
		};

		BaseChart.prototype.yAxis = function() {

			var yAxis = d3.svg.axis()
				.scale(this.yScale())
				.ticks(0)
				.orient("left");

			return yAxis;
		};


		BaseChart.prototype.yMap = function(target) {
			return function(d) {
				return target.yScale()(target.yValue(d));
			};

		};

		BaseChart.prototype.xScale = function() {
			return d3.scale.linear()
				.domain(this.xDomain)
				.range([0, this.width - this.xMargin]);
		};

		BaseChart.prototype.yScale = function() {
			return d3.scale.linear()
				.domain(this.yDomain)
				.range([this.height,this.yMargin]);
		};

		BaseChart.prototype.addChild = function(data) {
			console.log('data for children', data);
			if (Array.isArray(data)) {
				this.data = data;
				for (var i = 0; i < data.length; i++) {
					if (data[i]) {
						this.addSingleChild(data[i]);
					} else {
						console.log('no data for data set index', i);
					}
				}

			} else {
				this.addSingleChild(data);
			}
			return this;
		};

		BaseChart.prototype.calculateMin = function(data, prop) {
			var min = data.reduce(function(pv, cv) {
				var currentMin = cv.reduce(function(pv, cv) {
					return Math.min(pv, cv[prop]);
				}, 100);
				return Math.min(pv, currentMin);
			}, 100);
			return min;
		};

		BaseChart.prototype.calculateMax = function(data, prop) {
			var max = data.reduce(function(pv, cv) {
				var currentMax = cv.reduce(function(pv, cv) {
					return Math.max(pv, cv[prop]);
				}, 0);
				return Math.max(pv, currentMax);
			}, 0);
			return max;
		};

		BaseChart.prototype.addSingleChild = function(data) {
			var child = BaseChart().data(data);
			child.parent = this;
			this.children.push(child);
			return this;

		};

		BaseChart.prototype.generate = function() {
			this.container = this.target.append(this.type)
				.attr("width", this.width + this.xMargin)
				.attr("height", this.height + this.yMargin)
				.attr("transform", "translate(" + this.x + "," + this.y + ")");
			
			this.clipPath = this.container.append("clipPath") // define a clip path
				.attr("id", "clip"+this.id); // give the clipPath an ID
			this.clipPath.append("rect") // shape it as an ellipse
				.attr("x", this.xMargin)
				.attr("y", this.yMargin)
				.attr("width", this.width - this.xMargin)
				.attr("height", this.height - this.yMargin);

		};

		BaseChart.prototype.generateChildren = function() {
			var graphGroup = this.container.append("g");
        graphGroup.attr("clip-path", "url(#clip"+this.id+")"); // clip the rectangle

			for (var i = 0; i < this.children.length; i++) {
				this.children[i].setTarget(graphGroup).generate();
			}
		};

		BaseChart.prototype.render = function() {
			this.container
				.transition().duration(500).ease("sin-in-out")
				.attr("width", this.width + this.xMargin)
				.attr("height", this.height + this.xMargin)
				.attr("transform", "translate(" + this.x + "," + this.y + ")");
			this.renderAxes();

			this.renderChildren();


			this.container.selectAll("#clip")
				.transition().duration(500).ease("sin-in-out")
				.attr("width", this.width - this.xMargin)
				.attr("height", this.height - this.yMargin);



		};

		BaseChart.prototype.renderAxes = function() {
			var self = this;
			// if no axis exists, create one, otherwise update it
			var yAxes = this.container.selectAll(".y.axis").filter(function() {
				return this.parentNode === self.container.node();
			});
			if (yAxes[0].length < 1) {
				this.container.append("g")
					.attr("class", "y axis")
					.attr("transform", "translate(" + this.yAxisTranslation()[0] + "," + this.yAxisTranslation()[1] + ")")

				.call(this.yAxis());
			} else {
				yAxes
					.transition().duration(500).ease("sin-in-out")
					.attr("transform", "translate(" + this.yAxisTranslation()[0] + "," + this.yAxisTranslation()[1] + ")")

				.call(this.yAxis());
			}

			var xAxes = this.container.selectAll(".x.axis").filter(function() {
				return this.parentNode === self.container.node();
			});
			// if no axis exists, create one, otherwise update it
			var xTrans = this.xAxisTranslation();

			if (xAxes[0].length < 1) {
				this.container.append("g")
					.attr("class", "x axis")
					.attr("transform", "translate(" + xTrans[0] + "," + xTrans[1] + ")")
					.call(this.xAxis());
			} else {

				xAxes.transition().duration(500).ease("sin-in-out")
					.attr("transform", "translate(" + xTrans[0] + "," + xTrans[1] + ")")
					.call(this.xAxis());
			}


		};


		BaseChart.prototype.renderChildren = function() {
			for (var i = 0; i < this.children.length; i++) {
				this.children[i].render();
			}
		};


		BaseChart.prototype.setWidth = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.width = value;
			return this;
		};

		BaseChart.prototype.setHeight = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.height = value;
			return this;
		};


		BaseChart.prototype.setX = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.x = value;
			return this;
		};

		BaseChart.prototype.setY = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.y = value;
			return this;
		};

		BaseChart.prototype.setData = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.data = value;
			return this;
		};

		BaseChart.prototype.setType = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.type = value;
			return this;
		};

		BaseChart.prototype.setTarget = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.target = value;
			return this;
		};

		BaseChart.prototype.setYDomain = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.yDomain = value;
			return this;
		};

		BaseChart.prototype.setXDomain = function(value) {
			if (!arguments.length) {
				return this;
			}
			this.xDomain = value;
			return this;
		};


		return BaseChart;

	});