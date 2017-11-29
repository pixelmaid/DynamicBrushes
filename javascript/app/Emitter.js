'use strict';
define(['emitter'],

	function(EventEmitter) {


		var Emitter = class {

			constructor() {
				this.emitter = new EventEmitter();
				this.emitter.parent = this;

			}

			addListener(name, listener) {
				this.emitter.addListener(name, listener);
			}

			trigger(eventName, args){

				//console.log('trigger called',eventName,args, this.emitter.parent,this.emitter.getListeners());
				this.emitter.trigger(eventName, args);
			}

		};
		return Emitter;

	});