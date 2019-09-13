//BrushDebuggerModel

"use strict";

define(["app/DebuggerModel"],

function(DebuggerModel) {


    var BrushDebuggerModel = class extends DebuggerModel {


        constructor(collection) {
            super(collection);

            this.brushVizQueue = [];
            this.dataVizDict = {};
            this.stepThroughOn = true;
            this.toClearViz = false;
        }


        getParam(group, key) { //group is ['inspector'], key is eg sx. returns val 
            for (var i = 0; i < group["blocks"].length; i++) {
                var v;
                //iterate through blocks 
                var params = group["blocks"][i]["params"];
                params.find(function(e) {
                    if (e["id"] == key) {
                        v = e["val"];
                        return v;
                    }
                });
            }
        }

        replaceParam(data, key, val, behaviorIdx, brushIdx) {
            let group = data['behaviors'][behaviorIdx]['brushes'][brushIdx]['inspector']
            for (var i = 0; i < group["blocks"].length; i++) {
                var v;
                //iterate through blocks 
                var params = group["blocks"][i]["params"];
                for (var j = 0; j < params.length; j++) {
                    if (params[j]["id"] == key) {
                        params[j]["val"] = val;
                        console.log("~~~ replaced, data now ", params[j]);
                    }
                }
            }
            return data;
        }

        combineData(oldData, newData, param, behaviorIdx, brushIdx) {
            newVal = this.getParam(newData['behaviors'][behaviorIdx]['brushes'][brushIdx]['inspector'], param);
            combinedData = replaceParam(oldData, param, newVal, behaviorIdx, brushIdx);
            return combinedData
        }

        update(data) {
            /*
            geom block [1]
            sx, sy, rot, dx, dy - 2-6
            style block [2]
            w, h, l, s, a - 0-4 (all)
            */
            let oldData = this.data;
            this.data = data;

            if (this.collection.chartViewManager.currentView) {
                let currentBehaviorId = this.collection.chartViewManager.currentView.id;
                let selectedIndex = this.collection.selectedIndex;

                let targetBehaviorData = data.behaviors.find(function(element) {
                    return element.id == currentBehaviorId;
                });
                let targetBrushData = targetBehaviorData.brushes[selectedIndex];

                if (this.stepThroughOn) {
                    this.processStepData(targetBrushData);
                    if (this.collection.manualSteppingOn) {
                        params = ["sx", "sy", "rotation", "dx", "dy", "weight", "hue", "lightness", "saturation", "alpha"];
                        for (var i = 0; i < params.length; i++) {
                        	//TODO - change to real index
                            combinedData = combineData(oldData, data, params[i], 0, 0);
                            this.dataVizDict[params[i]] = combinedData;
                        }
                      this.data = oldData;  
                    }
                }
            }
        }


        //combine data all at once using dataVizQueue?

        this.trigger("DATA_UPDATED");


    }



    processStepData(data) {

        switch (data.event) {
            case "DRAW_SEGMENT":

                //this.trigger("ON_VIZ_DRAW_SEGMENT",[data]);
                this.visualizeDrawSegment(data);
                break;

            case "STATE_TRANSITION":
                //this.trigger("ON_STATE_TRANSITION",[data]);
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
            data.constraints[i].type = "binding";
            //START HERE!!!!!!!!
            //data.constraints[i].value = brushState[data.constraints[i].constraintId];
            this.brushVizQueue.push(data.constraints[i]);
        }
    }

    displayTransition(data) {
        console.log("! displaying transition of ", data, "brush queue is ", this.brushVizQueue);
        //add type
        this.brushVizQueue.push({
            transitionId: data.prevState,
            type: "transition"
        });
        this.brushVizQueue.push({
            transitionId: data.transitionId,
            type: "transition"
        });
        for (var i = 0; i < data.methods.length; i++) {
            data.methods[i].type = "method";
            this.brushVizQueue.push(data.methods[i]);
        }

        console.log("! now brush queue is ", this.brushVizQueue);

    }


};


return BrushDebuggerModel;


});