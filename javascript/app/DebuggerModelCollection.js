"use strict";

define(["app/Emitter", "app/DebuggerModel"],

	function(Emitter, DebuggerModel) {


		var DebuggerModelCollection = class extends Emitter {

			constructor() {
				super();
				this.data = {};
				this.setupData();

				this.brushModel = new DebuggerModel();
				this.inputModel = new DebuggerModel();
				this.outputModel = new DebuggerModel();


			}

			processInspectorData(newData) {
				console.log("! data type is ", newData.type);
				console.log("! data is ", newData);
				this.formatData(newData);

				this.brushModel.update(this.data.groups[0]);
				this.inputModel.update(this.data.groups[1]);
				this.outputModel.update(this.data.groups[2]);


			}

			formatData(newData) {
				var group = this.data["groups"][0];
				for (var key in newData) {
					if (newData.hasOwnProperty(key)) {
						var val = newData[key];
						this.formatParam(group, key, val);
					}
				}
			}

			formatParam(group, key, val) {
				for (var i = 0; i < group["blocks"].length; i++) {
					//iterate through blocks 
					var params = group["blocks"][i]["params"];
					params.find(function(e) {
						if (e["id"] == key) {
							console.log("~~~~ updated ", key, " to ", val);
							if(key == "parent"){
								e["val"] = val;
							}
							else{
								e["val"] = Math.round(val);
							}
							return;
						}
					});
				}
			}
q
			setupData() {
				this.data = {
					groups: [
						{
							groupName: "brush",
							blocks: [ {
								blockName: "time",
								params: [{
										name: "time",
										id: "time",
										val: 0
									},

								]
							},{
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
									name: "child index",
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
									id: "stylus-x",
									val: 0
								}, {
									name: "stylus y",
									id: "stylus-y",
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
							groupName: "inputLocal",
							blocks: []
						}, //need to hook up somehow? 

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