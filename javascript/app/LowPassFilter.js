/*LowPassFilter.js
* exponential, n-dimensional low pass filter
*/
'use strict';

define([], function() {


	function LowPassFilter(filterFactor, gain, n_dimensions) {
		this.filterFactor = filterFactor;
		this.gain = gain;
		this.n_dimensions = n_dimensions;
		this.processedData = [];
		this.yy = [];
		this.yy.length = n_dimensions;
		for (var i = 0; i < this.yy.length; i++) {
			this.yy[i] = 0;
		}
	}

	LowPassFilter.prototype.filter = function(x) {
		var y = this._filter([x]);
		if (y.length === 0) {
			return 0;
		}
		return y[0];
	};

	LowPassFilter.prototype._filter = function(x) {
		if (x.length != this.n_dimensions) {
			console.log('the number of input dimensions does not match the input');
			return;
		}

		for (var n = 0; n < this.n_dimensions; n++) {

			this.processedData[n] = ((this.yy[n] * this.filterFactor) + (1.0 - this.filterFactor) * x[n]) * this.gain;
			this.yy[n] = this.processedData[n];
		}
		return this.processedData;
	};

	return LowPassFilter;
});