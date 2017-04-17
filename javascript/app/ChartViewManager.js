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


                    self.onBehaviorAdded();
                });

                $("#behaviorselect").change(function() {
                    this.changeBehavior();
                }.bind(this));
                //this.model.addListener("ON_ADD_CHART", this.addChart);

            }

            destroyAllViews() {
                for (var i = 0; i < this.views.length; i++) {
                    this.views[i].destroy();
                }
                $('#canvas').empty();
                this.views.length = 0;
            }



            refreshBehaviorDropdown() {
                $("#behaviorselect").empty();

                var behavior_menu = document.getElementById("behaviorselect");
            console.log("views",this.views)
                for (var key in this.views) {
                    if (this.views.hasOwnProperty(key)) {
                        var option = document.createElement('option');
                        option.text = this.views[key].name;
                        option.value = this.views[key].id;
                        behavior_menu.add(option, 0);
                        console.log("adding option", this.views[key].name);
                    }
                }

                $("#behaviorselect").val(this.currentView.id);

            }

            //called when drawing client is sending behavior data to synchronize
            synchronize(sync_data) {
                this.destroyAllViews();
                var behaviorData = sync_data.data;
                console.log("synch called", behaviorData.length);

                for(var i=0;i<behaviorData.length;i++){
                    this.addBehavior(behaviorData[i]);

                }

                this.currentView.resetView();
                var selectedBehaviorData = behaviorData[behaviorData.length-1];
                this.currentView = this.views[selectedBehaviorData.id];

                this.currentView.createHTML(selectedBehaviorData);
                this.currentView.initializeBehavior(selectedBehaviorData);
            }

              addBehavior(data) {
                console.log("add behavior", data, this);
                if (this.currentView) {
                    this.currentView.resetView();
                }
                var chartView = new ChartView(data.id, data.name);
                chartView.addListener("ON_STATE_CONNECTION", function(connectionId, sourceId, sourceName, targetId, behaviorId) {
                    this.onConnection(connectionId, sourceId, sourceName, targetId, behaviorId);
                }.bind(this));


                chartView.addListener("ON_TRANSITION_REMOVED", function(behaviorId, transitionId) {
                    this.onTransitionRemoved(behaviorId, transitionId);
                }.bind(this));


                chartView.addListener("ON_TRANSITION_EVENT_REMOVED", function(behaviorId, transitionId) {
                    this.onTransitionEventRemoved(behaviorId, transitionId);
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
                    this.onMethodArgumentChanged(behaviorId, transitionId, methodId, targetMethod, args);
                }.bind(this));

                chartView.addListener("ON_METHOD_REMOVED", function(behaviorId, methodId) {
                    this.onMethodRemoved(behaviorId, methodId);
                }.bind(this));

                chartView.addListener("ON_GENERATOR_ADDED", function(mappingId, generatorId, generator_type, behaviorId, stateId, relativePropertyName, relativePropertyItemName, expressionId, expressionText, expressionPropertyList) {
                    this.onGeneratorAdded(mappingId, generatorId, generator_type, behaviorId, stateId, relativePropertyName, relativePropertyItemName, expressionId, expressionText, expressionPropertyList);
                }.bind(this));

                chartView.addListener("ON_STATE_ADDED", function(x, y, data) {
                    this.onStateAdded(x, y, data);
                }.bind(this));

                chartView.addListener("ON_STATE_REMOVED", function(behaviorId, stateId) {
                    this.onStateRemoved(behaviorId, stateId);
                }.bind(this));


                chartView.addListener("ON_EXPRESSION_TEXT_UPDATE", function(behaviorId, expressionId, expressionText, propertyList) {
                    this.onExpressionTextModified(behaviorId, expressionId, expressionText, propertyList);
                }.bind(this));

                chartView.addListener("ON_MAPPING_REFERENCE_UPDATE", function(mappingId, behaviorId, stateId, relativePropertyName, relativePropertyItemName, expressionId, expressionText, expressionPropertyList, constraint_type) {
                    this.onMappingReferenceUpdate(mappingId, behaviorId, stateId, relativePropertyName, relativePropertyItemName, expressionId, expressionText, expressionPropertyList, constraint_type);
                }.bind(this));

                chartView.addListener("ON_MAPPING_REFERENCE_REMOVED", function(behaviorId, expressionId, expressionPropertyList, expressionText) {
                    this.onMappingReferenceRemoved(behaviorId, expressionId, expressionPropertyList, expressionText);
                }.bind(this));


                chartView.addListener("ON_MAPPING_RELATIVE_REMOVED", function(behaviorId, mappingId, stateId) {
                    this.onMappingRelativeRemoved(behaviorId, mappingId, stateId);
                }.bind(this));


                chartView[data.id] = chartView;
                chartView.initializeBehavior(data);
                this.views[data.id] = chartView;
                this.currentView = chartView;
                this.refreshBehaviorDropdown();
                console.log("add behavior", data, this.currentView);

            }

            changeBehavior() {
                var selectedId = $("#behaviorselect").val();
                console.log("change behavior to", selectedId);
                var transmit_data = {
                    behaviorId: selectedId,
                    type: "request_behavior_json"
                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);


            }

            switchBehavior(data) {
                var behaviorData = data;
                this.currentView.resetView();
                this.currentView = this.views[behaviorData.id];

                this.currentView.createHTML(behaviorData);
                this.currentView.initializeBehavior(data);
            }

            processAuthoringResponse(data) {
                console.log("chart manager process authoring response", data, this.lastAuthoringRequest, data.result);
                if (data.result == "success") {
                    var behaviorId = this.lastAuthoringRequest.data.behaviorId;
                    switch (this.lastAuthoringRequest.data.type) {

                        case "request_behavior_json":
                            console.log("request behavior json called", data.data);
                            this.switchBehavior(data.data);

                            break;

                        case "transition_added":
                            console.log("transition added  called");
                            this.views[behaviorId].addOverlayToConnection(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;

                            break;

                        case "transition_removed":
                            console.log("transition removed  called");
                            this.views[behaviorId].removeTransition(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;

                            break;

                        case "transition_event_added":
                            console.log("transition event added called");
                            this.views[behaviorId].addTransitionEvent(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;
                            break;

                        case "transition_event_removed":
                            console.log("transition event removed called");
                            this.lastAuthoringRequest.data.eventName = "STATE_COMPLETE";
                            this.lastAuthoringRequest.data.displayName = "stateComplete";
                            this.views[behaviorId].addTransitionEvent(this.lastAuthoringRequest.data);

                            break;

                        case "mapping_added":
                            console.log("mapping added  called");
                            this.views[behaviorId].addMapping(this.lastAuthoringRequest.data);
                            // this.lastAuthoringRequest = null;

                            break;

                        case "method_added":
                            console.log("method added  called", data.data.argumentList, data.data);
                            this.lastAuthoringRequest.data.methodArguments = data.data.methodArguments;
                            this.lastAuthoringRequest.data.defaultArgument = data.data.defaultArgument;
                            this.views[behaviorId].addMethod(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;
                            break;
                        case "method_removed":
                            this.views[behaviorId].removeMethod(this.lastAuthoringRequest.data);
                            break;
                        case "mapping_updated":
                            console.log("mapping updated called");
                            this.views[behaviorId].updateMapping(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;


                            break;
                        case "generator_added":
                            console.log("generator added succesfully");

                            var generator_data = this.lastAuthoringRequest.data;
                            this.views[behaviorId].trigger("ON_MAPPING_REFERENCE_UPDATE", [generator_data.mappingId, generator_data.behaviorId, generator_data.stateId, generator_data.relativePropertyName, generator_data.relativePropertyItemName, generator_data.expressionId, generator_data.expressionText, generator_data.expressionPropertyList, "passive"]);
                            break;
                        case "mapping_relative_removed":
                            console.log("mapping relative removed called");
                            this.views[behaviorId].removeMapping(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;

                            break;
                        case "state_added":

                            this.views[behaviorId].newNode(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;

                            break;
                        case "state_removed":
                            console.log("state removed  called");
                            this.views[behaviorId].removeState(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;

                            break;
                        case "behavior_added":
                            this.addBehavior(this.lastAuthoringRequest.data);
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

            onBehaviorAdded() {
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
                        transitions: [],
                        mappings: [],
                        methods: []

                    };
                    this.lastAuthoringRequest = {
                        data: data
                    };
                    behavior_counter++;

                    this.emitter.emit("ON_AUTHORING_EVENT", data);
                }
            }

          


            onConnection(connectionId, sourceId, sourceName, targetId, behaviorId) {

                var transmit_data = {
                    fromStateId: sourceId,
                    toStateId: targetId,
                    name: sourceName,
                    eventName: "STATE_COMPLETE",
                    displayName: "stateComplete",
                    transitionId: connectionId,
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
                console.log("transition event added", connectionId, eventName, displayName);


                var transmit_data = {
                    fromStateId: sourceId,
                    toStateId: targetId,
                    eventName: eventName,
                    displayName: displayName,
                    name: sourceName,
                    transitionId: connectionId,
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

            onTransitionRemoved(behaviorId, transitionId) {

                var transmit_data = {
                    transitionId: transitionId,
                    behaviorId: behaviorId,
                    type: "transition_removed"
                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);


            }

            onTransitionEventRemoved(behaviorId, transitionId) {

                var transmit_data = {
                    transitionId: transitionId,
                    behaviorId: behaviorId,
                    type: "transition_event_removed"
                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };

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
                    constraintType: "passive",
                    type: "mapping_added"
                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };



                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);
            }

            onMappingReferenceUpdate(mappingId, behaviorId, stateId, relativePropertyName, relativePropertyItemName, expressionId, expressionText, expressionPropertyList, constraint_type) {
                console.log("mapping reference update", mappingId, stateId);

                var transmit_data = {
                    mappingId: mappingId,
                    behaviorId: behaviorId,
                    relativePropertyName: relativePropertyName,
                    relativePropertyItemName: relativePropertyItemName,
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

            //TODO: will need to re-enabled passive constraint here?
            onMappingReferenceRemoved(behaviorId, expressionId, expressionPropertyList, expressionText) {
                console.log("mapping reference removed", expressionId, expressionPropertyList);

                var transmit_data = {
                    behaviorId: behaviorId,
                    expressionId: expressionId,
                    expressionText: expressionText,
                    expressionPropertyList: expressionPropertyList,
                    type: "mapping_reference_removed"
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

            onGeneratorAdded(mappingId, generatorId, generator_type, behaviorId, stateId, relativePropertyName, relativePropertyItemName, expressionId, expressionText, expressionPropertyList) {
                console.log("generator added", generatorId, generator_type, stateId);

                var transmit_data = {
                    mappingId: mappingId,
                    generatorId: generatorId,
                    generator_type: generator_type,
                    behaviorId: behaviorId,
                    stateId: stateId,
                    relativePropertyName: relativePropertyName,
                    relativePropertyItemName: relativePropertyItemName,
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



            onMethodAdded(behaviorId, transitionId, methodId, targetMethod, args) {
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

            onMethodArgumentChanged(behaviorId, transitionId, methodId, targetMethod, args) {
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

            onMethodRemoved(behaviorId, methodId) {
                console.log("method removed ", methodId, behaviorId);

                var transmit_data = {
                    behaviorId: behaviorId,
                    methodId: methodId,
                    type: "method_removed"
                };

                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);
            }

            onMappingRelativeRemoved(behaviorId, mappingId, stateId) {
                console.log("mapping relative removed", mappingId, stateId, behaviorId);

                var transmit_data = {
                    mappingId: mappingId,
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
                data.x = x - $("#" + data.behaviorId).offset().left;
                data.y = y - $("#" + data.behaviorId).offset().top;
                console.log("state created", transmit_data);
                this.lastAuthoringRequest = {
                    data: transmit_data
                };
                this.emitter.emit("ON_AUTHORING_EVENT", transmit_data);
            }

            onStateRemoved(behaviorId, stateId) {
                var transmit_data = {
                    behaviorId: behaviorId,
                    stateId: stateId,
                    type: "state_removed"
                };

                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);

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