"use strict";

define(["app/Emitter", "app/DebuggerModel","app/BrushDebuggerModel"],

	function(Emitter, DebuggerModel, BrushDebuggerModel) {


		var DebuggerModelCollection = class extends Emitter {

			constructor(chartViewManager) {
				super();
				this.setupData();

				this.brushModel = new BrushDebuggerModel(this);
				this.inputModel = new DebuggerModel(this);
				this.outputModel = new DebuggerModel(this);
				this.selectedIndex = 0;
				this.inspectorQueue = [];
				// this.stepThroughQueue = []; //list of lists 
				this.chartViewManager = chartViewManager;
				this.startInspectorInterval();
				this.manualSteppingOn = false;
				this.currHighlighted = [];
				var self = this;
				this.lastWasTransition = false;
			

			}

			getCurrHighlighted() {
				return this.currHighlighted;
			}

			pushCurrHighlighted(obj){
				this.currHighlighted.push(obj);
			}

			resetCurrHighlighted() {
				this.currHighlighted = [];
			}

			updateSelectedIndex(index) {
				this.selectedIndex = index;
				this.trigger("ON_ACTIVE_INSTANCE_CHANGED", [this.selectedIndex]);
			}

			updateHighlight(dataArray){
				let id = dataArray[0];
				let isOn = dataArray[1];
				let data = {'name':id, 'isOn':isOn};
				console.log("!!!! triggering highlight~ ", data);
				this.trigger("ON_HIGHLIGHT_REQUEST",[data]);
		 	}


			startInspectorInterval(){
				if(this.inspectorDataTimer){
					clearInterval(this.inspectorDataTimer);
				}

				var self = this;
				this.inspectorDataTimer = setInterval(function() { self.inspectorDataInterval(); }, 50);
			}

			terminateInspectorInterval(){
				if(this.inspectorDataTimer){
					clearInterval(this.inspectorDataTimer);
				}
			}

			initializeStepping(){
				this.resetInspection();
				this.manualSteppingOn = true;
				this.trigger("INITIALIZE_STEPPING");
	        	this.terminateInspectorInterval();
			}

			deinitializeStepping(){
				this.resetInspection();
				this.manualSteppingOn = false;
				this.trigger("DEINITIALIZE_STEPPING");
				this.startInspectorInterval();

			}

			stepDrawingViewForward(){
				this.trigger("STEP_FORWARD");

			}

			resetInspection(){
				this.clearInspectorDataQueue();
			}

			clearInspectorDataQueue(){
				this.inspectorQueue = [];
			}

			processInspectorDataQueue(dataQueue){
				console.log("~~!! data queue is ", dataQueue);
				this.inspectorQueue.push.apply(this.inspectorQueue,dataQueue);

			}

			inspectorDataInterval(){
				// console.log("~~~~ !!!  called data interval");

				if (this.brushModel.brushVizQueue.length > 0) {
					console.log("~~~~ !!!  inspect: visualizing brush");
					this.trigger("VIZ_BRUSH_STEP_THROUGH");
					console.log("~~~~ !!! brushVizLen at end ", this.brushModel.brushVizQueue.length);
					return;
				}
				else if (this.brushModel.brushVizQueue.length == 0) {
					if (this.manualSteppingOn) {
						console.log("~~~~ !!! inspect: st qqepping forward ", this.brushModel.brushVizQueue);
						this.stepDrawingViewForward();
					} else if (this.brushModel.toClearViz){
						console.log("~~~~ !!!  inspect: clearing highlights");
						//clear highlights -- assuming last one is alpha
						this.trigger("CLEAR_STEP_HIGHLIGHT");	
						this.brushModel.toClearViz = false;					
					}

					if (this.inspectorQueue.length>0){
						console.log("~~~~ !!!  inspect: updating queue");
						console.log("~~~~ inspector queue in data interval ", this.inspectorQueue);
						let targetData = this.inspectorQueue.shift();
						// console.log("~~~~ global time in first queue element is ", targetData["brush"][
							// "behaviors"][0]["brushes"][0]["params"]["globalTime"]);
						// console.log("~~~ processing inspector queue ", targetData);
						this.processInspectorData(targetData);
					}
				}
				
			}


			processInspectorData(newData) {
				if(newData.type == "state"){
					this.processStateData(newData);
				}
				else if (newData.type == "highlight"){
					this.highlight(newData);
				}
			}


			highlight(newData){
				// console.log("~~~~~ received data final!! ", newData, this.brushModel);
				let type = newData.kind;
				let isOn = newData.isOn;
				switch (type) {
					case "clear":
						this.inputModel.highlight("none", false);
						this.brushModel.highlight("none", false);
						this.outputModel.highlight("none", false);
						break;
					case "input":
						this.inputModel.highlight("param-styx", true);
						this.inputModel.highlight("param-styy", true);
			            break;
			        case "origin":
						this.brushModel.highlight("param-ox", true);
						this.brushModel.highlight("param-oy", true);			            
						break;
			        case "scale-x":
						this.brushModel.highlight("param-sx", true);
						break;
			        case "scale-y":
						this.brushModel.highlight("param-sy", true);				            
			            break;
			        case "rotation":
						this.brushModel.highlight("param-rotation", true);				           
			            break;
			        case "brush":
						this.brushModel.highlight("param-posx", true);
						this.brushModel.highlight("param-posy", true);			            
						break;
			        case "output":
						this.outputModel.highlight("param-x", true);
						this.outputModel.highlight("param-y", true);			            
						break;
					default: //gets the generators 
						this.inputModel.highlight(type, true);
						console.log("~~~ highlighting a generator");
						break;
				}
			}

			processStateData(newData){ //this is on timer  
				// console.log("! data is ", newData);
				var formattedOutputData = this.formattedOutputData(newData.output);
				var formattedBrushData = this.formatBrushData(newData.brush);
				var formattedGeneratorData = this.formatGeneratorData(newData.input.generator.params);

				var formattedInputGlobalData = this.formatInputGlobalData(newData.input.inputGlobal);

				// console.log(formattedInputGlobalData);

				var formattedInputData = {
					local: formattedGeneratorData,
					global: formattedInputGlobalData
				};
				this.brushModel.update(formattedBrushData); 
				this.inputModel.update(formattedInputData);
				this.outputModel.update(formattedOutputData);


			}



			formatInputGlobalData(data) {
				var self = this;
				var formattedData = {};

				var group = self.dataTemplate.groups.find(function(group) {
					return group.groupName === "inputGlobal";
				});

				formattedData.groupName = "inputGlobal";
				var formattedItems = [];
				var items = data.items;

				var formattedParams = JSON.parse(JSON.stringify(group));
				for (var j = 0; j < items.length; j++) {

					var item = items[j];
					var params = item.params;

					for (var key in params) {
						if (params.hasOwnProperty(key)) {
							var val = params[key];
							this.formatParams(formattedParams, key, val);
						}
					}

				}

				formattedData.items = formattedParams;
				formattedData.name = "Global Input";
				return formattedData;
			}

			formattedOutputData(data) {
				var self = this;
				var formattedData = {
					behaviors: []
				};
				var behaviors = data.behaviors;
				for (var behaviorId in behaviors) {
					if (behaviors.hasOwnProperty(behaviorId)) {
						let behavior = behaviors[behaviorId];
						let formattedBehavior = {};
						var group = this.dataTemplate.groups.find(function(group) {
							return group.groupName == data.groupName;
						});
						formattedData.groupName = data.groupName;
						var formattedBrushes = [];
						var brushes = behavior.brushes;
						for (var brushId in brushes) {
							if (brushes.hasOwnProperty(brushId)) {
								var formattedParams = JSON.parse(JSON.stringify(group));
								let brush = brushes[brushId];
								var params = brush.params;
								
								for (var key in params) {
									if (params.hasOwnProperty(key)) {
										var val = params[key];
										this.formatParams(formattedParams, key, val);
									}
								}

									formattedParams.index = brush.i;
									if (formattedParams.index == self.selectedIndex) {
										formattedParams.selectedIndex = true;
									} else {
										formattedParams.selectedIndex = false;
									}
									formattedParams.id = brushId;
									formattedParams.name = brush.name;
									
									formattedBrushes.push(formattedParams);
							}

						}
					formattedBehavior.id = behaviorId;
					formattedBehavior.name = behavior.name;
					formattedBehavior.brushes = formattedBrushes;
					formattedData.behaviors.push(formattedBehavior);

					}
				}
				return formattedData;
			}

			formatBrushData(data) {
				var self = this;
				var formattedData = {
					behaviors: []
				};

				for (var i = 0; i < data.behaviors.length; i++) {
					let behavior = data.behaviors[i];
					let formattedBehavior = {};

					//group should be a list
					var group = this.dataTemplate.groups.find(function(group) {
						return group.groupName === data.groupName;
					});

					var brushes = behavior.brushes;
					formattedData.groupName = data.groupName;
					var formattedBrushes = [];

					for (var j = 0; j < brushes.length; j++) {
						var formattedParams = JSON.parse(JSON.stringify(group));
						var brush = brushes[j];
						var params = brush.params;

						for (var key in params) {
							if (params.hasOwnProperty(key)) {
								var val = params[key];
								this.formatParams(formattedParams, key, val);
							}
						}
						formattedParams.name = brush.name;
						formattedParams.index = brush.params.i;
						if (formattedParams.index == self.selectedIndex) {
							formattedParams.selectedIndex = true;
						} else {
							formattedParams.selectedIndex = false;
						}

						formattedParams.id = brush.id;
						formattedBrushes.push({
										inspector:formattedParams,
										behaviorId:brush.behaviorId,
										constraints:brush.constraints,
										currentState:brush.currentState,
										event: brush.event,
										id:brush.id,
										methods:brush.methods,
										prevState:brush.prevState,
										transitionId:brush.transitionId
									});
						//formattedBrushes.push(formattedParams);


					}

					formattedBehavior.id = behavior.id;
					formattedBehavior.name = behavior.name;
					formattedBehavior.brushes = formattedBrushes;
					formattedData.behaviors.push(formattedBehavior);

				}

				return formattedData;
			}



			formatParams(group, key, val) {
				for (var i = 0; i < group["blocks"].length; i++) {
					//iterate through blocks 
					var params = group["blocks"][i]["params"];

					params.find(function(e) {
						if (e["id"] == key) {
							// console.log("~~~~ updated ", key, " to ", val);
							if (key == "parent" || key == "pen") {
								e["val"] = val;
							}
							else if( key == "stylusEvent"){
								switch (val){
									case 0: 
									e["val"] = "stylus up";
									break;
									case 1: 
									e["val"] = "stylus move";
									break;
									case 2: 
									e["val"] = "stylus down";
									break;
								}
							}
							 else {
								e["val"] = val.toFixed(2);
							}


							return;
						}
					});
				}
			}


			formatGeneratorData(data) {
				var formattedData = {
					behaviors: []
				};
				var self = this;
				var seenGenTypes = [];
				for (var generatorId in data) {
					if (data.hasOwnProperty(generatorId)) {

						let generatorList = data[generatorId];
						for (var i = 0; i < generatorList.length; i++) {
							let generatorInstance = generatorList[i];
							let behaviorId = generatorInstance["behaviorId"];
							let behaviorName = generatorInstance["behaviorName"];
							let brushId = generatorInstance["brushId"];

							let brushIndex = generatorInstance["brushIndex"];
							let val = generatorInstance["v"];
							let generatorType = generatorInstance["generatorType"];
							if (seenGenTypes.includes(generatorType)) continue;
							let time = generatorInstance["time"];
							seenGenTypes.push(generatorType);
							var behavior = formattedData.behaviors.find(function(b) {
								return b.id === behaviorId;
							});

							if (behavior == null) {
								behavior = {
									id: behaviorId,
									name: behaviorName,
									brushes: []
								};
								formattedData.behaviors.push(behavior);

							}


							var brush = behavior.brushes.find(function(b) {
								return b.id === brushId;
							});


							if (brush == null) {
								brush = {
									id: brushId,
									index: brushIndex,
									generators: JSON.parse(JSON.stringify(self.generatorTemplate))
								};
								if (brushIndex == self.selectedIndex) {
									brush.selectedIndex = true;
								} else {
									brush.selectedIndex = false;
								}
								behavior.brushes.push(brush);
							}

							var targetGenerator = brush.generators.find(function(g) {
								return g.type === generatorType;
							});

							targetGenerator.instances.push({
								id: generatorId,
								time: time,
								val: val.toFixed(2)
							});


							behavior.brushes.sort(function(a, b) {
								return a.index - b.index;
							});
						}

					}

				}
				formattedData.groupName = "generator";

				return formattedData;

			}



			setupData() {

				this.generatorTemplate = [

					{
						type: "sawtooth",
						instances: []
					},

					{
						type: "sine",
						instances: []
					},


					{
						type: "random",
						instances: []
					},


					{
						type: "triangle",
						instances: []
					},


					{
						type: "square",
						instances: []
					}


				];

				this.dataTemplate = {
					groups: [{
							groupName: "brush",
							blocks: [{
								blockName: "time",
								params: [{
										name: "time",
										id: "time",
										val: 0
									},

								]
							}, {
								blockName: "geometry",
								params: [{
									name: "origin x",
									id: "ox",
									val: 0
								}, {
									name: "origin y",
									id: "oy",
									val: 0
								}, {
									name: "scale x",
									id: "sx",
									val: 0
								}, {
									name: "scale y",
									id: "sy",
									val: 0
								}, {
									name: "rotation",
									id: "rotation",
									val: 0
								}, /*{
									name: "position x",
									id: "x",
									val: 0
								}, {
									name: "position y",
									id: "y",
									val: 0
								},*/ {
									name: "delta x",
									id: "dx",
									val: 0
								}, {
									name: "delta y",
									id: "dy",
									val: 0
								}/*, {
									name: "polar radius",
									id: "pr",
									val: 0
								}, {
									name: "polar theta",
									id: "pt",
									val: 0
								}*/]
							}, {
								blockName: "style",
								params: [{
									name: "stroke weight",
									id: "weight",
									val: 0
								}, {
									name: "hue",
									id: "hue",
									val: 0
								}, {
									name: "lightness",
									id: "lightness",
									val: 0
								},{
									name: "saturation",
									id: "saturation",
									val: 0
								}, {
									name: "alpha",
									id: "alpha",
									val: 0
								}]
							}, {
								blockName: "instance",
								params: [{
									name: "spawn index",
									id: "i",
									val: 0
								}, {
									name: "sibling count",
									id: "sc",
									val: 0
								}, {
									name: "spawn level",
									id: "lv",
									val: 0
								}, {
									name: "parent",
									id: "parent",
									val: "test"
								}]
							}]
						},

						{
							groupName: "inputGlobal",
							blocks: [{

								blockName: "stylus",
								params: [{
									name: "stylus event",
									id: "stylusEvent",
									val: 0
								},{
									name: "stylus x",
									id: "x",
									val: 0
								}, {
									name: "stylus y",
									id: "y",
									val: 0
								},{
									name: "stylus delta x",
									id: "dx",
									val: 0
								}, {
									name: "stylus delta y",
									id: "dy",
									val: 0
								}, {
									name: "stylus force",
									id: "force",
									val: 0
								}, {
									name: "stylus angle",
									id: "angle",
									val: 0
								}]
							}/*, {
								blockName: "mic",
								params: [{
									name: "amplitude",
									id: "amp",
									val: 0
								}, {
									name: "frequency",
									id: "freq",
									val: 0
								}]
							}*/],
						},

						{
							groupName: "output",
							blocks: [{
								blockName: "pen state",
								params: [{
									name: "pen state",
									id: "pen",
									val: "up"
								}]
							}, {
								blockName: "geometry",
								params: [{
									name: "absolute x",
									id: "x",
									val: 0
								}, {
									name: "absolute y",
									id: "y",
									val: 0
								}]
							}, {
								blockName: "style",
								params: [{
									name: "stroke weight",
									id: "weight",
									val: 0
								}, {
									name: "hue",
									id: "h",
									val: 0
								}, {
									name: "saturation",
									id: "s",
									val: 0
								}, {
									name: "lightness",
									id: "l",
									val: 0
								}, {
									name: "alpha",
									id: "a",
									val: 0
								}, ]
							}]
						}
					]
				};
			}
		};

		return DebuggerModelCollection;
	});