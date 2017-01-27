'use strict';
define(['emitter'],

	function(EventEmitter) {


		var Model = class {

			constructor() {
				this.emitter = new EventEmitter();
				this.emitter.parent = this;

			}

			addListener(name, listener) {
				this.emitter.addListener(name, listener);
			}

		};
		return Model;

	});