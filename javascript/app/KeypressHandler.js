//Keypress

"use strict";

define(["app/Emitter"],

	function(Emitter) {


		var KeypressHandler = class extends Emitter {

			constructor(model) {
				super();
       			this.model = model;
      			var self = this;

				document.onkeyup = function(e) {

					if (e.keyCode == 39) {
			          console.log("~~~~  next pressed, brush queue is ", this.model.brushVizQueue);
	            	  self.model.collection.terminateInspectorInterval();
	            	  self.model.collection.inspectorDataInterval();
					}
				}.bind(this);
			}

		};

		return KeypressHandler;


	});