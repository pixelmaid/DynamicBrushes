//Debugger

"use strict";

define(["app/Emitter"],

	function(Emitter){


		var Debugger = class extends Emitter{


			constructor(){
				super();
				this.pastConstraint = null;
        this.lastTransitionId = null;
        this.inspectorInit = false;
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

      initInspector() {
        console.log("adding inspector");
        var inspectorHTML = '<div id="brush-inspector" class="w jsplumb-draggable jsplumb-droppable ui-droppable">' +
        '<ul style="padding:0 10px 0 10px;">' +
        '<li id="param-x">position x: <span id="inspector-x-pos">x</span></li>' +
        '<li id="param-y">position y: <span id="inspector-y-pos">x</span></li>' +
        '<li id="param-sX">scale x: <span id="inspector-x-scale">x</span></li>' +
        '<li id="param-sY">scale y: <span id="inspector-y-scale">x</span></li>' +
        '<li id="param-r">rotation: <span id="inspector-rot">x</span></li>' +
         '<li id="param-d">diameter: <span id="inspector-diameter">x</span></li>' +
        '<li id="param-a">alpha: <span id="inspector-alpha">x</span></li>' +
        '<li id="param-h">hue: <span id="inspector-hue">x</span></li>' +
        '<li id="param-s">saturation: <span id="inspector-sat">x</span></li>' +
        '<li id="param-lV">level: <span id="inspector-val">x</span></li>' +
        '<li id="param-l">lightness: <span id="inspector-lightness">x</span></li>' +
        '</ul>' +
        '</div>'
        $('#canvas').append(inspectorHTML);
      }

			processInspectorData(data){
        console.log("data type is ", data.type);
        console.log("data is ", data);
        this.updateInspector(data);
				switch (data.type){
                    case "DRAW_SEGMENT":
                       this.visualizeDrawSegment(data);
                    break;

                    case "STATE_TRANSITION":
                      this.displayTransition(data);
                    break;

                }
			}
      updateInspector(data) {
        if (!this.inspectorInit) {
          this.initInspector();
          this.inspectorInit = true;
        }
        console.log("INSPECTOR DATA!! ", data.brushState);
        $("#inspector-x-pos").text(data.brushState.x);
        $("#inspector-y-pos").text(data.brushState.y);
        $("#inspector-x-scale").text(data.brushState.sX);
        $("#inspector-y-scale").text(data.brushState.sY);
        $("#inspector-rot").text(data.brushState.r);
        $("#inspector-diameter").text(data.brushState.d);
        $("#inspector-alpha").text(parseFloat(data.brushState.a).toFixed(2));
        $("#inspector-hue").text(data.brushState.h);
        $("#inspector-sat").text(data.brushState.s);
        $("#inspector-val").text(data.brushState.lV);
          $("#inspector-lightness").text(data.brushState.l);


      }

      displayTransition(data){
        console.log("transition via", data.transitionId);
        console.log("prev state id", data.prevState, "curr state id", data.currentState);
        $("#" + data.transitionId).parent().show();
        $("#" + data.transitionId).parent().next().hide(); //the toggle button
        console.log("sibling is ", $("#" + data.transitionId).parent().next());
        //should pause? automatically goes to draw segment step 
        this.lastTransitionId = data.transitionId;
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
        if(this.lastTransitionId) {
          $("#" + this.lastTransitionId).parent().hide();
          $("#" + this.lastTransitionId).parent().next().show(); //the toggle button
          this.lastTransitionId = null;
        }
				if(pastConstraint){
					$("#" + pastConstraint.constraintId).removeClass("debug");
          $("#param-" + pastConstraint.name).removeClass("debug-inspect");
          console.log("VIZ past ", pastConstraint.name);
				} 
				$("#" + constraint.constraintId).addClass("debug");
        $("#param-" + constraint.name).addClass("debug-inspect");
        console.log("VIZ curr ", constraint.name);

        // highlight inspector console 


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