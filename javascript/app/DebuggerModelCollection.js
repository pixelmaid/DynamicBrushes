"use strict";

define(["app/Emitter", "app/DebuggerModel"],

	function(Emitter, DebuggerModel) {


		var DebuggerModelCollection = class extends Emitter {

			constructor() {
				super();
				this.setupData();

				this.brushModel = new DebuggerModel();
				this.inputModel = new DebuggerModel();
				this.outputModel = new DebuggerModel();
				this.selectedIndex = 0;


			}

			processInspectorData(newData) {
				console.log("! data is ", newData);
				var formattedBrushData = this.formatBrushData(newData.brush);
				var formattedGeneratorData = this.formatGeneratorData(newData.input.generator.default.params);

				this.brushModel.update(formattedBrushData);
				this.inputModel.update(formattedGeneratorData);
				//this.outputModel.update(newData.output);


			}

			formatBrushData(data) {
				var self = this;
				var formattedData = {behaviors:[]};

				for(var i =0;i<data.behaviors.length;i++){
				let behavior = data.behaviors[i];
				let formattedBehavior = {};

				//group should be a list
				var group = this.dataTemplate.groups.find(function(group) {
					return group.groupName === data.groupName;
				});

				var brushes = behavior.brushes;
				formattedData.groupName = data.groupName;
				var formattedBrushes = [];

				for (var j = 0; j< brushes.length; j++) {
					var formattedParams = JSON.parse(JSON.stringify(group));
					var brush = brushes[j];
					var params = brushes.params;

					for (var key in params) {
						if (params.hasOwnProperty(key)) {
							var val = params[key];
							this.formatBrushParams(formattedParams, key, val);
						}
					}
					formattedParams.name = brush.name;
					formattedParams.index = brush.params.i;
					if(formattedParams.index == self.selectedIndex){
						formattedParams.selectedIndex = true;
					}
					else{
						formattedParams.selectedIndex = false; 
					}

					formattedParams.id = brush.id;
					formattedBrushes.push(formattedParams);


				}

				formattedBehavior.id = behavior.id;
				formattedBehavior.name = behavior.name;
				formattedBehavior.brushes = formattedBrushes;
				formattedData.behaviors.push(formattedBehavior);

				}

				return formattedData;
			}



			formatBrushParams(group, key, val) {
				for (var i = 0; i < group["blocks"].length; i++) {
					//iterate through blocks 
					var params = group["blocks"][i]["params"];

					params.find(function(e) {
						if (e["id"] == key) {
							console.log("~~~~ updated ", key, " to ", val);
							if (key == "parent") {
								e["val"] = val;
							} else {
								e["val"] = Math.round(val);
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
							let time = generatorInstance["time"];

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
								if(brushIndex == self.selectedIndex){
									brush.selectedIndex = true;
								}
								else{
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
				formattedData.groupName = "generator"

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
								}, {
									name: "position x",
									id: "x",
									val: 0
								}, {
									name: "position y",
									id: "y",
									val: 0
								}, {
									name: "delta x",
									id: "dx",
									val: 0
								}, {
									name: "delta y",
									id: "dy",
									val: 0
								}, {
									name: "polar radius",
									id: "pr",
									val: 0
								}, {
									name: "polar theta",
									id: "pt",
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
									id: "hue",
									val: 0
								}, {
									name: "saturation",
									id: "saturation",
									val: 0
								}, {
									name: "lightness",
									id: "lightness",
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
									name: "stylus x",
									id: "x",
									val: 0
								}, {
									name: "stylus y",
									id: "y",
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
							}, {
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
							}],
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
									id: "absx",
									val: 0
								}, {
									name: "absolute y",
									id: "absy",
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
									name: "value",
									id: "v",
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