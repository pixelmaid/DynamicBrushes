//BrushDebuggerModel

"use strict";

define(["app/DebuggerModel"],

	function(DebuggerModel) {


		var BrushDebuggerModel = class extends DebuggerModel {


			constructor(collection) {
				super(collection);

				this.brushVizQueue = [];
				this.dataVizQueue = [];
				this.stepThroughOn = true;
				this.toClearViz = false;
			}

			update(data){
			   let oldData = this.data;
			   this.data = data;

			   if(this.collection.chartViewManager.currentView){
			  	 let currentBehaviorId = this.collection.chartViewManager.currentView.id;
			  	 let selectedIndex = this.collection.selectedIndex;

			  	 let targetBehaviorData = data.behaviors[currentBehaviorId];
			  	 let targetBrushData = targetBehaviorData.brushes[selectedIndex];

			  	 if (this.stepThroughOn) {
			  	  this.processStepData(targetBrushData);
			  	  if (this.collection.manualSteppingOn) {
				  	  this.dataVizQueue.push(data);
				  	  this.data = oldData;			  	  	
			  	  }
			  	 } 
			  	 
			  	 
			  	 
			  	}
			  	//combine data all at once using dataVizQueue?

			  	this.trigger("DATA_UPDATED");

			}



			processStepData (data) {

				switch (data.event) {
					case "DRAW_SEGMENT":

						//this.trigger("ON_VIZ_DRAW_SEGMENT",[data]);
						this.visualizeDrawSegment(data);
						break;

					case "STATE_TRANSITION":
						//this.trigger("ON_STATE_TRANSITION",[data]);
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
					//START HERE!!!!!!!!
					//data.constraints[i].value = brushState[data.constraints[i].constraintId];
					this.brushVizQueue.push(data.constraints[i]);
				}
				this.toClearViz = true;
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


		return BrushDebuggerModel;


	});