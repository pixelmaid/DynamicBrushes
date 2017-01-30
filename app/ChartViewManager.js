//ChartViewManager.js
'use strict';
define(["jquery", "app/Emitter", "app/ChartView"],

    function($, Emitter, ChartView) {

        var ChartViewManager = class extends Emitter {

            constructor(model, element) {
                super();
                this.el = $(element);
                this.model = model;
                this.views = [];
                this.currentView = null;
                this.lastAuthoringRequest = null;

                var self = this;


                this.model.addListener("ON_INITIALIZE_STATE", function(x, y, data) {
                    this.addState(x, y, data);
                }.bind(this));
                this.model.addListener("ON_INITIALIZE_BEHAVIOR", function(data) {
                    this.addBehavior(data);
                }.bind(this));

                //this.model.addListener("ON_ADD_CHART", this.addChart);

            }

            destroyAllCharts() {
                /* for(var i=0;i<this.views.length;i++){
                   this.views[i].destroy();
                  }*/
                $('#canvas').empty();
                this.views.length = 0;
            }


            processAuthoringResponse(data) {
                if (data.result == "success") {
                    switch (this.lastAuthoringRequest.data.type) {

                        case "transition_added":
                            console.log("transition added  called");
                            this.currentView.addOverlayToConnection(this.lastAuthoringRequest.data);
                            break;
                        case "mapping_added":
                            console.log("transition added  called");
                            this.currentView.addMapping(  this.lastAuthoringRequest.data.targetState, this.lastAuthoringRequest.data);
                            break;


                    }

                    this.lastAuthoringRequest = null;
                } else if (data.result == "fail") {

                    //TODO: error handling code for authoring fail here
                }


            }

            addBehavior(data) {
                console.log("add behavior", data, this);
                var chartView = new ChartView(data.id);
                chartView.addListener("ON_STATE_CONNECTION", function(connectionId, sourceId, targetId) {
                    this.onConnection(connectionId, sourceId, targetId);
                }.bind(this));
                  chartView.addListener("ON_MAPPING_ADDED", function(id,name,targetStateId) {
                    this.onMappingAdded(id,name,targetStateId);
                }.bind(this));
                chartView[data.id] = chartView;
                chartView.initializeBehavior(data);
                this.views.push(chartView);
                this.currentView = chartView;
                console.log("add behavior", data, this.currentView);

            }

            addState(x, y, data) {
                console.log("add state", x, y, data);
                this.currentView.newNode(x, y, data);
            }

            onConnection(connectionId, sourceId, targetId) {

                var transmit_data = {
                    fromStateId: sourceId,
                    toStateId: targetId,
                    name: "placeholder_name",
                    event: "STATE_COMPLETE",
                    id: connectionId,
                    parentFlag: "false",
                    type: "transition_added"
                };
                this.lastAuthoringRequest = {data:transmit_data};
                console.log("state transition made chart view", this);

                this.trigger("ON_STATE_CONNECTION", [transmit_data]);


            }

            onMappingAdded(id,name,targetStateId){
                console.log("mapping added",id,name,targetStateId);

                var transmit_data = {
                    id: id,
                    relativePropertyName: name,
                    targetState: targetStateId,
                    type: "mapping_added"
                };
                this.lastAuthoringRequest = {data:transmit_data};

                this.trigger("ON_MAPPING_ADDED", [transmit_data]);
            }

            behaviorChange(data) {
                if (this.views[data.behavior_id]) {
                    console.log("behavior found for ", data.brush_name);
                    this.views[data.behavior_id].behaviorChange(data.event, data.data);
                }
            }



        };

        return ChartViewManager;

    });