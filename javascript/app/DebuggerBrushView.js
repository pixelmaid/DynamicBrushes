//Debugger Brush View


define(["jquery", "handlebars", "app/DebuggerView"],

	function($, Handlebars, DebuggerView) {


		var DebuggerBrushView = class extends DebuggerView {

			constructor(model, modelCollection, element, template, groupName, keyHandler) {
				super(model, modelCollection, element, template, groupName, keyHandler);
				this.keyHandler = keyHandler;

				this.keyHandler.addListener("VIZ_BRUSH_STEP_THROUGH", function() {
					console.log("! called brush step through");
					let currentConstraint = this.model.brushVizQueue.shift();
					this.visualizeStepThrough(currentConstraint, this.pastConstraint, model.data);
					this.pastConstraint = currentConstraint;
				}.bind(this));
			}


			dataUpdatedHandler(){
				super.dataUpdatedHandler();
			}

			

		};

		return DebuggerBrushView;
	});