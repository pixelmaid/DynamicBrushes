//Debugger

"use strict";

define(["app/Emitter"],

	function(Emitter){


		var Debugger = class extends Emitter{


			constructor(){
				super();
				this.pastConstraint = null;
				this.vizQueue = [];
                document.onkeyup = function(e) {
                
                    if(e.keyCode == 39){
                    	if(this.vizQueue.length === 0){
                       		this.trigger("STEP_FORWARD");
                       	}
                       	else{
                       		let currentConstraint = this.vizQueue.pop();
                       		this.visualizeConstraint(currentConstraint,this.pastConstraint);
                       		this.pastConstraint = currentConstraint;
                       	}

                    }
                }.bind(this);
			}

			processInspectorData(data){
				switch (data.type){

                    case "DRAW_SEGMENT":
                       this.visualizeDrawSegment(data);
                    break;

                    case "STATE_TRANSITION":

                    break;

                }
			}


			visualizeDrawSegment(data){
				let brushState = data["brushState"];
				$("#" + data.prevState).children(".state").removeClass("active");
				$("#" + data.currentState).children(".state").addClass("active");
				for (var c in data.constraints){
					if(data.constraints.hasOwnProperty(c)){
						let constraint = {constraintId: c, name: data.constraints[c], value:brushState[data.constraints[c]] };
						this.vizQueue.push(constraint);
					}
				}

			}

			visualizeConstraint(constraint,pastConstraint){
				if(pastConstraint){
					$("#" + pastConstraint.constraintId).removeClass("debug");

				}
				$("#" + constraint.constraintId).addClass("debug");

				/*   addInspector(target) {
                var inspectorModel = new InspectorModel(this.id, target.attr("id"));
                var el = inspectorModel.view.el;
                target.hover(
                    function() {
                        var position = $(this).offset();
                        el.css({
                            left: position.left,
                            top: position.top + 30,
                            visibility: "visible"
                        });
                    },
                    function() {

                        el.css({
                            visibility: "hidden"
                        });

                    });
            }*/
			}

		};

		return Debugger;


	});