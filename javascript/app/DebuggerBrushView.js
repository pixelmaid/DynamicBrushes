//Debugger Brush View


define(["jquery", "handlebars", "app/DebuggerView"],

	function($, Handlebars, DebuggerView) {


		var DebuggerBrushView = class extends DebuggerView {

			constructor(model, element, template, groupName, keyHandler) {
				super(model, element, template, groupName, keyHandler);
				this.keyHandler = keyHandler;
				this.pastConstraint = null;
				this.keyHandler.addListener("VIZ_BRUSH_STEP_THROUGH", function() {
					let currentConstraint = this.model.brushVizQueue.shift();
					this.visualizeStepThrough(currentConstraint, this.pastConstraint, model.data);
					this.pastConstraint = currentConstraint;
				}.bind(this));

				this.model.collection.addListener("VIZ_BRUSH_STEP_THROUGH", function() {
					// console.log("~~~~ !!! called brush step through in main");
					let currentConstraint = this.model.brushVizQueue.shift();
					this.visualizeStepThrough(currentConstraint, this.pastConstraint, model.data);
					this.pastConstraint = currentConstraint;
				}.bind(this));
			}


			dataUpdatedHandler() {
				super.dataUpdatedHandler();
			}

			// setupHighlighting(data) {
			// 	if ($('#param-dx').length) {
			// 		$('#param-dx')[0].previousElementSibling.id = 'param-posy';
			// 		$('#param-posy')[0].previousElementSibling.id = 'param-posx';					
			// 	}
			// 	this.setUpHighlightClicks('brush');
			// 	for (var i = 0; i < this.model.collection.getCurrHighlighted().length; i++) {
		 //          // console.log("~ rehighlighting ", self.model.collection.getCurrHighlighted()[i]);
		 //          this.highlightParamRow(this.model.collection.getCurrHighlighted()[i]);

		 //        }    
			// }

			visualizeStepThrough(constraint, pastConstraint, data) {

				if (!$("#brush-toggle").is(":checked")) { return; }


				console.log("! visualizing constraints ", data, " past constraint ", pastConstraint);
				var arrowObject;
				if (pastConstraint) {
					switch (pastConstraint.type) {
						case "method":
							$("#" + pastConstraint.methodId).removeClass("method-inspect");
							break;
						case "binding":
							$("#" + pastConstraint.constraintId).removeClass("debug");
							$("#param-" + pastConstraint.relativePropertyName).removeClass("debug-inspect");
							break;
						case "transition":
							if (pastConstraint.transitionId == "start") {
								$(".setup").children().eq(1).removeClass("start-highlight");
							} else if ($("#" + pastConstraint.transitionId).hasClass("transition_statement")) {
								$("#" + pastConstraint.transitionId).children().first().removeClass("method-inspect");
							} else { //it's a state
								$("#" + pastConstraint.transitionId).children().eq(1).removeClass("active");
							}
							//remove arrow highlight                     
							arrowObject = $("#" + pastConstraint.transitionId).parent().prev();
							arrowObject.children().eq(1).attr("stroke", "#efac1f");
							arrowObject.children().eq(2).attr("stroke", "#efac1f");
							arrowObject.children().eq(2).attr("fill", "#efac1f");
							break;
					}
				}

				switch (constraint.type) {
					case "method":
						console.log("!!VIZ METHOD ", constraint);
						$("#" + constraint.methodId).addClass("method-inspect");
						break;
					case "binding":
						console.log("binding name ", constraint.relativePropertyName, constraint);
						var name = constraint.relativePropertyName;
						$("#" + constraint.constraintId).addClass("debug");
						$("#param-" + constraint.relativePropertyName).addClass("debug-inspect");
						// console.log("data is ", this.model.data);
						$("#" + data.currentState).children(".state").addClass("active");

						let id = constraint.relativePropertyName;


						break;
					case "transition":
						console.log("!!VIZ TRANSITION ", constraint, pastConstraint);
						if (constraint.transitionId == "start") {
							$(".setup").children().eq(1).addClass("start-highlight");
						}
						if ($("#" + constraint.transitionId).hasClass("transition_statement")) {
							//outline header
							$("#" + constraint.transitionId).children().first().addClass("method-inspect");
						} else { //it's a state
							$("#" + constraint.transitionId).children().eq(1).addClass("active");
						}
						//add arrow highlight                     
						arrowObject = $("#" + constraint.transitionId).parent().prev();
						arrowObject.children().eq(1).attr("stroke", "#00ff00");
						arrowObject.children().eq(2).attr("stroke", "#00ff00");
						arrowObject.children().eq(2).attr("fill", "#00ff00");
						break;
				}

			}



		};

		return DebuggerBrushView;
	});