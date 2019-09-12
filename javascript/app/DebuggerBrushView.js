//Debugger Brush View


define(["jquery", "handlebars", "app/DebuggerView"],

	function($, Handlebars, DebuggerView) {


		var DebuggerBrushView = class extends DebuggerView {

			constructor(model, element, template, groupName, keyHandler) {
				super(model, element, template, groupName, keyHandler);
				this.keyHandler = keyHandler;
				this.pastConstraint = null;
				this.stateHighlighted = false;
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

				this.model.collection.addListener("CLEAR_STEP_HIGHLIGHT", function() {
					// console.log("~~~~ !!! called brush step through in main");
					this.clearStepHighlight();
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

			clearStepHighlight() {
				//assuming last one is alpha
				$("#param-alpha").removeClass("debug-inspect");
				//go through state mappings
				$(".mappings").each(function(i) {
                        $(".mappings").children().each(function(i) {
                            if ($(this).hasClass("debug")){
                                $(this).removeClass("debug");
                            }
                        });
                    });
				//remove state highlight 
				$(".state").each(function (i) {
					if ($(this).hasClass("active")){
                        $(this).removeClass("active");
                    }
				})
			}

			removeStateHighlight(pastConstraint) {
				$("#" + pastConstraint.transitionId).children().eq(1).removeClass("active");
			}


			removeMethodHighlight(pastConstraint) {
				if (pastConstraint.type == method) {
					$("#" + pastConstraint.methodId).removeClass("method-inspect");

				} else {
					$("#" + pastConstraint.transitionId).children().first().removeClass("method-inspect");
				}
			}

			visualizeStepThrough(constraint, pastConstraint, data) {
				var self = this;
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
								$("#" + pastConstraint.transitionId).parent().removeClass("transition-front");
							} else { //it's a state
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

						if (pastConstraint) {
							if (pastConstraint.type == "transition") {
								console.log("~~~ REMOVING METHOD !", constraint);
								// self.removeMethodHighlight(constraint);
								self.removeStateHighlight(constraint);
								return;
							}
						}
						break;
					case "binding":
						// console.log("binding name ", constraint.relativePropertyName, constraint);
						var name = constraint.relativePropertyName;
						$("#" + constraint.constraintId).addClass("debug");
						$("#param-" + constraint.relativePropertyName).addClass("debug-inspect");
						// console.log("data is ", this.model.data);
						// $("#" + data.currentState).children(".state").addClass("active");
						// console.log("~~ parent is ", $("#" + constraint.constraintId).parentElement);
						$("#" + constraint.constraintId).parent().parent().parent().addClass("active");
						// console.log("~~ curr state is ", $("#data.currentState").children(".state"), data.currentState );

						let id = constraint.relativePropertyName;


						break;
					case "transition":
						console.log("!!VIZ TRANSITION ", constraint, pastConstraint);

						if (pastConstraint) {
							if (pastConstraint.type == "binding" && self.stateHighlighted == true) {
								console.log("~~~ REMOVING TRANS !", constraint);
								// self.removeMethodHighlight(constraint);
								self.removeStateHighlight(constraint);
								self.stateHighlighted = false;
								return;
							}
						}
						if (constraint.transitionId == "start") {
							$(".setup").children().eq(1).addClass("start-highlight");
						}
						if ($("#" + constraint.transitionId).hasClass("transition_statement")) {
							//outline header
							console.log("~highlight header")
							$("#" + constraint.transitionId).children().first().addClass("method-inspect");
							//bring to front also 
							$("#" + constraint.transitionId).parent().addClass("transition-front");
							self.stateHighlighted = true;
						} else { //it's a state
							console.log("~highlight state")
							$("#" + constraint.transitionId).children().eq(1).addClass("active");
							self.stateHighlighted = true;
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