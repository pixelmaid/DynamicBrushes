/*SignalUtils.js
 *basic signal processing functions
 */
define([], function() {
	function SignalUtils() {

	}

	SignalUtils.prototype.map_range = function(value, low1, high1, low2, high2) {
		return low2 + (high2 - low2) * (value - low1) / (high1 - low1);
	};


SignalUtils.prototype.cartToPolar = function(p1, p2) {

			var r = 0;
			var theta = 0;
			var x = p2.x - p1.x;
			var y = p2.y - p1.y;
			r = Math.sqrt((x * x) + (y * y));

			var type = 0;
			if (x > 0 && y >= 0) {
				type = 1;
			}
			if (x > 0 && y < 0) {
				type = 2;
			}
			if (x < 0) {
				type = 3;
			}
			if (x === 0 && y > 0) {
				type = 4;
			}
			if (x === 0 && y < 0) {
				type = 5;
			}
			if (x === 0 && y === 0) {
				type = 6;
			}

			//Find theta
			switch (type) {
				case (1):
					theta = Math.atan(y / x);
					break;
				case (2):
					theta = (Math.atan(y / x) + 2 * Math.PI);
					break;
				case (3):
					theta = (Math.atan(y / x) + Math.PI);
					break;
				case (4):
					theta = (Math.PI / 2.0);
					break;
				case (5):
					theta = ((3 * Math.PI) / 2.0);
					break;
				case (6):
					theta = 0.0;
					break;
				default:
					theta = 0.0;
					break;
			}

			return {
				rad: r,
				theta: theta,
				type: type
			};

		};

		SignalUtils.prototype.polarToCart = function(r, theta) {
			var x = Math.cos(theta * (Math.PI / 180.0)) * r;
			var y = Math.sin(theta * (Math.PI / 180.0)) * r;


			return {
				x: x,
				y: y
			};
		};


	SignalUtils.prototype.mapToSignal = function(p, spine_a, length_a, length_b, data) {
		var d = spine_a.getOffsetOf(p);
		var x = this.map_range(d, 0, length_a, 0, length_b);
		var a1, a2, p1, p2;
		for (var i = 0; i < data.length - 1; i++) {
			if (x >= data[i].x && x < data[i + 1].x) {
				p1 = data[i];
				p2 = data[i + 1];
				var dx = p2.x - p1.x;
				var d1 = x - p1.x;
				var d2 = p2.x - x;
				a1 = d1 / dx;
				a1 = d1 / dx;
				a2 = d2 / dx;
				break;
			}
		}


		if (!p2) {
			return data[data.length - 1].y;
		}
		var mapped_value = (a1) * p1.y + (a2) * p2.y;
		//console.log('mapped val',mapped_value,'p1',p1.y,'p2',p2.y);
		return mapped_value;
	};

	SignalUtils.prototype.simple_moving_averager = function(period) {
		var nums = [];
		return function(num) {
			nums.push(num);
			if (nums.length > period) {
				nums.splice(0, 1); // remove the first element of the array
			}
			var sum = 0;
			for (var i = 0; i < nums.length; i++) {
				sum += nums[i];
			}
			var n = period;
			if (nums.length < period) {
				n = nums.length;
			}
			return (sum / n);
		};
	};

	SignalUtils.prototype.calculateInflectionPoints = function(dataset) {
		var der = [];
		var inflections = [];
		inflections.push(dataset[0]);
		for (var i = 1; i < dataset.length; i++) {
			var x_t = dataset[i].y;
			var x_t_1 = dataset[i - 1].y;
			var delta_t = dataset[i].x - dataset[i - 1].x;
			var y_t = (x_t - x_t_1) / delta_t;
			der.push(y_t);
			if (i > 1) {
				var y_t_1 = der[i - 2];
				if (y_t === 0) {

				} else {
					if (y_t < 0 && y_t_1 >= 0) {
						inflections.push(dataset[i]);

					} else if (y_t > 0 && y_t_1 <= 0) {
						inflections.push(dataset[i]);

					} 

				}

			}
		}
		inflections.push(dataset[dataset.length - 1]);
		return inflections;
	};

	return SignalUtils;
});