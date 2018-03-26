//ChartView     
"use strict";
define(["jquery", "jquery.panzoom", "contextmenu", "jquery-ui", "jsplumb", "editableselect", "app/Expression", "app/Emitter", "app/id", "app/InspectorModel", "hbs!app/templates/method", "hbs!app/templates/event", "hbs!app/templates/behavior", "hbs!app/templates/state", "hbs!app/templates/start", "hbs!app/templates/transition", "hbs!app/templates/mapping"],



    function($, panzoom, contextmenu, ui, jsPlumb, EditableSelect, Expression, Emitter, ID, InspectorModel, methodTemplate, eventTemplate, behaviorTemplate, stateTemplate, startTemplate, transitionTemplate, mappingTemplate) {

        var block_was_dragged = null;
        var conditionalEvents = ["TIME_INTERVAL", "DISTANCE_INTERVAL", "STYLUS_MOVE_BY", "STYLUS_X_MOVE_BY", "STYLUS_Y_MOVE_BY", "INTERSECTION"];
        console.log("start template", startTemplate);
        console.log("state template", stateTemplate);
        var state_counter = 0;
        var global_brush_properties;
        var brush_properties_added = {};
        var ChartView = class extends Emitter {

            constructor(id, name, active_status, brush_properties, action_properties) {
                super();
                var behavior_data = {
                    id: id,
                    name: name
                };
                this.setupId = null;
                this.dieId = null;
                this.name = name;
                this.active_status = active_status;
                global_brush_properties = brush_properties;
                this.expressions = {};
                var self = this;
                var last_dragged = null;

                //queue for storing behavior changes
                this.behavior_queue = [];
                //timer for running behavior changes
                this.behaviorTimer = false;
                this.currrentState = null;
                this.prevState = null;
                this.id = id;
                this.action_properties = action_properties;

                jsPlumb.ready(function() {


                    // setup some defaults for jsPlumb.
                    self.instance = jsPlumb.getInstance({
                        Endpoint: ["Rectangle", {
                            width: 10,
                            height: 10,
                            cssClass: "transendpoint"
                        }],
                        Connector: ["StateMachine", {
                            stub: [40, 100],
                            gap: 0,
                            cornerRadius: 5,
                            alwaysRespectStubs: true
                        }],
                        HoverPaintStyle: {
                            strokeStyle: "#eacc96",
                            lineWidth: 10
                        },
                        ConnectionOverlays: [
                            ["Arrow", {
                                location: 1,
                                id: "arrow",
                                length: 14,
                                foldback: 1,
                            }]

                        ]
                    });

                    self.instance.registerConnectionType("basic", {
                        anchor: "Continuous",
                        connector: "StateMachine"
                    });

                    self.instance.registerConnectionType("state", {
                        anchor: "Continuous",
                        connector: "StateMachine"
                    });

                    self.instance.bind("connection", function(info) {
                        console.log("state transition made", info);
                        info.connection.setParameter("id", info.connection.getId());
                        self.trigger("ON_STATE_CONNECTION", [info.connection.getParameter("id"), info.sourceId, $(info.source).attr("name"), info.targetId, self.id]);
                    });

                    window.jsp = self.instance;
                    var canvas = document.getElementById("canvas");
                    var windows = jsPlumb.getSelector(".statemachine .w");



                    $(document).on("mouseup", function(e) {
                        if (block_was_dragged !== null) {

                            var styles = {
                                left: "0px",
                                top: "0px"
                            };
                            block_was_dragged.css(styles);
                            block_was_dragged.removeClass("block-draggable");

                            block_was_dragged = null;
                        }
                    });

                });

                $.contextMenu({
                    selector: '#' + self.id + ' .jsplumb-connector',
                    callback: function(key, options) {
                        if (key == "delete") {
                            var c_id = options.$trigger[0]._jsPlumb.getParameter("id");

                            self.trigger("ON_TRANSITION_REMOVED", [self.id, c_id]);
                        }
                    },
                    items: {
                        "delete": {
                            name: "Delete Transition",
                        }
                    }

                });

                $.contextMenu({
                    selector: '#' + self.id + ' .stateContainer',
                    reposition: false,
                    callback: function(key, options) {
                        if (key == "delete") {
                            var parent = $(options.$trigger[0]).parent();
                            console.log("state", parent[0].id);
                            self.trigger("ON_STATE_REMOVED", [self.id, parent[0].id]);
                        }
                    },
                    items: {
                        "delete": {
                            name: "Delete State",
                        }
                    }

                });




               // CONTEXT MENUL FOR PROPERTY ITEMS
                $.contextMenu({
                    trigger: 'left',
                    className: "property_menu",                    
                    selector: '#' + self.id +' .state .prop_button',                 
                    callback: function(key, options) {
                        var name = key;
                        var mapping_id = ID();
                        var expressionId = ID();
                        var id = options.$trigger.parent().parent().parent().attr('id');
                        var type = "brush_prop";
                        var fieldName = key;
                        if (key == "delta x"){
                            fieldName = "dx";
                        }else if (key == "delta y"){
                            fieldName = "dy";
                        }else if (key == "scale x"){
                            fieldName = "sx";
                        }else if (key == "scale y"){
                            fieldName = "sy";
                        }
                        console.log(mapping_id, name, fieldName, type, expressionId, $(options.$trigger[0]), self.id);
                        self.trigger("ON_MAPPING_ADDED", [mapping_id, name, fieldName, type, expressionId, id, self.id]);
                        //self.trigger("ON_MAPPING_DATA_REQUEST", [self.id]);                      
                    },

                    build: function(trigger) {
                        console.log(global_brush_properties);
                        var p_items = {};
                        var parent = $(trigger[0]).parent().parent().parent();
                        for(var i = 0; i < global_brush_properties.length; i++){
                            var p_name = global_brush_properties[i].fieldName;
                            p_items[p_name] = {className: 'property_menu_item', name: global_brush_properties[i].displayName, disabled: Object.values(brush_properties_added[self.id][parent.attr("id")]).indexOf(p_name) > -1, fieldName: global_brush_properties[i].fieldName};//function(){
                       }

                        var options = {
                            items:p_items
                       };
                        return options;
                    }             

                });

// CONTEXT MENUL FOR ACTION ITEMS
                $.contextMenu({
                    trigger: 'left',
                    className: "methods_menu",                    
                    selector: '#' + self.id +' .methodsContainer .prop_button',                 
                    callback: function(key, options) {
                        var name = key;
                        var methodId = ID();
                        var expressionId = ID();
                        var id = options.$trigger.parent().parent().parent().attr('id');
                        console.log(action_id, name, $(options.$trigger[0]), self.id);
                        var targetMethod = $(ui.draggable).attr('name');
                                                   var defaultArgument = $(ui.draggable).attr('defaultArgument');
                                                   //data.name = name;
                                                   self.trigger("ON_METHOD_ADDED", [self.id, null, methodId, targetMethod, defaultArgument]);
                                                   $(ui.helper).remove(); //destroy clone
                                                   $(ui.draggable).remove(); //remove from list

                     
                    },

                    build: function(trigger) {
                        console.log(self.action_properties);
                        var p_items = {};
                        var parent = $(trigger[0]).parent().parent().parent();
                        for(var i = 0; i < self.action_properties.length; i++){
                            var p_name = self.action_properties[i].fieldName;
                            var displayName = self.action_properties[i].displayName;
                            console.log(displayName, p_name);

                            p_items[p_name] = {className: 'property_menu_item', name:displayName, fieldName: p_name};//function(){
                       }

                        var options = {
                            items:p_items
                       };
                        return options;
                    }             

                });

     // set a title

                $.contextMenu({
                    selector: '#canvas',
                    callback: function(key, options) {
                        if (key == "newstate") {
                            var state_id = ID();
                            var x = $(".context-menu-visible").parent().position().left;
                            var y = $(".context-menu-visible").parent().position().top;
                            var name = prompt("Please give your state a name", "myState");
                            if (name !== null) {
                                self.trigger("ON_STATE_ADDED", [self.id, state_id, name, x, y]);
                            }
                        }
                    },
                    items: {
                        "newstate": {
                            name: "New State",
                        }
                    }

                });

                $.contextMenu({
                    selector: '#' + self.id + ' .mapping',
                    callback: function(key, options) {
                        if (key == "delete") {
                            var mappingId = $(options.$trigger[0]).attr("id");
                            var stateId = $(options.$trigger[0]).attr("stateid");

                            console.log("mappping", mappingId);
                            self.trigger("ON_MAPPING_REMOVED", [self.id, mappingId, stateId]);
                            //new extension
                            var parent = $(options.$trigger[0]).parent().parent().parent();
                            console.log("mapping-deleted callback",parent);
                            //self.trigger("ON_MAPPING_DATA_REQUEST", [self.id]);
                        }
                    },
                    items: {
                        "delete": {
                            name: "Delete Mapping",
                        }
                    }

                });

                $.contextMenu({
                    selector: '#' + self.id + ' .method',
                    callback: function(key, options) {
                        if (key == "delete") {
                            var methodId = $(options.$trigger[0]).attr("id");

                            self.trigger("ON_METHOD_REMOVED", [self.id, methodId]);

                        }
                    },
                    items: {
                        "delete": {
                            name: "Delete Action",
                        }
                    }

                });



                this.createHTML(behavior_data);

            }

            enablePan() {
                console.log("enable pan");
                $('#' + this.id).panzoom("enable");
            }

            disablePan() {
                console.log("disable pan");
                $('#' + this.id).panzoom("disable");
            }

            zoom(scaleAmount, point) {
                console.log("zoom", scaleAmount, point);
                this.enablePan();
                $('#' + this.id).panzoom("zoom", scaleAmount, {
                    focal: point
                });
                this.disablePan();
            }



            createHTML(behaviorData) {
                var self = this;
                var html = behaviorTemplate(behaviorData);
                $("#canvas").empty();

                $("#canvas").append(html);

                $('#' + behaviorData.id).droppable({
                    greedy: true,
                    drop: function(event, ui) {
                        console.log("drop event", ui);
                        self.resolveDrop($(ui.draggable));
                        var type = $(ui.draggable).attr('type');
                        console.log("type=", type);
                        var drop_id = ID();
                        var data = {
                            type: type,
                            id: drop_id,
                            behaviorId: behaviorData.id

                        };
                        var x = $(ui.draggable).position().left;
                        var y = $(ui.draggable).position().top;
                        // if (type == 'state') {
                        //     var name = prompt("Please give your state a name", "myState");
                        //     if (name !== null) {
                        //         data.name = name;
                        //         self.trigger("ON_STATE_ADDED", [x, y, data]);

                        //     }
                        //     $(ui.helper).remove(); //destroy clone
                        //     $(ui.draggable).remove(); //remove from list
                        // } 
                         if (type == "brush_prop") {
                            var mappingId = $(ui.draggable).attr('mappingId');
                            var stateId = $(ui.draggable).attr('stateId');

                            if (mappingId) {
                                console.log("state found", stateId);
                                $(ui.helper).remove(); //destroy clone
                                $(ui.draggable).remove(); //remove from list
                                self.trigger("ON_MAPPING_REMOVED", [mappingId, stateId, data.id]);

                            }

                        }
                       


                    }
                });

                this.instance.setContainer(behaviorData.id);
                $('#' + behaviorData.id).panzoom({
                    cursor: "grab"
                });
                this.disablePan();

            }

            resetView() {
                this.instance.empty(this.id);
                if ($('#' + this.id).data('ui-droppable')) {
                    console.log("droppable initialized");

                    $('#' + this.id).droppable("destroy");
                } else {
                    console.log("droppable not initialized");
                }
                this.expressions = {};
            }

            destroyView() {
                this.resetView();
                this.instance.cleanupListeners();
            }

            updateProperties(prop_data){
                brush_properties_added[prop_data.data.behaviorId] = prop_data.data.states;
                for (var st in brush_properties_added[prop_data.data.behaviorId]){
                    var mpArray = [];
                    for(var mp in brush_properties_added[prop_data.data.behaviorId][st]){     
                        mpArray.push(brush_properties_added[prop_data.data.behaviorId][st][mp]["relativePropertyFieldName"]);
                    }
                    brush_properties_added[prop_data.data.behaviorId][st] = mpArray;
                }
                console.log("brush props added",brush_properties_added);
            }


            //
            // initialise element as connection targets and source.
            //
            initNode(el, stateId, name) {
                var self = this;
                // initialise draggable elements.
                this.instance.draggable(el, {
                        stop: function(event, ui) {
                            // Show dropped position.
                            var x = $(el).position().left;
                            var y = $(el).position().top;
                            self.trigger("ON_STATE_MOVED", [self.id, stateId, x, y]);
                            console.log("dragged to", x, y);

                        }
                    }

                );

                this.instance.makeSource(el, {
                    filter: ".ep",
                    anchor: ["Continuous", {
                        faces: ["left", "right"]
                    }],
                    connectorStyle: {
                        strokeStyle: "#efac1f",
                        lineWidth: 6,
                        outlineColor: "transparent",
                        outlineWidth: 4
                    },
                    connectionType: "basic",
                    extract: {
                        "action": "the-action"
                    },
                    maxConnections: 50,
                    onMaxConnections: function(info, e) {
                        alert("Maximum connections (" + info.maxConnections + ") reached");
                    }
                });

                this.instance.makeTarget(el, {
                    dropOptions: {
                        hoverClass: "dragHover"
                    },
                    anchor: ["Continuous", {
                        faces: ["left", "right"]
                    }],
                    allowLoopback: true
                });


            }

            newNode(state_data) {
                var self = this;

                console.log(state_data.x, state_data.y, $("#" + this.id).offset(), this.id, state_data.stateName);
                if (!state_data) {
                    state_data = {
                        name: "state " + state_counter,
                        id: ID(),
                        mappings: []
                    };
                    state_counter++;
                }
                var html;
                var d = document.createElement("div");
                var id = state_data.stateId;
                d.className = "w";

                if (state_data.stateName == "setup") {
                    console.log("state data  is setup");
                    d.className = "setup w";
                    html = startTemplate(state_data);
                } else if (state_data.stateName == "die") {
                    d.className = "die w";
                    html = startTemplate(state_data);
                } else {
                    html = stateTemplate(state_data);
                    console.log('state html',html);

                    }
                d.id = id;

                d.innerHTML = html;



                d.style.left = state_data.x + "px";
                d.style.top = state_data.y + "px";
                this.instance.getContainer().appendChild(d);
                this.initNode(d, state_data.stateId, state_data.stateName);

                console.log("state", $('#' + id));
                $("#" + id).attr("name", state_data.stateName);
                $('#' + id).droppable({
                    greedy: true,
                    drop: function(event, ui) {
                        var type = $(ui.draggable).attr('type');
                        var name = $(ui.draggable).attr('name');
                        var fieldName = $(ui.draggable).html();
                        var mapping_id = ID();
                        var data = {
                            type: type,
                            id: mapping_id
                        };
                        var x = $(ui.draggable).position().left;
                        var y = $(ui.draggable).position().top;
                        console.log("dropped on state", x, y, type);
                        if (type == "brush_prop") {
                            console.log("brush prop dropped on state");
                            var expressionId = ID();
                            console.log(mapping_id, name, fieldName, type, expressionId, id, self.id);
                            self.trigger("ON_MAPPING_ADDED", [mapping_id, name, fieldName, type, expressionId, id, self.id]);
                            //need to extension
                            $(ui.helper).remove(); //destroy clone
                            $(ui.draggable).remove(); //remove from list
                        }

                    }
                });


                return d;
            }

            removeState(data) {
                this.instance.remove(data.stateId);
            }

            initializeExpression(expressionId, mappingId) {
                var ex_el = $("#" + mappingId + " .reference_expression .text_entry")[0];
                var expression = new Expression(ex_el, mappingId, expressionId);

                this.expressions[mappingId] = expression;
                expression.addListener("ON_TEXT_CHANGED", function(expression, removedReferences) {
                    this.expressionModified(expression, removedReferences);
                }.bind(this));

                return expression;

            }

            addMapping(mapping_data) {
                console.log("add mapping", mapping_data);
                var target_state = mapping_data.stateId;
                var html = mappingTemplate(mapping_data);
                console.log("target_state = ", target_state, mapping_data);
                $("#" + target_state + " .state .mappings").append(html);

                var target = $("#" + mapping_data.mappingId + " .relative_expression .block");

                console.log("expressionId =", mapping_data.expressionId);

                var expression = this.initializeExpression(mapping_data.expressionId, mapping_data.mappingId);

                console.log("target droppable", $('#' + mapping_data.mappingId).find(".reference_expression"));
                var el =  $($('#' + mapping_data.mappingId).find(".reference_expression")[0]);
                this.setDropFunctionsForExpression(el,mapping_data.mappingId);
                this.instance.repaintEverything();

                //need to extension

            }

            setDropFunctionsForExpression(el, expressionTargetId){
                var self = this;
              el.droppable({
                    greedy: true,
                    drop: function(event, ui) {
                        var referenceType = $(ui.draggable).attr('type');
                        var referenceId = $(ui.draggable).attr('id');
                        var referenceDisplayName = $(ui.draggable).html();
                        var style = $(ui.draggable).attr('blockstyle');
                        console.log("!style in drop is ", style, $(ui.draggable));
                      
                      $(ui.draggable).remove();

                    var expression = self.addReferenceToExpression(expressionTargetId, referenceId, referenceType, referenceDisplayName, style);
                    var eventArgs = [self.id, expression.id, expression.getText(), expression.getPropertyList()];

                        self.trigger("ON_EXPRESSION_MODIFIED", eventArgs);
                    }
                });
            }


            expressionModified(expression, removedReferences) {
                var self = this;
                if (removedReferences.length > 0) {
                    removedReferences.forEach(function(r) {
                        self.expressionReferenceRemoved(r, expression.id);
                    });
                }
                this.trigger("ON_EXPRESSION_MODIFIED", [this.id, expression.id, expression.getText(), expression.getPropertyList()]);
                this.instance.repaintEverything();

            }

            addReferenceToExpression(mappingId, referenceId, referenceType, referenceDisplayName, style) {
                var expression = this.expressions[mappingId];
                var el = expression.addReference(referenceId, referenceType, referenceDisplayName, style);
                console.log("el to make draggable");
                this.makeDraggable(el);
                this.addInspector(el);
                return expression;
            }


            addTransitionEvent(data, generator_data, condition_data) {
                console.log("adding transition event", data);
                //var html = "<div parent_id='" + data.transitionId + "'name='" + data.eventName + "'type='transition' class='block transition'>" + data.displayName + "</div>";
                var self = this;
                var eventTemplateData = {
                    transitionId: data.transitionId,
                    eventName: data.eventName,
                    displayName: data.displayName,
                };

                if (conditionalEvents.indexOf(data.eventName) >= 0) {
                    eventTemplateData.transitionNumberId = data.transitionId + "_num";
                    eventTemplateData.value = 1;
                }

                if (data.conditionName) {
                    var conditionName = data.conditionName;
                    var condition = condition_data.filter(function(c) {
                        return c.name == conditionName;
                    });

                    var relativeName = condition[0].relativeNames[0];
                    var generator = generator_data.filter(function(g) {
                        return g.generatorId == relativeName;
                    });
                    if (generator[0].generator_type == "interval") {
                        var val = generator[0].inc;
                        eventTemplateData.value = val;

                    }

                    console.log("transition has condition!", conditionName, condition, generator);

                }

                var html = eventTemplate(eventTemplateData);

                $($('#' + data.transitionId).find(".events .event_block")[0]).empty();
                $($('#' + data.transitionId).find(".events .event_block")[0]).prepend(html);
                var target = $("#" + data.transitionId + " .events .event_block .block");



                if (data.eventName == "STATE_COMPLETE") {
                    target.attr("id", data.eventName);
                } else {
                    this.makeDraggable(target);

                }

                $('#' + data.transitionId + "_num").change(function() {
                    console.log("change!");
                    self.transitionConditionChanged(self.id, data.transitionId, data.eventName, data.fromStateId, data.toStateId, data.displayName, data.name);
                });
                console.log("update event", $("#" + data.transitionId + " .events .event_block .block"), data);

            }

            transitionConditionChanged(behaviorId, transitionId, eventName, fromStateId, toStateId, displayName, name) {
                var transitionHTML = $('#' + transitionId);
                var conditions = [];
                if (conditionalEvents.indexOf(eventName) >= 0) {
                    var num_condition = $('#' + transitionId + "_num").val();
                    conditions.push(num_condition);
                    console.log("transition condition  changed for ", eventName, num_condition);

                }

                this.trigger("ON_TRANSITION_CONDITION_CHANGED", [behaviorId, transitionId, eventName, fromStateId, toStateId, displayName, name, conditions]);
            }


            removeTransition(data) {
                var connections = this.instance.getConnections();
                var connection = connections.find(function(c) {
                    return c.getParameter("id") == data.transitionId;
                });
                this.instance.detach(connection);

            }

            removeTransitionEvent(data) {

            }

            addMethod(data) {
                console.log("method data =", data);
                var self = this;
                var argumentList = "";

                for (var arg in data.methodArguments) {
                    if (data.methodArguments.hasOwnProperty(arg)) {
                        argumentList += arg + "|" + data.methodArguments[arg] + ";";
                    }
                }
                var methodTemplateData = {};

                argumentList = argumentList.slice(0, -1);
                console.log("data.methodArguments", data.methodArguments, argumentList);

                methodTemplateData.targetMethod = data.targetMethod;
                methodTemplateData.methodId = data.methodId;
                console.log("has arguments?", data.hasArguments);
                if (data.hasArguments) {
                    methodTemplateData.argumentList = argumentList;
                    methodTemplateData.hasArguments = true;
                    if (data.currentArguments) {
                        methodTemplateData.defaultArgumentName = data.methodArguments[data.currentArguments[0]];
                        methodTemplateData.defaultArgumentId = data.currentArguments[0];

                    } else {
                        methodTemplateData.defaultArgumentName = data.methodArguments[data.defaultArgument];
                        methodTemplateData.defaultArgumentId = data.defaultArgument;
                    }

                    methodTemplateData.methodTextId = data.methodId + "_text";
                    if (data.targetMethod == "spawn") {
                        methodTemplateData.methodNumberId = data.methodId + "_num";
                        if (data.currentArguments) {
                            methodTemplateData.defaultNumberArgument = data.currentArguments[1];

                        } else {
                            methodTemplateData.defaultNumberArgument = 1;
                        }

                    }

                }
                var html = methodTemplate(methodTemplateData);
                console.log("target transition:", data.targetTransition, $('#' + data.targetTransition), $($('#' + data.targetTransition).find(".methods")));
                if (data.targetTransition && data.targetTransition != "globalTransition") {
                    $($('#' + data.targetTransition).find(".methods")[0]).append(html);

                } else {

                    $('#' + self.id).append(html);

                }
                // this.makeDraggable($("#" + data.methodId));
                if (data.hasArguments) {
                    console.log("get text box by id", document.getElementById(methodTemplateData.methodTextId), methodTemplateData.methodTextId);
                    //EditableSelect.createEditableSelect(document.getElementById(methodTemplateData.methodTextId));
                var expression = this.initializeExpression(data.expressionId, data.methodId);
                    console.log("method added event", $("#" + data.targetTransition + " .methods .block"), data, $('#' + methodTemplateData.methodTextId));
                    $('#' + methodTemplateData.methodTextId).change(function() {
                        console.log("change!");
                        self.methodArgumentChanged(self.id, data.targetTransition, data.methodId, data.targetMethod);
                    });
                    $('#' + data.methodId + "_num").change(function() {
                        console.log("change!");
                        self.methodArgumentChanged(self.id, data.targetTransition, data.methodId, data.targetMethod);
                    });
                }
            }

            removeMethod(data) {
                console.log("method:", $('#' + data.methodId));
                $('#' + data.methodId).remove();
            }



            methodArgumentChanged(behaviorId, transitionId, methodId, targetMethod) {
                var methodHTML = $('#' + methodId);

                var currentArgument = $('#' + methodId + "_text").attr('argumentid');
                if(currentArgument == "nil"){
                    currentArgument = $('#' + methodId + "_text").attr("value");
                }
                console.log("method argument changed for ", methodId, currentArgument);
                var args = [currentArgument];
                if (targetMethod == "spawn") {
                    args.push($('#' + methodId + "_num").val());
                }

                this.trigger("ON_METHOD_ARGUMENT_CHANGE", [behaviorId, transitionId, methodId, targetMethod, args]);
            }

           

            //TODO: I think remove unbinds events of child elements but need to confirm here
            removeMapping(data) {
                console.log("mapping to remove", $("#" + data.mappingId), data.mappingId);
                var br = $("#" + data.mappingId + "+ br");
                var mapping = $("#" + data.mappingId);
                br.remove();
                mapping.remove();
                this.instance.repaintEverything();

            }

            addInspector(target){
                var inspectorModel = new InspectorModel(this.id,target.attr("id"));
                var el = inspectorModel.view.el;
                target.hover(
                    function() {
                        var position = $(this).offset(); 
                        el.css({left:position.left, top:position.top+30,visibility:"visible"});
                    },
                    function() {
                       
                          el.css({visibility:"hidden"});

                    });
            }

            makeDraggable(target) {
                var self = this;



                target.draggable({
                    helper: function() {
                        var parent = $(this).parent();
                        self.last_dragged = {
                            parent: parent
                        };
                        $(this).appendTo('body');
                        var styles = {
                            position: "absolute",
                            'z-index': 1000
                        };
                        $(this).css(styles);
                        $(this).addClass("last_dragged");
                        return $(this);
                    },
                    start: function(event, ui) {
                        $(this).draggable('instance').offset.click = {
                            left: Math.floor(ui.helper.width() / 2),
                            top: Math.floor(ui.helper.height() / 2)
                        };
                    },
                    cursor: 'move',

                });

                this.instance.draggable(target);

            }


            returnToParent(target) {
                console.log("return to parent", this.last_dragged, target);
                if (this.last_dragged) {
                    target.detach().appendTo(this.last_dragged.parent);
                    target.removeClass("last_dragged");
                    var styles = {
                        position: "relative",
                        left: 0,
                        top: 0,
                        'z-index': 1
                    };
                    target.css(styles);
                    this.last_dragged = null;
                    return true;

                }
                return false;
            }

            resolveDrop(target, newParent) {
                console.log("resolve drop", target.attr('type'));
                if (this.last_dragged) {
                    console.log("last dragged", target, this.last_dragged);
                    target.removeClass("last_dragged");

                    switch (target.attr('type')) {
                        case "sensor_prop":
                        case "generator":
                        case "ui_prop":
                            this.expressionReferenceRemoved(target.attr("id"), target.attr("parent_id"));
                            break;
                        case "transition":
                            this.trigger("ON_TRANSITION_EVENT_REMOVED", [this.id, target.attr("parent_id")]);
                            break;

                    }
                }
            }

            expressionReferenceRemoved(referenceId, expressionId) {
                if (expressionId) {
                    var mappingId = $("#" + expressionId).attr("parent_id");
                    var expression = this.expressions[mappingId];
                    expression.removeReference(referenceId);
                    var expressionPropertyList = expression.getPropertyList();
                    var expressionText = expression.getText();
                    this.trigger("ON_EXPRESSION_MODIFIED", [this.id, expression.id, expression.getText(), expression.getPropertyList()]);
                }
            }


            initializeBehavior(data) {
                console.log("initialize behavior");
                var self = this;


                for (var i = 0; i < data.states.length; i++) {
                    this.newNode(data.states[i]);
                }
                this.instance.unbind("connection");
                for (var j = 0; j < data.transitions.length; j++) {
                    console.log("connecting ", data.transitions[j].toStateId, "to", data.transitions[j].toStateId);
                    var connection = this.instance.connect({
                        source: data.transitions[j].fromStateId,
                        target: data.transitions[j].toStateId,
                        type: "basic"
                    });
                    var connection_id = data.transitions[j].transitionId;
                    connection.setParameter("id", connection_id);

                    console.log("connection id", data.transitions[j], connection.id);
                    self.addOverlayToConnection(data.transitions[j]);
                    self.addTransitionEvent(data.transitions[j], data.generators, data.conditions);
                }
                this.instance.bind("connection", function(info) {
                    console.log("state transition made", info);
                    info.connection.setParameter("id", info.connection.getId());
                    self.trigger("ON_STATE_CONNECTION", [info.connection.getParameter("id"), info.sourceId, $(info.source).attr("name"), info.targetId, self.id]);
                });

                self.trigger("ON_MAPPING_DATA_REQUEST", [self.id]);

                for (var k = 0; k < data.mappings.length; k++) {
                    var mapping_data = data.mappings[k];
                    this.addMapping(mapping_data);
                    var els = this.expressions[mapping_data.mappingId].updateReferences(mapping_data.expressionText, mapping_data.expressionPropertyList);
                    els.every(function(el) {
                        console.log("el to make draggable", el);
                        self.makeDraggable(el);
                        self.addInspector(el);
                    });
                }

                for (var m = 0; m < data.methods.length; m++) {
                    var method_data = data.methods[m];
                    this.addMethod(method_data);


                }
            }

            addOverlayToConnection(transition_data) {
                var self = this;

                var id = transition_data.transitionId;
                console.log("transition id=", id);
                var connections = this.instance.getConnections();
                var connection = connections.find(function(c) {
                    return c.getParameter("id") == id;
                });
                console.log("connection is", connection);
                connection.addOverlay(["Custom", {
                    create: function(component) {
                        var html = transitionTemplate(transition_data);
                        return $(html);
                    },
                    location: 0.5,
                    cssClass: "transition_overlay",

                    id: "transition_" + id
                }]);



                connection.addOverlay(["Custom", {
                    create: function(component) {

                        var html = "<div><div class = 'transition_toggle'>+</div></div>";
                        return $(html);
                    },
                    location: 0.5,
                    id: "toggle_" + id,
                    events: {
                        click: function(customOverlay, originalEvent) {
                            console.log("connection", connection);
                            var all_connections = self.instance.getAllConnections();
                            for (var i = 0; i < all_connections.length; i++) {
                                if (connection != all_connections[i]) {
                                    var overlays = all_connections[i].getOverlays();
                                    console.log("overlays =", overlays);
                                    for (var o in overlays) {
                                        if (overlays.hasOwnProperty(o)) {
                                            if (o.split("_")[0] == "transition") {
                                                overlays[o].hide();
                                            }
                                            if (o.split("_")[0] == "toggle") {
                                                overlays[o].show();
                                            }
                                        }
                                    }

                                }
                            }
                            connection.getOverlay("transition_" + id).show();
                            console.log("transition overlay", id, $('#' + id).parent());
                            $('#' + id).parent().css('z-index', 50);

                            connection.getOverlay("toggle_" + id).hide();

                        }
                    }
                }]);

                console.log("droppable target:", $('#' + id).find(".events .event_block"));
                console.log("transition_data", transition_data);

                $($('#' + id).find(".events .event_block")[0]).droppable({
                    greedy: true,
                    drop: function(event, ui) {
                        console.log("drop_event_data", transition_data);

                        var eventName = $(ui.draggable).attr('name');
                        var displayName = $(ui.draggable).html();
                        var type = $(ui.draggable).attr('type');
                        var sourceId = transition_data.fromStateId;
                        var targetId = transition_data.toStateId;
                        var sourceName = transition_data.name;

                        console.log("type=", type);

                        if (type == 'transition') {
                            var conditions = [1];
                            //data.name = name;
                            self.trigger("ON_TRANSITION_EVENT_ADDED", [id, eventName, conditions, displayName, sourceId, sourceName, targetId, self.id]);
                            $(ui.helper).remove(); //destroy clone
                            $(ui.draggable).remove(); //remove from list

                        }
                    }
                });

                $($('#' + id).find(".methods")[0]).droppable({
                    greedy: true,
                    drop: function(event, ui) {
                        console.log("drop method");
                        var type = $(ui.draggable).attr('type');
                        var behaviorId = self.id;
                        var transitionId = id;
                        var methodId = ID();
                         var expressionId = ID();
                        var targetMethod = $(ui.draggable).attr('name');
                        console.log("type=", type);

                        if (type == 'action') {

                            //data.name = name;
                            self.trigger("ON_METHOD_ADDED", [behaviorId, transitionId, methodId, expressionId, targetMethod, null]);
                            $(ui.helper).remove(); //destroy clone
                            $(ui.draggable).remove(); //remove from list

                        }
                    }
                });



                connection.getOverlay("transition_" + id).hide();
                var selector = $("#" + id).parent().closest('div').attr('id');
                console.log("selector:", selector);
                $.contextMenu({
                    selector: "#" + selector +" .methods",
                    callback: function(key, options) {
                        if (key == "minimize") {
                            connection.getOverlay("transition_" + id).hide();
                            connection.getOverlay("toggle_" + id).show();


                        }
                    },
                    items: {
                        "minimize": {
                            name: "minimize transition",
                        }
                    }

                });
             



            }

            behaviorChange(behaviorEvent, data) {
                var self = this;
                this.behavior_queue.push({
                    event: behaviorEvent,
                    data: data
                });
                if (!this.behaviorTimer) {
                    this.behaviorTimer = setInterval(function() {
                        self.animateBehaviorChange(self);
                    }, 800);
                }

            }

            animateBehaviorChange(self) {
                if (self.prevState) {
                    $("#" + self.prevState).removeClass("active");
                }
                var change = self.behavior_queue.shift();
                // if(change.event == "state"){
                var classes = $("#" + change.data.id).attr('class');
                classes = "active" + ' ' + classes;
                $("#" + change.data.id).attr('class', classes);
                self.currrentState = change.data.id;

                // }



                self.prevState = self.currrentState;

                //}
                console.log("change = ", change);
                if (self.behavior_queue.length < 1) {
                    clearInterval(self.behaviorTimer);
                    self.behaviorTimer = false;
                }
            }

        };



        return ChartView;
    });