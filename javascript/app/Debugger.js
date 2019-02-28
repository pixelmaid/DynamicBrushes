//Debugger

"use strict";

define(["app/Emitter"],

	function(Emitter) {


		var Debugger = class extends Emitter {


			constructor() {
				super();
				this.pastConstraint = null;
				this.inspectorInit = false;
				this.data = null;
				this.vizQueue = [];
				document.onkeyup = function(e) {

					if (e.keyCode == 39) {
						if (this.vizQueue.length === 0) {
							this.trigger("STEP_FORWARD");
						} else {
							let currentConstraint = this.vizQueue.shift();
							this.visualizeStepThrough(currentConstraint, this.pastConstraint, this.data);
							this.pastConstraint = currentConstraint;
						}

					}
				}.bind(this);
			}

			initInspector(data) {
				console.log("adding inspector");
				var inspectorHTML = '<div id="brush-inspector" class="w jsplumb-draggable jsplumb-droppable ui-droppable">' +
					'<ul style="padding:0 10px 0 10px;">' +
					'<li id="param-ox">origin x: <span id="inspector-ox-pos">' + parseFloat(data.brushState.ox).toFixed(2) + '</span></li>' +
					'<li id="param-oy">origin y: <span id="inspector-oy-pos">' + parseFloat(data.brushState.oy).toFixed(2) + '</span></li>' +
					'<li id="param-sx">scale x: <span id="inspector-x-scale">' + parseFloat(data.brushState.sx).toFixed(2) + '</span></li>' +
					'<li id="param-sy">scale y: <span id="inspector-y-scale">' + parseFloat(data.brushState.sy).toFixed(2) + '</span></li>' +
					'<li id="param-rotation">rotation: <span id="inspector-rotation">' + parseFloat(data.brushState.rotation).toFixed(2) + '</span></li>' +
					'<li id="param-x">position x: <span id="inspector-x-pos">' + parseFloat(data.brushState.x).toFixed(2) + '</span></li>' +
					'<li id="param-y">position y: <span id="inspector-y-pos">' + parseFloat(data.brushState.y).toFixed(2) + '</span></li>' +
					'<li id="param-diameter">diameter: <span id="inspector-diameter">' + parseFloat(data.brushState.diameter).toFixed(2) + '</span></li>' +
					'<li id="param-hue">hue: <span id="inspector-hue">' + data.brushState.hue + '</span></li>' +
					'<li id="param-saturation">saturation: <span id="inspector-saturation">' + data.brushState.saturation + '</span></li>' +
					'<li id="param-lightness">lightness: <span id="inspector-lightness">' + data.brushState.lightness + '</span></li>' +
					'<li id="param-alpha">alpha: <span id="inspector-alpha">' + parseFloat(data.brushState.alpha).toFixed(2) + '</span></li>' +
					'<li id="param-i">child index: <span id="inspector-child">' + data.brushState.i + '</span></li>' +
					'<li id="param-lV">spawn level: <span id="inspector-spawnlv">' + data.brushState.lV + '</span></li>' +
					'</ul>' +
					'</div>';
				$('#canvas').append(inspectorHTML);
			}

			processInspectorData(data) {
				console.log("data type is ", data.type);
				console.log("data is ", data);
				this.data = data;
				switch (data.type) {
					case "DRAW_SEGMENT":
						this.visualizeDrawSegment(data);
						break;

          case "STATE_TRANSITION":
						this.displayTransition(data);
						break;

				}
			}

			displayTransition(data) {
        console.log("! displaying transition of ", data, " queue is ", this.vizQueue);
        //add type
        this.vizQueue.push({transitionId: data.prevState, type:"transition"});
        this.vizQueue.push({transitionId: data.transitionId, type:"transition"});
        for (var i = 0; i < data.methods.length; i++) {
          data.methods[i].type = "method"
          this.vizQueue.push(data.methods[i]);
        }

        // UNCOMMENT THESE LINES TO HIDE/SHOW
				// $("#" + data.transitionId).parent().show();
				// $("#" + data.transitionId).parent().next().hide(); //the toggle button
        // $("#" + data.transitionId).parent().next().removeClass("state active");
        // $("#" + data.transitionId).parent().addClass("state active");

        console.log("! now queue is ", this.vizQueue);

			}

			visualizeDrawSegment(data) {
        console.log("! visualizing draw segment ", data, " queue is ", this.vizQueue);
				let brushState = data["brushState"];
				//$("#" + data.prevState).children(".state").removeClass("active");
				//$("#" + data.currentState).children(".state").addClass("active");
				for (var i = 0; i < data.constraints.length; i++) {
          data.constraints[i].type = "binding"
					data.constraints[i].value = brushState[data.constraints[i].constraintId];
					this.vizQueue.push(data.constraints[i]);
				}


			}

			visualizeStepThrough(constraint, pastConstraint, data) {
        console.log("! visualizing constraints ", data, " queue ", this.vizQueue, " past constraint ", pastConstraint);
				if (!this.inspectorInit) {
					this.initInspector(data);
					this.inspectorInit = true;
				}

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
              }
              else if ($("#" + pastConstraint.transitionId).hasClass("transition_statement")) {
                $("#" + pastConstraint.transitionId).children().first().removeClass("method-inspect");;
              } else { //it's a state
                $("#" + pastConstraint.transitionId).children().find("h2").removeClass("state-title-inspect");
              }
              //remove arrow highlight                     
              var arrowObject = $("#" + pastConstraint.transitionId).parent().prev();
              arrowObject.children().eq(1).attr("stroke", "#efac1f");
              arrowObject.children().eq(2).attr("stroke", "#efac1f");
              arrowObject.children().eq(2).attr("fill", "#efac1f");
            break;            
          }
        }

        switch (constraint.type) {
          case "method":
            console.log("VIZ METHOD ", constraint);
            $("#" + constraint.methodId).addClass("method-inspect");
            break;
          case "binding":
            $("#" + constraint.constraintId).addClass("debug");
            $("#param-" + constraint.relativePropertyName).addClass("debug-inspect");
            console.log("VIZ curr ", constraint.relativePropertyName);

            switch (constraint.relativePropertyName) {
              case "x":
                $("#inspector-x-pos").text(data.brushState.x);
                console.log("update x");
                break;
              case "y":
                $("#inspector-y-pos").text(data.brushState.y);
                console.log("update y");
                break;
              case "sx":
                $("#inspector-x-scale").text(data.brushState.sy);
                break;
              case "sy":
                $("#inspector-y-scale").text(data.brushState.sx);
                break;
              case "rotation":
                $("#inspector-rotation").text(data.brushState.rotation);
                break;
              case "alpha":
                $("#inspector-alpha").text(parseFloat(data.brushState.alpha).toFixed(2));
                break;
              case "hue":
                $("#inspector-hue").text(data.brushState.hue);
                break;
              case "saturation":
                $("#inspector-sat").text(data.brushState.saturation);
                break;
              case "lightness":
                $("#inspector-lightness").text(data.brushState.lightness);
                break;
              case "diameter":
                $("#inspector-diameter").text(data.brushState.diameter);
                break;
              case "i":
                $("#inspector-child").text(data.brushState.i);
                break;
              case "lV":
                $("#inspector-spawnlv").text(data.brushState.lV);
                break;
            }         
            break;
          case "transition":
            console.log("! VIZ TRANSITION ", constraint, pastConstraint);
            if (constraint.transitionId == "start") {
              $(".setup").children().eq(1).addClass("start-highlight");
            }
            if ($("#" + constraint.transitionId).hasClass("transition_statement")) {
              //outline header
              $("#" + constraint.transitionId).children().first().addClass("method-inspect");
            } else { //it's a state
              //highlight title
              $("#" + constraint.transitionId).children().find("h2").addClass("state-title-inspect");
            }
              //add arrow highlight                     
              var arrowObject = $("#" + constraint.transitionId).parent().prev();
              arrowObject.children().eq(1).attr("stroke", "aqua");
              arrowObject.children().eq(2).attr("stroke", "aqua");
              arrowObject.children().eq(2).attr("fill", "aqua");
            break;         
        }
				
			}

		};

		return Debugger;


	});