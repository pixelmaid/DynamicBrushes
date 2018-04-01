//ChartViewManager.js
'use strict';
define(["jquery", "app/id", "app/Emitter", "app/ChartView", "app/GeneratorModel", "hbs!app/templates/behavioritem", "app/InspectorDataController"],

    function($, ID, Emitter, ChartView, GeneratorModel, BehaviorItemTemplate, InspectorDataController) {
        var behavior_counter = 1;
        var spaceDown = false;
        var cmmd_down = false;
        var zoomAmount = 1;
        var mousePosition = {
            clientX: 0,
            clientY: 0
        };
        var basic_template, empty_template, parent_template, child_template, ui_template, timer_template, brush_properties, actions;
        var ChartViewManager = class extends Emitter {


            constructor(model, element) {

                super();
                this.el = $(element);
                this.model = model;
                this.generatorModel = new GeneratorModel();
                this.views = {};
                this.currentView = null;
                this.lastAuthoringRequest = null;

                var self = this;

                var add_behavior_btn = $('body').find('#add_behavior_btn');

                add_behavior_btn.click(function(event) {
                    document.getElementById("behavior_template_menu").classList.toggle("show");
                });

                $.getJSON("app/behavior_templates/basic_template.json", function(data) {
                    basic_template = data;
                });
                $.getJSON("app/behavior_templates/empty_template.json", function(data) {
                    empty_template = data;
                });
                $.getJSON("app/behavior_templates/parent_template.json", function(data) {
                    parent_template = data;
                });
                $.getJSON("app/behavior_templates/child_template.json", function(data) {
                    child_template = data;
                });
                $.getJSON("app/behavior_templates/ui_template.json", function(data) {
                    ui_template = data;
                });

                 $.getJSON("app/behavior_templates/timer_template.json", function(data) {
                    timer_template = data;
                });

                  $.getJSON("app/presets/brush_props.json", function(data) {
                    brush_properties = data;
                });

                  $.getJSON("app/presets/actions.json", function(data) {
                    actions = data;
                });

                //let $("#behavior_items")

                window.onclick = function(event) {
                    if (!event.target.matches('.dropbtn')) {

                        var dropdowns = document.getElementsByClassName("dropdown-content");
                        var i;
                        for (i = 0; i < dropdowns.length; i++) {
                            var openDropdown = dropdowns[i];
                            if (openDropdown.classList.contains('show')) {
                                openDropdown.classList.remove('show');
                            }
                        }
                    }
                };

                $( "#canvas" ).dblclick(function(e) {
                    console.log("dblclick",self.currentView);
                    if(self.currentView !== null){
                        self.currentView.activateStateMenu(e.pageX, e.pageY);
                    }
                 });
                
                $("#behavior_template_menu span").click(function(event) {


                    var type = $(event.target).html();
                    console.log("type = ", type, event.target);
                    var data;
                    switch (type) {
                        case "basic":
                            data = basic_template;
                            break;
                        case "empty":
                            data = empty_template;
                            break;
                        case "timer":
                            data = timer_template;
                            break;
                        case "parent":
                            data = parent_template;
                            break;
                        case "child":
                            data = child_template;
                            break;
                        case "ui defaults":
                            data = ui_template;
                            break;

                    }
                    var data_clone = {};
                    Object.assign(data_clone, data);
                    console.log("data", data, data_clone);
                    self.onBehaviorAdded(data_clone);
                });

                $("#behaviorselect").change(function() {
                    this.changeBehavior();
                }.bind(this));

                $("#zoom_select").change(function() {
                    zoomAmount = parseFloat($("#zoom_select").val());
                    var pos = {
                        clientX: $(document).width() / 2,
                        clientY: $(document).height() / 2
                    };
                    self.currentView.zoom(zoomAmount, pos);

                });

                document.onmousemove = function(event) {
                    mousePosition.clientX = event.clientX;
                    mousePosition.clientY = event.clientY;
                };


                document.onkeyup = function(e) {
                    console.log("keyup", e, self.currentView);
                    if (e.keyCode == 32) {
                        if (self.currentView) {
                            self.currentView.disablePan();
                        }
                        spaceDown = false;
                    }
                    if (e.keyCode == 91) {
                        cmmd_down = false;
                    }
                };

                document.onkeydown = function(e) {
                    if (e.keyCode == 91) {
                        cmmd_down = true;
                    }

                    if (e.keyCode == 32) {

                        if (self.currentView && !spaceDown) {
                            self.currentView.enablePan();
                        }
                        spaceDown = true;
                    } /*else if (e.keyCode == 187) {
                        if (self.currentView) {
                            if (zoomAmount < 1) {
                                zoomAmount += 0.1;
                                self.currentView.zoom(zoomAmount, mousePosition);
                            }
                        }
                    } else if (e.keyCode == 189) {
                        if (self.currentView) {

                            zoomAmount -= 0.1;
                            self.currentView.zoom(zoomAmount, mousePosition);
                        }
                    }*/

                };



            }

            destroyAllViews() {
                for (var i = 0; i < this.views.length; i++) {
                    this.views[i].destroy();
                }
                $('#canvas').empty();
                this.views = {};
            }



            refreshBehaviorList() {
                console.log("refresh behavior dropdown", this.views);
                var self = this;
                $("#behaviorselect").empty();

                var behavior_menu = $("#behaviorselect");
                console.log("views", this.views);
                for (var key in this.views) {
                    if (this.views.hasOwnProperty(key)) {
                        if (this.views[key].name) {
                            var cur_id = this.views[key].id;
                            var name = this.views[key].name;
                            var active_status = this.views[key].active_status;
                            var option = BehaviorItemTemplate(this.views[key]);
                            behavior_menu.append(option);
                            self.addBehaviorListItem(cur_id, active_status, name);
                            console.log("adding option", this.views[key].name);
                        }
                    }
                }


            }

            removeBehavior(behaviorId) {
                console.log("remove behavior from list", behaviorId);

                delete this.views[behaviorId];
                if (this.currentView.id == behaviorId) {
                    if (Object.keys(this.views).length > 0) {
                        var targetView = this.views[Object.keys(this.views)[0]];
                        this.changeBehavior(targetView.id);
                    } else {
                        this.clearCurrentBehavior();
                        this.refreshBehaviorList();
                    }

                } else {
                    this.refreshBehaviorList();
                }
            }

            deselectAllBehaviors() {
                for (var key in this.views) {
                    if (this.views.hasOwnProperty(key)) {
                        if (this.views[key].name) {
                            var id = this.views[key].id;
                            $("li#" + id).removeClass("selected");
                        }
                    }
                }
            }

            addBehaviorListItem(id, active_status, name) {
                var self = this;
                if (this.currentView && this.currentView.id == id) {
                    $("li#" + id).addClass("selected");
                }
                $("li#" + id + " .name").click(function(event) {
                    self.deselectAllBehaviors();
                    $("li#" + id).addClass("selected");
                    self.changeBehavior(id);
                });
                var active_toggle = $("#" + id + " .active_toggle");
                var trash_toggle = $("#" + id + " .trash");
                var refresh_button = $("#" + id + " .refresh");

                if (active_status) {
                    active_toggle.addClass("active");
                }

                active_toggle.click(function(event) {

                    if (!active_toggle.hasClass("active")) {
                        active_toggle.addClass("active");
                        self.views[id].active_status = true;
                        self.onActiveStatusChanged(id, true);

                    } else {
                        active_toggle.removeClass("active");
                        self.views[id].active_status = false;
                        self.onActiveStatusChanged(id, false);
                    }

                });

                trash_toggle.click(function(event) {
                    if (confirm("this will delete" + name)) {
                        self.onDeleteBehavior(id);
                    }

                });

                refresh_button.click(function(event) {

                    self.onRefreshBehavior(id);


                });
            }

            //called when drawing client is sending behavior data to synchronize
            synchronize(sync_data) {
                this.destroyAllViews();
                this.refreshBehaviorList();

                var behaviorData = sync_data;
                console.log("synch called", behaviorData.length);

                for (var i = 0; i < behaviorData.length; i++) {
                    this.addBehavior(behaviorData[i]);

                }

                this.currentView.resetView();
                var selectedBehaviorData = behaviorData[behaviorData.length - 1];
                this.currentView = this.views[selectedBehaviorData.id];

                this.currentView.createHTML(selectedBehaviorData);
                this.currentView.initializeBehavior(selectedBehaviorData);
            }

             updateProperties(prop_data){
                this.currentView.updateProperties(prop_data.data);
             }

            addBehavior(data) {
                console.log("add behavior", data, this);
                if (this.currentView) {
                    this.currentView.resetView();
                }

                var chartView = new ChartView(data.id, data.name, data.active_status, brush_properties, actions);
                chartView.addListener("ON_STATE_CONNECTION", function(behaviorId, transitionId, name, fromStateId, toStateId, conditionId, condition, referenceA,referenceB) {
                    this.onConnection(behaviorId, transitionId, name, fromStateId, toStateId, conditionId, condition, referenceA,referenceB);
                }.bind(this));


                chartView.addListener("ON_TRANSITION_REMOVED", function(behaviorId, transitionId) {
                    this.onTransitionRemoved(behaviorId, transitionId);
                }.bind(this));
                    //self.trigger("ON_CONDITION_RELATIONAL_CHANGED",[behaviorId,transitionData.conditionId,relational])

                chartView.addListener("ON_CONDITION_RELATIONAL_CHANGED", function(behaviorId, conditionId, relational) {
                    this.onConditionRelationalChanged(behaviorId, conditionId, relational);
                }.bind(this));

                chartView.addListener("ON_MAPPING_ADDED", function(mappingId, name, fieldName, type, expressionId, stateId, behaviorId) {
                    this.onMappingAdded(mappingId, name, fieldName, type, expressionId, stateId, behaviorId);
                }.bind(this));

                chartView.addListener("ON_METHOD_ADDED", function(behaviorId, transitionId, methodId, fieldName, displayName, argumentList) {
                    this.onMethodAdded(behaviorId, transitionId, methodId, fieldName, displayName, argumentList);
                }.bind(this));

              

                chartView.addListener("ON_METHOD_REMOVED", function(behaviorId, methodId) {
                    this.onMethodRemoved(behaviorId, methodId);
                }.bind(this));


                chartView.addListener("ON_DATASET_ADDED", function(mappingId, datasetId, datasetType, behaviorId, stateId, relativePropertyName, relativePropertyFieldName, expressionId, expressionText, expressionPropertyList) {
                    this.onDatasetAdded(mappingId, datasetId, datasetType, behaviorId, stateId, relativePropertyName, relativePropertyFieldName, expressionId, expressionText, expressionPropertyList);
                }.bind(this));

                chartView.addListener("ON_STATE_ADDED", function(behaviorId, stateId, stateName, x, y)  {
                    this.onStateAdded(behaviorId, stateId, stateName, x, y);
                }.bind(this));

                chartView.addListener("ON_STATE_MOVED", function(behaviorId, stateId, x, y) {
                    this.onStateMoved(behaviorId, stateId, x, y);
                }.bind(this));

                chartView.addListener("ON_STATE_REMOVED", function(behaviorId, stateId) {
                    this.onStateRemoved(behaviorId, stateId);
                }.bind(this));


                chartView.addListener("ON_EXPRESSION_MODIFIED", function(behaviorId, expressionId, expressionText, propertyList,generatorId,generatorType) {
                    this.onExpressionModified(behaviorId, expressionId, expressionText, propertyList,generatorId,generatorType);
                }.bind(this));


                chartView.addListener("ON_MAPPING_REMOVED", function(behaviorId, mappingId, stateId) {
                    this.onMappingRemoved(behaviorId, mappingId, stateId);
                }.bind(this));

                 chartView.addListener("ON_MAPPING_DATA_REQUEST", function(behaviorId) {
                    this.onMappingDataRequest(behaviorId);
                }.bind(this));


                chartView[data.id] = chartView;
                chartView.initializeBehavior(data);
                this.views[data.id] = chartView;
                this.currentView = chartView;
                this.refreshBehaviorList();
                console.log("add behavior", data, this.currentView);

            }

            changeBehavior(selectedId) {
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


            clearCurrentBehavior() {
                this.currentView.resetView();
                this.currentView = null;
            }

            switchBehavior(data) {
                var behaviorData = data;
                this.clearCurrentBehavior();
                this.currentView = this.views[behaviorData.id];

                this.currentView.createHTML(behaviorData);
                this.currentView.initializeBehavior(data);
                this.refreshBehaviorList();

            }

            processInspectorData(data){
                if(data.type == "signal_data"){
                  InspectorDataController.setData(data);
                }
                else if(data.type == "state_transition"){
                    console.log("state transition data",data,$("#"+data.toState+" .state"));
                     $("#"+data.fromState+" .state").removeClass("active");

                    $("#"+data.toState+" .state").addClass("active");


                }
            }


            processAuthoringResponse(data) {
                console.log("chart manager process authoring response", data, this.lastAuthoringRequest, data.result);
                if (data.result == "success" || data.result == "check") {
                    if(data.authoring_type == "dataset_loaded"){
                        return;
                    }
                    var behaviorId = this.lastAuthoringRequest.data.behaviorId;
                    switch (this.lastAuthoringRequest.data.type) {

                        case "request_behavior_json":
                            console.log("request behavior json called", data.data);
                            this.switchBehavior(data.data);

                            break;

                        case "transition_added":
                            console.log("transition added  called");
                            this.views[behaviorId].addOverlayToConnection(this.lastAuthoringRequest.data,this.lastAuthoringRequest.data.condition);

                            this.lastAuthoringRequest = null;

                            break;

                        case "transition_removed":
                            console.log("transition removed  called");
                            this.views[behaviorId].removeTransition(this.lastAuthoringRequest.data);
                            this.lastAuthoringRequest = null;

                            break;

                        case "relational_changed":
                            console.log("relational changed called");
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
                            console.log("method added  called", data.data);
                            
                            this.views[behaviorId].addMethod(data.data);
                            this.lastAuthoringRequest = null;
                            break;

                        case "method_removed":
                            this.views[behaviorId].removeMethod(this.lastAuthoringRequest.data);
                            break;
                        case "expression_modified":
                            console.log("expression_modified updated called");  
                            this.lastAuthoringRequest = null;
                            break;
                        
                        case "mapping_removed":
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
                            this.addBehavior(this.lastAuthoringRequest.data["data"]);
                            this.lastAuthoringRequest = null;

                            break;
                        case "delete_behavior_request":
                            if (data.result == "check") {
                                if (!confirm("This behavior is referenced by other behaviors. Deleting it will cause the spawn methods in these behaviors stop working. Do you still want to delete it?")) {
                                    return;
                                }

                            }
                            this.onHardDeleteBehavior(this.lastAuthoringRequest.data.behaviorId);

                            break;
                        case "hard_delete_behavior":
                            this.removeBehavior(this.lastAuthoringRequest.data.behaviorId);
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

            onBehaviorAdded(template) {
                var name = prompt("Give your behavior a name", "behavior_" + behavior_counter);
                if (name !== null) {

                    var id = ID();

                    template["default"]["id"] = id;
                    template["default"]["name"] = name;

                    var data = {
                        type: "behavior_added",
                        id: id,
                        name: name,
                        data: template["default"]

                    };
                    this.lastAuthoringRequest = {
                        data: data
                    };
                    behavior_counter++;

                    this.emitter.emit("ON_AUTHORING_EVENT", data);
                }
            }


            onActiveStatusChanged(behaviorId, active_status) {

                var transmit_data = {
                    behaviorId: behaviorId,
                    active_status: active_status,
                    type: "set_behavior_active"
                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };
                console.log("active status set", active_status, behaviorId);

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);
            }

            onRefreshBehavior(behaviorId) {
                var transmit_data = {
                    behaviorId: behaviorId,
                    type: "refresh_behavior"
                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };
                console.log("refresh behavior", behaviorId);

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);
            }


            onDeleteBehavior(behaviorId) {
                var transmit_data = {
                    behaviorId: behaviorId,
                    type: "delete_behavior_request"
                };

                this.lastAuthoringRequest = {
                    data: transmit_data
                };
                console.log("delete behavior request", behaviorId);

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);
            }

            onHardDeleteBehavior(behaviorId) {
                var transmit_data = {
                    behaviorId: behaviorId,
                    type: "hard_delete_behavior"
                };

                this.lastAuthoringRequest = {
                    data: transmit_data
                };
                console.log("hard delete behavior", behaviorId);

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);
            }

            onConnection(behaviorId, transitionId, name, fromStateId, toStateId, conditionId, condition, referenceA,referenceB) {

                var transmit_data = {
                    behaviorId:behaviorId,
                    transitionId:transitionId,
                    name:name,
                    fromStateId:fromStateId,
                    toStateId:toStateId,
                    conditionId:conditionId,
                    condition:condition,
                    referenceA:referenceA,
                    referenceB:referenceB,
                    type: "transition_added"
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

         
            onConditionRelationalChanged(behaviorId, conditionId, relational){
                var transmit_data = {
                    behaviorId: behaviorId,
                    conditionId: conditionId,
                    relational: relational,
                    type: "relational_changed"
                };
                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);

            }

            onMappingAdded(mappingId, name, fieldName, type, expressionId, stateId, behaviorId) {
                console.log("mapping added", mappingId, name, stateId);

                var transmit_data = {
                    mappingId: mappingId,
                    behaviorId: behaviorId,
                    relativePropertyFieldName: fieldName,
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
    

            onMethodAdded(behaviorId, transitionId, methodId, fieldName, displayName, argumentList) {
                console.log("method added ",argumentList);
                var transmit_data = {
                    behaviorId: behaviorId,
                    transitionId: transitionId,
                    methodId: methodId,
                    fieldName: fieldName,
                    displayName: displayName,
                    argumentList: argumentList,
                    type: "method_added"
                };

                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);
            }
            

         

            onExpressionModified(behaviorId, expressionId, expressionText, propertyList, generatorId, generatorType) {

                var transmit_data = {
                    behaviorId: behaviorId,
                    expressionId: expressionId,
                    expressionText: expressionText,
                    expressionPropertyList: propertyList,
                     generatorId:generatorId,
                    generatorType:generatorType,
                    type: "expression_modified"
                   

                };
                //TODO: This is sloppy- find a fix
                if(generatorId!== undefined || generatorId!== null){
                    this.generatorModel.addDefaultValues(generatorType, transmit_data);

                }
                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);

            }



 onDatasetAdded(mappingId, datasetId, datasetType, behaviorId, stateId, relativePropertyName, relativePropertyFieldName, expressionId, expressionText, expressionPropertyList) {
                console.log("dataset added called", datasetId, datasetType, stateId);

                var transmit_data = {
                    mappingId: mappingId,
                    datasetId: datasetId,
                    datasetType: datasetType,
                    behaviorId: behaviorId,
                    stateId: stateId,
                    relativePropertyName: relativePropertyName,
                    relativePropertyFieldName: relativePropertyFieldName,
                    expressionId: expressionId,
                    expressionText: expressionText,
                    expressionPropertyList: expressionPropertyList,
                    type: "dataset_added"
                };
                this.generatorModel.addDefaultValues(datasetType, transmit_data);
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

            onMappingRemoved(behaviorId, mappingId, stateId) {
                console.log("mapping relative removed", mappingId, stateId, behaviorId);

                var transmit_data = {
                    mappingId: mappingId,
                    behaviorId: behaviorId,
                    stateId: stateId,
                    type: "mapping_removed"
                };

                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_AUTHORING_EVENT", [transmit_data]);

            }

            onMappingDataRequest(behaviorId){
                  console.log("mapping data  request",behaviorId);

                var transmit_data = {
                    behaviorId: behaviorId,
                    type: "request_existing_mappings"
                };

                this.lastAuthoringRequest = {
                    data: transmit_data
                };

                this.trigger("ON_DATA_REQUEST_EVENT", [transmit_data]);
            }

            onStateAdded(behaviorId, stateId, stateName, x, y) {

                var transmit_data = {
                    behaviorId: behaviorId,
                    stateId: stateId,
                    stateName: stateName,
                    x: x,
                    y: y,
                    type: "state_added"
                };
                // data.type = "state_added";
                // data.x = x - $("#" + behaviorId).offset().left;
                // data.y = y - $("#" + behaviorId).offset().top;
                console.log("state created", transmit_data);
                this.lastAuthoringRequest = {
                    data: transmit_data
                };
                this.emitter.emit("ON_AUTHORING_EVENT", transmit_data);
            }

            onStateMoved(behaviorId, stateId, x, y) {
                var transmit_data = {
                    type: "state_moved",
                    x: x,
                    y: y,
                    behaviorId: behaviorId,
                    stateId: stateId
                };

                console.log("state moved", transmit_data);
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