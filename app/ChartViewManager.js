//ChartViewManager.js
'use strict';
define(["jquery", "app/Emitter", "app/ChartView"],

    function($, Emitter, ChartView) {

        var ChartViewManager = class extends Emitter {

            constructor(model, element) {
                super();
                this.el = $(element);
                this.model = model;
                this.views = {};
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
                    var behavior_id = this.lastAuthoringRequest.data.behavior_id;
                    switch (this.lastAuthoringRequest.data.type) {

                        case "transition_added":
                            console.log("transition added  called");
                            this.views[behavior_id].addOverlayToConnection(this.lastAuthoringRequest.data);
                            break;
                        case "mapping_added":
                            console.log("transition added  called");
                           this.views[behavior_id].addMapping(this.lastAuthoringRequest.data.targetState, this.lastAuthoringRequest.data);
                            break;
                        case "mapping_updated":
                            console.log("mapping updated called");
                           //this.views[behavior_id].addMapping(this.lastAuthoringRequest.data.targetState, this.lastAuthoringRequest.data);
                            break;

                        case "state_added":
                            this.views[behavior_id].newNode(this.lastAuthoringRequest.x, this.lastAuthoringRequest.y, this.lastAuthoringRequest.data);
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
                chartView.addListener("ON_STATE_CONNECTION", function(connectionId, sourceId, targetId,behaviorId) {
                    this.onConnection(connectionId, sourceId, targetId,behaviorId);
                }.bind(this));
                chartView.addListener("ON_MAPPING_ADDED", function(id, name, targetStateId,behaviorId) {
                    this.onMappingAdded(id, name, targetStateId,behaviorId);
                }.bind(this));
                chartView.addListener("ON_STATE_ADDED", function(x, y, data) {
                    this.onStateAdded(x, y, data);
                }.bind(this));
                 chartView.addListener("ON_MAPPING_REFERENCE_UPDATE", function(id,behaviorId,targetState,relativePropertyName,referenceProperty,referenceNames) {
                    this.onMappingReferenceUpdate(id,behaviorId,targetState,relativePropertyName,referenceProperty,referenceNames);
                }.bind(this));
                chartView[data.id] = chartView;
                chartView.initializeBehavior(data);
                this.views[data.id] = chartView;
                this.currentView = chartView;
                console.log("add behavior", data, this.currentView);

            }


            onConnection(connectionId, sourceId, targetId,behaviorId) {

                var transmit_data = {
                    fromStateId: sourceId,
                    toStateId: targetId,
                    name: "placeholder_name",
                    event: "STATE_COMPLETE",
                    id: connectionId,
                    behavior_id: behaviorId,
                    parentFlag: "false",
                    type: "transition_added"
                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };
                console.log("state transition made chart view", this);

                this.trigger("ON_STATE_CONNECTION", [transmit_data]);


            }

            onMappingAdded(id, name, targetStateId,behaviorId) {
                console.log("mapping added", id, name, targetStateId);

                var transmit_data = {
                    id: id,
                    behavior_id: behaviorId,
                    relativePropertyName: name,
                    targetState: targetStateId,
                    type: "mapping_added"
                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_MAPPING_ADDED", [transmit_data]);
            }

            onMappingReferenceUpdate(id,behaviorId,targetState,relativePropertyName,referenceProperty,referenceNames){
                console.log("mapping reference update", id, name, targetState);

                var transmit_data = {
                    id: id,
                    behavior_id: behaviorId,
                    relativePropertyName: relativePropertyName,
                    targetState: targetState,
                    referenceProperty:referenceProperty,
                    referenceNames:referenceNames,
                    type: "mapping_updated"
                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_MAPPING_ADDED", [transmit_data]);
            }

            onStateAdded(x, y, data) {

                var transmit_data = data;
                data.type = "state_added";


                console.log("state created", transmit_data);
                this.lastAuthoringRequest = {
                    x: x,
                    y: y,
                    data: transmit_data
                };
                this.emitter.emit("ON_STATE_ADDED", transmit_data);
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