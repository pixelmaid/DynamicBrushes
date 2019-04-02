//Keypress

"use strict";

define(["app/Emitter"],

	function(Emitter) {


		var KeypressHandler = class extends Emitter {

			constructor(model) {
				super();
        this.model = model;

				document.onkeyup = function(e) {

					if (e.keyCode == 39) {
            console.log("~~~~  next pressed, brush queue is ", this.model.brushVizQueue);
            if (this.model.brushVizQueue.length === 0) {
              this.trigger("STEP_FORWARD");
            } else {
              this.trigger("VIZ_BRUSH_STEP_THROUGH");
            }
					}
				}.bind(this);
			}

		};

		return KeypressHandler;


	});