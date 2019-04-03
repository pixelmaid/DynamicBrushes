//Debugger

"use strict";

define(["app/Emitter"],

    function(Emitter) {


        var DebuggerModel = class extends Emitter {


            constructor() {
                super();

                this.data = {};
                this.setupData();

                this.brushVizQueue = [];
                this.inputVizQueue = [];
                this.outputVizQueue = [];
            }

            processInspectorData(data) {

                console.log("! data type is ", data.type);
                console.log("! data is ", data);
                this.updateBrushData(data.brushState);
                switch (data.type) {
                    case "DRAW_SEGMENT":
                        
                        //this.trigger("ON_VIZ_DRAW_SEGMENT",[data]);
                        this.visualizeDrawSegment(data);
                        break;

                    case "STATE_TRANSITION":
                        //this.trigger("ON_STATE_TRANSITION",[data]);
                        console.log("! calling display transition");
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
              data.constraints[i].type = "binding"
              data.constraints[i].value = brushState[data.constraints[i].constraintId];
              this.brushVizQueue.push(data.constraints[i]);
            }
          }

          displayTransition(data) {
            console.log("! displaying transition of ", data, "brush queue is ", this.brushVizQueue);
            //add type
            this.brushVizQueue.push({transitionId: data.prevState, type:"transition"});
            this.brushVizQueue.push({transitionId: data.transitionId, type:"transition"});
            for (var i = 0; i < data.methods.length; i++) {
              data.methods[i].type = "method"
              this.brushVizQueue.push(data.methods[i]);
            }

            console.log("! now brush queue is ", this.brushVizQueue);

          }

            updateParam(group, key, val) {
              for (var i = 0; i < group["blocks"].length; i++) {
                //iterate through blocks 
                var params = group["blocks"][i]["params"]
                params.find(function (e) {
                  if (e["id"] == key) {
                    console.log("~~~~ updated ", key, " to ", val);
                    e["val"] = val;
                    return;
                  }
                });
              }
            }

            updateBrushData(data) {
              var group = this.data["groups"][0];
              for (var key in data) {
                var val = data[key];
                this.updateParam(group, key, val);
              }
            }



            setupData() {
                this.data = {
                    groups: [{
                            groupName: "brush",
                            blocks: [{
                                blockName: "geometry",
                                params: [
                                    { name: "origin x", id: "ox", val: 0 },
                                    { name: "origin y", id: "oy", val: 0 },
                                    { name: "scale x", id: "sx", val: 0 },
                                    { name: "scale y", id: "sy", val: 0 },
                                    { name: "rotation", id: "rotation", val: 0 },
                                    { name: "position x", id: "x", val: 0 },
                                    { name: "position y", id: "y", val: 0 },
                                    { name: "delta x", id: "dx", val: 0 },
                                    { name: "delta y", id: "dy", val: 0 },
                                ]
                                },
                                {blockName: "style",
                                    params: [
                                        { name: "stroke weight", id: "weight", val: 0 },
                                        { name: "hue", id: "hue", val: 0 },
                                        { name: "saturation", id: "saturation", val: 0 },
                                        { name: "lightness", id: "lightness", val: 0 },
                                        { name: "alpha", id: "alpha", val: 0 },
                                    ]
                                },
                                {blockName: "spawn",
                                    params: [
                                        { name: "child index", id: "i", val: 0 },
                                        { name: "spawn level", id: "lV", val: 0 }
                                    ]
                                }
                            ]
                        },

                        {
                            groupName: "inputGlobal",
                            blocks: [{

                                 blockName: "stylus",
                                    params: [
                                        { name: "stylus x", id: "stylus-x", val: 0 },
                                        { name: "stylus y", id: "stylus-y", val: 0 }
                                    ]
                                },
                                { blockName: "mic",
                                    params: [
                                        { name: "amplitude", id: "amp", val: 0 },
                                        { name: "frequency", id: "freq", val: 0 }
                                    ]
                                }
                            ],
                        },


                        {
                            groupName: "inputLocal",
                            blocks: []
                        }, //need to hook up somehow? 

                        {
                            groupName: "output",
                            blocks: [{
                                 blockName: "pen state",
                                    params: [
                                        { name: "pen state", id: "pen", val: "up" }
                                    ]
                                },
                                { blockName: "geometry",
                                    params: [
                                        { name: "absolute x", id: "absx", val: 0 },
                                        { name: "absolute y", id: "absy", val: 0 }
                                    ]
                                },
                                { blockName: "style",
                                    params: [
                                        { name: "stroke weight", id: "weight", val: 0 },
                                        { name: "hue", id: "h", val: 0 },
                                        { name: "saturation", id: "s", val: 0 },
                                        { name: "value", id: "v", val: 0 },
                                        { name: "lightness", id: "l", val: 0 },
                                        { name: "alpha", id: "a", val: 0 },
                                    ]
                            }]
                        }
                    ]
                }
            }

        };

        return DebuggerModel;


    });