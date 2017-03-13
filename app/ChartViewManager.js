//ChartViewManager.js
'use strict';
define(["jquery", "app/id", "app/Emitter", "app/ChartView"],

    function($, ID, Emitter, ChartView) {

        var ChartViewManager = class extends Emitter {

            constructor(model, element) {
                super();
                this.el = $(element);
                this.model = model;
                this.views = {};
                this.currentView = null;
                this.lastAuthoringRequest = null;

                var self = this;

                var add_behavior_btn = $('body').find('#add_behavior_btn');

                add_behavior_btn.click(function(event) {


                    self.addBehavior();
                });

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
                console.log("chart manager process authoring response", data);
                if (data.result == "success") {
                    var behavior_id = this.lastAuthoringRequest.data.behavior_id;
                    switch (this.lastAuthoringRequest.data.type) {

                        case "transition_added":
                            console.log("transition added  called");
                            this.views[behavior_id].addOverlayToConnection(this.lastAuthoringRequest.data);
                            break;
                        case "mapping_added":
                            console.log("transition added  called");
                            this.views[behavior_id].addMapping(this.lastAuthoringRequest.data.stateId, this.lastAuthoringRequest.data);
                            break;
                        case "mapping_updated":
                            console.log("mapping updated called");
                            this.views[behavior_id].updateMapping(this.lastAuthoringRequest.data);
                            break;
                        case "mapping_relative_removed":
                            console.log("mapping relative removed called");
                            this.views[behavior_id].removeMapping(this.lastAuthoringRequest.data);
                            break;
                        case "state_added":
                            this.lastAuthoringRequest.x = this.lastAuthoringRequest.x - $("#" + behavior_id).offset().left;
                            this.lastAuthoringRequest.y = this.lastAuthoringRequest.y - $("#" + behavior_id).offset().top;
                            this.views[behavior_id].newNode(this.lastAuthoringRequest.x, this.lastAuthoringRequest.y, this.lastAuthoringRequest.data);
                            break;
                        case "behavior_added":
                            this.onBehaviorAdded(this.lastAuthoringRequest.data);
                            break;
                    }

                    this.lastAuthoringRequest = null;
                } else if (data.result == "fail") {

                    //TODO: error handling code for authoring fail here
                }


            }

            addBehavior() {
                var id = ID();
                var dieId = ID();
                var setupId = ID();

                var setupData = {
                    name: "setup",
                    id: setupId,
                    mappings: [],
                    x: 20,
                    y: 150
                };

                var dieData = {
                    name: "die",
                    id: dieId,
                    mappings: [],
                    x: 1000,
                    y: 150
                };

                var data = {
                    type: "behavior_added",
                    name: "behavior_" + id,
                    id: id,
                    states: [setupData, dieData],
                    dieId: dieId,
                    setupId: setupId,
                    transitions: []

                };
                this.lastAuthoringRequest = {
                    data: data
                };
                this.emitter.emit("ON_BEHAVIOR_ADDED", data);
            }

            onBehaviorAdded(data) {
                console.log("add behavior", data, this);
                var chartView = new ChartView(data.id);
                chartView.addListener("ON_STATE_CONNECTION", function(connectionId, sourceId, sourceName, targetId, targetName, behaviorId) {
                    this.onConnection(connectionId, sourceId, sourceName, targetId, targetName, behaviorId);
                }.bind(this));
                chartView.addListener("ON_MAPPING_ADDED", function(id, name, item_name, type, stateId, behaviorId) {
                    this.onMappingAdded(id, name, item_name, type, stateId, behaviorId);
                }.bind(this));
                chartView.addListener("ON_STATE_ADDED", function(x, y, data) {
                    this.onStateAdded(x, y, data);
                }.bind(this));
                chartView.addListener("ON_MAPPING_REFERENCE_UPDATE", function(id, reference_type, behaviorId, stateId, itemName, relativePropertyName, referenceProperty, referenceNames) {
                    this.onMappingReferenceUpdate(id, reference_type, behaviorId, stateId, itemName, relativePropertyName, referenceProperty, referenceNames);
                }.bind(this));
                chartView.addListener("ON_MAPPING_RELATIVE_REMOVED", function(id, stateId, behaviorId) {
                    this.onMappingRelativeRemoved(id, stateId, behaviorId);
                }.bind(this));
                chartView[data.id] = chartView;
                chartView.initializeBehavior(data);
                this.views[data.id] = chartView;
                this.currentView = chartView;
                console.log("add behavior", data, this.currentView);

            }


            onConnection(connectionId, sourceId,sourceName, targetId, targetName,behaviorId) {
                console.log("source name,target name",sourceName,targetName);
                var name = sourceName;

                var transmit_data = {
                    fromStateId: sourceId,
                    toStateId: targetId,
                    name: name,
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

            onMappingAdded(id, name, item_name, type, stateId, behaviorId) {
                console.log("mapping added", id, name, stateId);

                var transmit_data = {
                    mappingId: id,
                    behavior_id: behaviorId,
                    relativePropertyItemName: item_name,
                    relativePropertyName: name,
                    relativePropertyType: type,
                    stateId: stateId,
                    type: "mapping_added"
                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_MAPPING_ADDED", [transmit_data]);
            }

            onMappingReferenceUpdate(id, reference_type, behaviorId, stateId, itemName, relativePropertyName, referenceProperty, referenceNames) {
                console.log("mapping reference update", id, itemName, stateId);

                var transmit_data = {
                    id: id,
                    behavior_id: behaviorId,
                    relativePropertyName: relativePropertyName,
                    stateId: stateId,
                    referenceProperty: referenceProperty,
                    referenceNames: referenceNames,
                    itemName: itemName,
                    reference_type: reference_type,
                    type: "mapping_updated"
                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_MAPPING_ADDED", [transmit_data]);
            }

            onMappingRelativeRemoved(id, stateId, behaviorId){
                console.log("mapping relative removed", id, stateId, behaviorId);

                var transmit_data = {
                    mappingId: id,
                    behavior_id: behaviorId,
                    stateId: stateId,
                    type: "mapping_relative_removed"
                };

                this.lastAuthoringRequest = {
                    data: transmit_data
                };
 
                 this.trigger("ON_MAPPING_RELATIVE_REMOVED", [transmit_data]);

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