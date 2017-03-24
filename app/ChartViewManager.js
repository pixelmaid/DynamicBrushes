//ChartViewManager.js
'use strict';
define(["jquery", "app/id", "app/Emitter", "app/ChartView", "app/GeneratorInspector"],

    function($, ID, Emitter, ChartView, GeneratorInspector) {
        var behavior_counter = 1;

        var ChartViewManager = class extends Emitter {

            constructor(model, element) {
                super();
                this.el = $(element);
                this.model = model;
                this.generatorInspector = new GeneratorInspector();
                this.views = {};
                this.currentView = null;
                this.lastAuthoringRequest = null;

                var self = this;

                var add_behavior_btn = $('body').find('#add_behavior_btn');

                add_behavior_btn.click(function(event) {


                    self.addBehavior();
                });


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
                console.log("chart manager process authoring response", data, this.lastAuthoringRequest, data.result);
                if (data.result == "success") {
                    var behaviorId = this.lastAuthoringRequest.data.behaviorId;
                    switch (this.lastAuthoringRequest.data.type) {

                        case "transition_added":
                            console.log("transition added  called");
                            this.views[behaviorId].addOverlayToConnection(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;

                            break;

                        case "transition_event_added":
                            console.log("transition event added called");
                            this.views[behaviorId].addTransitionEvent(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;
                            break;
                        case "mapping_added":
                            console.log("mapping added  called");
                            this.views[behaviorId].addMapping(this.lastAuthoringRequest.data.stateId, this.lastAuthoringRequest.data);
                            // this.lastAuthoringRequest = null;

                            break;

                        case "method_added":
                            console.log("method added  called",data.data.argumentList,data.data);
                            this.lastAuthoringRequest.data.methodArguments = data.data.argumentList;
                             this.lastAuthoringRequest.data.defaultArgument = data.data.defaultArgument;
                            this.views[behaviorId].addMethod(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;
                            break;
                        case "mapping_updated":
                            console.log("mapping updated called");
                            this.views[behaviorId].updateMapping(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;


                            break;
                        case "generator_added":
                            console.log("generator added succesfully");

                            var generator_data = this.lastAuthoringRequest.data;
                            //mappingId, behaviorId, stateId, relativePropertyName, expressionId, expressionText, expressionPropertyList, constraint_type
                            this.views[behaviorId].trigger("ON_MAPPING_REFERENCE_UPDATE", [generator_data.mappingId, generator_data.behaviorId, generator_data.stateId, generator_data.relativePropertyName, generator_data.expressionId,generator_data.expressionText,generator_data.expressionPropertyList, "passive"]);
                            break;
                        case "mapping_relative_removed":
                            console.log("mapping relative removed called");
                            this.views[behaviorId].removeMapping(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;

                            break;
                        case "state_added":
                            this.lastAuthoringRequest.x = this.lastAuthoringRequest.x - $("#" + behaviorId).offset().left;
                            this.lastAuthoringRequest.y = this.lastAuthoringRequest.y - $("#" + behaviorId).offset().top;
                            this.views[behaviorId].newNode(this.lastAuthoringRequest.x, this.lastAuthoringRequest.y, this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;

                            break;
                        case "behavior_added":
                            this.onBehaviorAdded(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;

                            break;
                        case "expression_added":
                            console.log("expression added succesfully");
                            this.lastAuthoringRequest = null;

                            break;
                    }


                } else if (data.result == "fail") {

                    //TODO: error handling code for authoring fail here
                }


            }

            addBehavior() {
                var name = prompt("Give your behavior a name", "behavior_" + behavior_counter);
                if (name !== null) {

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
                        name: name,
                        id: id,
                        states: [setupData, dieData],
                        dieId: dieId,
                        setupId: setupId,
                        transitions: []

                    };
                    this.lastAuthoringRequest = {
                        data: data
                    };
                    behavior_counter++;

                    this.emitter.emit("ON_AUTHORING_EVENT", data);
                }
            }

            onBehaviorAdded(data) {
                console.log("add behavior", data, this);
                var chartView = new ChartView(data.id,data.name);
                chartView.addListener("ON_STATE_CONNECTION", function(connectionId, sourceId, sourceName, targetId, behaviorId) {
                    this.onConnection(connectionId, sourceId, sourceName, targetId, behaviorId);
                }.bind(this));

                chartView.addListener("ON_TRANSITION_EVENT_ADDED", function(connectionId, eventName, displayName, sourceId, sourceName, targetId, behaviorId) {
                    this.onTransitionEventAdded(connectionId, eventName, displayName, sourceId, sourceName, targetId, behaviorId);
                }.bind(this));

                chartView.addListener("ON_MAPPING_ADDED", function(mappingId, name, item_name, type, expressionId, stateId, behaviorId) {
                    this.onMappingAdded(mappingId, name, item_name, type, expressionId, stateId, behaviorId);
                }.bind(this));

                chartView.addListener("ON_METHOD_ADDED", function(behaviorId, transitionId, methodId, targetMethod, args) {
                    this.onMethodAdded(behaviorId, transitionId, methodId, targetMethod, args);
                }.bind(this));

                chartView.addListener("ON_METHOD_ARGUMENT_CHANGE", function(behaviorId, transitionId, methodId, targetMethod, args) {
                    this.onMethodArgumentChanged(behaviorId, transitionId, methodId, targetMethod,args);
                }.bind(this));

                chartView.addListener("ON_GENERATOR_ADDED", function(mappingId, generatorId, generator_type, behaviorId, stateId, itemName, relativePropertyName, expressionId, expressionText, expressionPropertyList) {
                    this.onGeneratorAdded(mappingId, generatorId, generator_type, behaviorId, stateId, itemName, relativePropertyName, expressionId, expressionText, expressionPropertyList);
                }.bind(this));

                chartView.addListener("ON_STATE_ADDED", function(x, y, data) {
                    this.onStateAdded(x, y, data);
                }.bind(this));

                chartView.addListener("ON_EXPRESSION_TEXT_UPDATE", function(behaviorId, expressionId, expressionText, propertyList) {
                    this.onExpressionTextModified(behaviorId, expressionId, expressionText, propertyList);
                }.bind(this));

                chartView.addListener("ON_MAPPING_REFERENCE_UPDATE", function(mappingId, behaviorId, stateId, relativePropertyName, expressionId, expressionText, expressionPropertyList, constraint_type) {
                    this.onMappingReferenceUpdate(mappingId, behaviorId, stateId, relativePropertyName, expressionId, expressionText, expressionPropertyList, constraint_type);
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


            onConnection(connectionId, sourceId, sourceName, targetId, behaviorId) {

                var transmit_data = {
                    fromStateId: sourceId,
                    toStateId: targetId,
                    name: sourceName,
                    id: connectionId,
                    behaviorId: behaviorId,
                    parentFlag: "false",
                    type: "transition_added"
                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };
                console.log("state transition made chart view", this);

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);


            }

            onTransitionEventAdded(connectionId, eventName, displayName, sourceId, sourceName, targetId, behaviorId) {
                console.log("transition event added", connectionId, eventName,displayName);


                var transmit_data = {
                    fromStateId: sourceId,
                    toStateId: targetId,
                    eventName: eventName,
                    displayName: displayName,
                    name: sourceName,
                    id: connectionId,
                    behaviorId: behaviorId,
                    parentFlag: "false",
                    type: "transition_event_added"
                };

                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                console.log("state transition made chart view", this);
                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);
            }

            onMappingAdded(mappingId, name, item_name, type, expressionId, stateId, behaviorId) {
                console.log("mapping added", mappingId, name, stateId);

                var transmit_data = {
                    mappingId: mappingId,
                    behaviorId: behaviorId,
                    relativePropertyItemName: item_name,
                    relativePropertyName: name,
                    stateId: stateId,
                    expressionId: expressionId,
                    constraintType: "active",
                    type: "mapping_added"
                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };



                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);
            }

            onMappingReferenceUpdate(mappingId, behaviorId, stateId, relativePropertyName, expressionId, expressionText, expressionPropertyList, constraint_type) {
                console.log("mapping reference update", mappingId, stateId);

                var transmit_data = {
                    mappingId: mappingId,
                    behaviorId: behaviorId,
                    relativePropertyName: relativePropertyName,
                    stateId: stateId,
                    expressionId: expressionId,
                    expressionText: expressionText,
                    expressionPropertyList: expressionPropertyList,
                    constraintType: constraint_type,
                    type: "mapping_updated"
                };

                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);
            }

            onExpressionTextModified(behaviorId, expressionId, expressionText, propertyList) {

                var transmit_data = {
                    behaviorId: behaviorId,
                    expressionId: expressionId,
                    expressionText: expressionText,
                    expressionPropertyList: propertyList,
                    type: "expression_text_modified"

                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);

            }

            onGeneratorAdded(mappingId, generatorId, generator_type, behaviorId, stateId, itemName, relativePropertyName, expressionId, expressionText, expressionPropertyList) {
                console.log("generator added", generatorId, generator_type, stateId);

                var transmit_data = {
                    mappingId: mappingId,
                    generatorId: generatorId,
                    generator_type: generator_type,
                    behaviorId: behaviorId,
                    stateId: stateId,
                    itemName: itemName,
                    relativePropertyName: relativePropertyName,
                    expressionId: expressionId,
                    expressionText: expressionText,
                    expressionPropertyList: expressionPropertyList,
                    type: "generator_added"
                };
                this.generatorInspector.addDefaultValues(generator_type, transmit_data);
                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);
            }



            onMethodAdded(behaviorId, transitionId, methodId, targetMethod,args) {
                console.log("method added", methodId, targetMethod);

                var transmit_data = {
                    behaviorId: behaviorId,
                    targetTransition: transitionId,
                    methodId: methodId,
                    targetMethod: targetMethod,
                    args: args,
                    type: "method_added"
                };

                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);
            }

            onMethodArgumentChanged(behaviorId, transitionId, methodId, targetMethod,args) {
                console.log("method argument changed", methodId, targetMethod);

                var transmit_data = {
                    behaviorId: behaviorId,
                    targetTransition: transitionId,
                    methodId: methodId,
                    targetMethod: targetMethod,
                    args: args,
                    type: "method_argument_changed"
                };

                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);
            }

            onMappingRelativeRemoved(id, stateId, behaviorId) {
                console.log("mapping relative removed", id, stateId, behaviorId);

                var transmit_data = {
                    mappingId: id,
                    behaviorId: behaviorId,
                    stateId: stateId,
                    type: "mapping_relative_removed"
                };

                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);

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
                this.emitter.emit("ON_AUTHORING_EVENT", transmit_data);
            }

            behaviorChange(data) {
                if (this.views[data.behaviorId]) {
                    console.log("behavior found for ", data.brush_name);
                    this.views[data.behaviorId].behaviorChange(data.event, data.data);
                }
            }



        };

        return ChartViewManager;

    });