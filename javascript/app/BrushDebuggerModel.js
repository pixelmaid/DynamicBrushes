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

                for (var j = 0; j < params.length; j++) {
                    if (params[j]["id"] == key) {
                        return params[j]["val"];
                    }
                }

            }
        }

        replaceParam(data, key, val, behaviorIdx, brushIdx) {
            let group = data['behaviors'][behaviorIdx]['brushes'][brushIdx]['inspector'];
            for (var i = 0; i < group["blocks"].length; i++) {
                //iterate through blocks 
                var params = group["blocks"][i]["params"];
                for (var j = 0; j < params.length; j++) {
                    if (params[j]["id"] == key) {
                        params[j]["val"] = val;
                    }
                }
            }
            return data;
        }

        combineData(oldData, newData, param, behaviorIdx, brushIdx) {
            let newVal = this.getParam(newData['behaviors'][behaviorIdx]['brushes'][brushIdx]['inspector'], param);
            let oldVal = this.getParam(oldData['behaviors'][behaviorIdx]['brushes'][brushIdx]['inspector'], param);
            if (param == "dx")
		        console.log("~~ new val is ", newVal, param, oldVal);

            let combinedData = this.replaceParam(oldData, param, newVal, behaviorIdx, brushIdx);
            return combinedData;
        }

        update(data) {
            let oldData = JSON.parse(JSON.stringify(this.data));
            this.data = data;
            console.log("~~ !! updated old data dx, time " , this.getParam(oldData['behaviors'][0]['brushes'][0]['inspector'], "dx"), this.getParam(oldData['behaviors'][0]['brushes'][0]['inspector'], "time"), "new data dx, time ", this.getParam(data['behaviors'][0]['brushes'][0]['inspector'], "dx"), this.getParam(data['behaviors'][0]['brushes'][0]['inspector'], "time"));

            if (this.collection.chartViewManager.currentView) {
                let currentBehaviorId = this.collection.chartViewManager.currentView.id;
                let selectedIndex = this.collection.selectedIndex;

                let targetBehaviorData = data.behaviors.find(function(element) {
                    return element.id == currentBehaviorId;
                });
                let targetBrushData = targetBehaviorData.brushes[selectedIndex];

                if (this.stepThroughOn) {
                    if (this.collection.manualSteppingOn) {
                        let params = ["sy", "rotation", "dx", "dy", "weight", "hue", "lightness", "saturation", "alpha"];
                    	let oldDataCopy = JSON.parse(JSON.stringify(oldData));
                    	var combinedData = this.combineData(oldDataCopy, this.data, "sx", 0, 0);
                        this.dataVizDict["sx"] = combinedData;
                        for (var i = 0; i < params.length; i++) {
                        	//TODO - change to real index
                        	let oldCombinedData = JSON.parse(JSON.stringify(combinedData));
                            combinedData = this.combineData(oldCombinedData, this.data, params[i], 0, 0);
                            this.dataVizDict[params[i]] = combinedData;
                        }
                        // console.log("~~updated datavizDict is now ", this.dataVizDict);
                        this.data = oldData;	
                        console.log("~~ this.data is now ", this.getParam(this.data['behaviors'][0]['brushes'][0]['inspector'], "dx"), this.getParam(oldData['behaviors'][0]['brushes'][0]['inspector'], "dx"));
                        this.processStepData(targetBrushData);
                        console.log("~~~updated data to oldData. new data sx:  ", this.getParam(data['behaviors'][0]['brushes'][0]['inspector'], "dx"), " old data sx: ", this.getParam(this.data['behaviors'][0]['brushes'][0]['inspector'], "dx"));
                    }
                }
            }

            console.log("~~~~~ updated data to ", this.data, " with dx val ", this.getParam(this.data['behaviors'][0]['brushes'][0]['inspector'], "dx"));

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