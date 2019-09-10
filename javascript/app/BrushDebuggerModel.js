//BrushDebuggerModel

"use strict";

define(["app/DebuggerModel"],

	function(DebuggerModel) {


		var BrushDebuggerModel = class extends DebuggerModel {


			constructor(collection) {
				super();

				this.brushVizQueue = [];

			}

			processInspectorData(data) {

				console.log("! data type is ", data.type);
				console.log("! data is ", data);
				this.updateBrushData(data.brushState);
				switch (data.type) {
					case "DRAW_SEGMENT":

						//this.trigger("ON_VIZ_DRAW_SEGMENT",[data]);
						this.visualizeDrawSegment(data);
						break;

					case "STATE_TRANSITION":
						//this.trigger("ON_STATE_TRANSITION",[data]);
						console.log("! calling display transition");
						this.displayTransition(data);
						break;

				}
			}


			visualizeDrawSegment(data) {
				console.log("! visualizing draw segment ", data, " brush queue is ", this.brushVizQueue);
				let brushState = data["brushState"];
				// $("#" + data.prevState).children(".state").removeClass("active");
				// $("#" + data.currentState).children(".state").addClass("active");
				for (var i = 0; i < data.constraints.length; i++) {
					data.constraints[i].type = "binding";
					data.constraints[i].value = brushState[data.constraints[i].constraintId];
					this.brushVizQueue.push(data.constraints[i]);
				}
			}

			displayTransition(data) {
				console.log("! displaying transition of ", data, "brush queue is ", this.brushVizQueue);
				//add type
				this.brushVizQueue.push({
					transitionId: data.prevState,
					type: "transition"
				});
				this.brushVizQueue.push({
					transitionId: data.transitionId,
					type: "transition"
				});
				for (var i = 0; i < data.methods.length; i++) {
					data.methods[i].type = "method";
					this.brushVizQueue.push(data.methods[i]);
				}

				console.log("! now brush queue is ", this.brushVizQueue);

			}


		};


		return DebuggerModel;


	});