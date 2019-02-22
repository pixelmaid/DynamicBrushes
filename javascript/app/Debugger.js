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
        this.data = null;
				this.vizQueue = [];
                document.onkeyup = function(e) {
                
                    if(e.keyCode == 39){
                    	if(this.vizQueue.length === 0){
                       		this.trigger("STEP_FORWARD");
                       	}
                       	else{
                       		let currentConstraint = this.vizQueue.pop();
                       		this.visualizeConstraint(currentConstraint,this.pastConstraint,this.data);
                       		this.pastConstraint = currentConstraint;
                       	}

                    }
                }.bind(this);
			}

      initInspector(data) {
        console.log("adding inspector");
        var inspectorHTML = '<div id="brush-inspector" class="w jsplumb-draggable jsplumb-droppable ui-droppable">' +
        '<ul style="padding:0 10px 0 10px;">' +
        '<li id="param-x">position x: <span id="inspector-x-pos">'+data.brushState.x+'</span></li>' +
        '<li id="param-y">position y: <span id="inspector-y-pos">'+data.brushState.y+'</span></li>' +
        '<li id="param-sX">scale x: <span id="inspector-x-scale">'+data.brushState.sX+'</span></li>' +
        '<li id="param-sY">scale y: <span id="inspector-y-scale">'+data.brushState.sY+'</span></li>' +
        '<li id="param-r">rotation: <span id="inspector-rot">'+data.brushState.r+'</span></li>' +
         '<li id="param-d">diameter: <span id="inspector-d">'+data.brushState.r+'</span></li>' +
        '<li id="param-a">alpha: <span id="inspector-alpha">'+parseFloat(data.brushState.a).toFixed(2)+'</span></li>' +
        '<li id="param-h">hue: <span id="inspector-hue">'+data.brushState.h+'</span></li>' +
        '<li id="param-s">saturation: <span id="inspector-sat">'+data.brushState.s+'</span></li>' +
        '<li id="param-l">lightness: <span id="inspector-lightness">'+data.brushState.l+'</span></li>' +
        '<li id="param-i">child index: <span id="inspector-child">'+data.brushState.i+'</span></li>' +
        '<li id="param-lV">spawn level: <span id="inspector-spawnlv">'+data.brushState.lV+'</span></li>' +
        '</ul>' +
        '</div>'
        $('#canvas').append(inspectorHTML);
      }

			processInspectorData(data){
        console.log("data type is ", data.type);
        console.log("data is ", data);
        this.data = data;
				switch (data.type){
                    case "DRAW_SEGMENT":
                       this.visualizeDrawSegment(data);
                    break;

                    case "STATE_TRANSITION":
                      this.displayTransition(data);
                    break;

                }
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

			visualizeConstraint(constraint,pastConstraint,data){
        if (!this.inspectorInit) {
          this.initInspector(data);
          this.inspectorInit = true;
        }
        if(this.lastTransitionId) {
          $("#" + this.lastTransitionId).parent().hide();
          $("#" + this.lastTransitionId).parent().next().show(); //the toggle button
          this.lastTransitionId = null;
        }
				if(pastConstraint){
					$("#" + pastConstraint.constraintId).removeClass("debug");
          $("#param-" + pastConstraint.name).removeClass("debug-inspect");
				} 
				$("#" + constraint.constraintId).addClass("debug");
        $("#param-" + constraint.name).addClass("debug-inspect");
        console.log("VIZ curr ", constraint.name);

        switch (constraint.name) {
          case "x":
              $("#inspector-x-pos").text(data.brushState.x);
              console.log("update x");
              break;
          case "y":
              $("#inspector-y-pos").text(data.brushState.y);
                console.log("update y");
              break;
          case "sX":
              $("#inspector-x-scale").text(data.brushState.sX);
              break;
          case "sY":
              $("#inspector-y-scale").text(data.brushState.sY);
              break;
          case "r":
              $("#inspector-rot").text(data.brushState.r);
              break;
          case "a":
              $("#inspector-alpha").text(parseFloat(data.brushState.a).toFixed(2));
              break;
          case "h":
              $("#inspector-hue").text(data.brushState.h);
              break;
          case "s":
              $("#inspector-sat").text(data.brushState.s);
              break;
          case "l":
              $("#inspector-lightness").text(data.brushState.l);
              break;
          case "d":
              $("#inspector-diameter").text(data.brushState.d);
              break;
          case "i":
              $("#inspector-child").text(data.brushState.i);
              break;
          case "lV":
              $("#inspector-spawnlv").text(data.brushState.lV);
              break;
        }


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