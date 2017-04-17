//ChartView     
"use strict";
define(["jquery", "contextmenu", "jquery-ui", "jsplumb", "editableselect", "app/Expression", "app/Emitter", "app/id", "hbs!app/templates/method", "hbs!app/templates/behavior", "hbs!app/templates/state", "hbs!app/templates/start", "hbs!app/templates/transition", "hbs!app/templates/mapping"],



    function($, contextmenu, ui, jsPlumb, EditableSelect, Expression, Emitter, ID, methodTemplate, behaviorTemplate, stateTemplate, startTemplate, transitionTemplate, mappingTemplate) {

        var block_was_dragged = null;


        console.log("start template", startTemplate);
        console.log("state template", stateTemplate);
        var state_counter = 0;
        var ChartView = class extends Emitter {

            constructor(id, name) {
                super();
                var behavior_data = {
                    id: id,
                    name: name
                };
                this.setupId = null;
                this.dieId = null;
                this.name = name;
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
                        self.trigger("ON_STATE_CONNECTION", [info.connection.getId(), info.sourceId, $(info.source).attr("name"), info.targetId, self.id]);
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
                            var c_id = options.$trigger[0]._jsPlumb.getId();

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
                    selector: '#' + self.id + ' .state',
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

                $.contextMenu({
                    selector: '#' + self.id + ' .mapping',
                    callback: function(key, options) {
                        if (key == "delete") {
                            var mappingId = $(options.$trigger[0]).attr("id");
                            var stateId = $(options.$trigger[0]).attr("stateid");

                            console.log("mappping", mappingId);
                            self.trigger("ON_MAPPING_RELATIVE_REMOVED", [self.id, mappingId, stateId]);
                        }
                    },
                    items: {
                        "delete": {
                            name: "Delete Mapping",
                        }
                    }

                });

                this.createHTML(behavior_data);

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
                        if (type == 'state') {
                            var name = prompt("Please give your state a name", "myState");
                            if (name !== null) {
                                data.name = name;
                                self.trigger("ON_STATE_ADDED", [x, y, data]);
                                $(ui.helper).remove(); //destroy clone
                                $(ui.draggable).remove(); //remove from list
                            }
                        } else if (type == "brush_prop") {
                            var mappingId = $(ui.draggable).attr('mappingId');
                            var stateId = $(ui.draggable).attr('stateId');

                            if (mappingId) {
                                console.log("state found", stateId);
                                $(ui.helper).remove(); //destroy clone
                                $(ui.draggable).remove(); //remove from list
                                self.trigger("ON_MAPPING_RELATIVE_REMOVED", [mappingId, stateId, data.id]);

                            }

                        } else if (type == "action") {
                            var methodId = ID();
                            var targetMethod = $(ui.draggable).attr('name');
                            var defaultArgument = $(ui.draggable).attr('defaultArgument');
                            //data.name = name;
                            self.trigger("ON_METHOD_ADDED", [self.id, null, methodId, targetMethod, defaultArgument]);
                            $(ui.helper).remove(); //destroy clone
                            $(ui.draggable).remove(); //remove from list


                        }


                    }
                });

                this.instance.setContainer(behaviorData.id);

            }

            resetView() {
                this.instance.empty(this.id);
                $('#' + this.id).droppable("destroy");
                this.expressions = {};
            }

            destroyView() {
                this.resetView();
                this.instance.cleanupListeners();
            }


            //
            // initialise element as connection targets and source.
            //
            initNode(el, name) {

                // initialise draggable elements.
                this.instance.draggable(el);

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

                console.log(state_data.x, state_data.y, $("#" + this.id).offset(), this.id, state_data.name);
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
                var id = state_data.id;
                d.className = "w";

                if (state_data.name == "setup") {
                    console.log("state data  is setup");
                    d.className = "setup w";
                    html = startTemplate(state_data);
                } else if (state_data.name == "die") {
                    d.className = "die w";
                    html = startTemplate(state_data);
                } else {
                    html = stateTemplate(state_data);
                }
                d.id = id;

                d.innerHTML = html;



                d.style.left = state_data.x + "px";
                d.style.top = state_data.y + "px";
                this.instance.getContainer().appendChild(d);
                this.initNode(d, state_data.name);

                console.log("state", $('#' + id));
                $("#" + id).attr("name", state_data.name);
                $('#' + id).droppable({
                    greedy: true,
                    drop: function(event, ui) {
                        var type = $(ui.draggable).attr('type');
                        var name = $(ui.draggable).attr('name');
                        var item_name = $(ui.draggable).html();
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
                            self.trigger("ON_MAPPING_ADDED", [mapping_id, name, item_name, type, expressionId, id, self.id]);
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
                expression.addListener("ON_TEXT_CHANGED", function(expression) {
                    this.expressionModified(expression);
                }.bind(this));

                return expression;

            }

            expressionModified(expression) {
                this.trigger("ON_EXPRESSION_TEXT_UPDATE", [this.id, expression.id, expression.getText(), expression.getPropertyList()]);
                this.instance.repaintEverything();


            }

            addReferenceToExpression(mappingId, referenceType, referenceName, referenceProperties, referencePropertiesDisplayNames,referenceId, referenceDisplayName, name) {
                var expression = this.expressions[mappingId];
                var el = expression.addReference(referenceType, referenceName, referenceProperties,referencePropertiesDisplayNames, referenceId, referenceDisplayName, name);
                console.log("el to make draggable");
                this.makeDraggable(el);

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

                //this.makeDraggable(target);
                var self = this;

                console.log("target droppable", $('#' + mapping_data.mappingId).find(".reference_expression"));
                $($('#' + mapping_data.mappingId).find(".reference_expression")[0]).droppable({
                    greedy: true,
                    drop: function(event, ui) {
                        var type = $(ui.draggable).attr('type');
                        var name = $(ui.draggable).attr('name');
                        var displayName = $(ui.draggable).html();
                        var relativePropertyName = mapping_data.relativePropertyName;
                        var relativePropertyItemName = mapping_data.relativePropertyItemName;

                        var referenceProperty = name.split("_")[0];
                        var referenceNames = name.split("_");
                        referenceNames.shift();

                        console.log("drop on expression", type);

                        var drop_id = ID();
                        var data = {
                            type: type,
                            id: drop_id,
                            behaviorId: self.id

                        };
                        var referenceName, referenceProperties,referencePropertiesDisplayNames;
                        if (type == 'sensor_prop') {
                            referenceName = 'stylus';
                            console.log("sensor prop dropped on mapping", displayName);
                            $(ui.helper).remove(); //destroy cloneit'
                            referenceProperties = [name.split("_")[1]];
                            referencePropertiesDisplayNames = [displayName];

                            console.log("reference properties =", referenceProperties, name.split("_"));
                            expression = self.addReferenceToExpression(mapping_data.mappingId, type, referenceName, referenceProperties, referencePropertiesDisplayNames, drop_id, displayName, name);

                            console.log('reference properties set', expression.getPropertyList());

                            self.trigger("ON_MAPPING_REFERENCE_UPDATE", [mapping_data.mappingId, self.id, target_state, relativePropertyName, relativePropertyItemName, expression.id, expression.getText(), expression.getPropertyList(), "active"]);

                        }

                        if (type == 'generator') {

                            console.log("generator dropped on mapping");
                            $(ui.helper).remove(); //destroy clone
                            //$(ui.draggable).remove(); //remove from list
                            referenceName = null;
                            var generatorId = drop_id;
                            var generatorType = name;
                            referenceProperties = [generatorId];
                            referencePropertiesDisplayNames = [displayName];
                            expression = self.addReferenceToExpression(mapping_data.mappingId, type, referenceName, referenceProperties,referencePropertiesDisplayNames, generatorId, displayName, name);

                            self.trigger("ON_GENERATOR_ADDED", [mapping_data.mappingId, generatorId, generatorType, self.id, target_state, relativePropertyName, relativePropertyItemName, expression.id, expression.getText(), expression.getPropertyList()]);

                        }
                    }
                });

                this.instance.repaintEverything();

            }

            addTransitionEvent(data) {
                var html = "<div parent_id='" + data.transitionId + "'name='" + data.eventName + "'type='transition' class='block transition'>" + data.displayName + "</div>";
                $($('#' + data.transitionId).find(".events .event_block")[0]).empty();
                $($('#' + data.transitionId).find(".events .event_block")[0]).prepend(html);
                var target = $("#" + data.transitionId + " .events .event_block .block");



                if (data.eventName == "STATE_COMPLETE") {
                    target.attr("id", data.eventName);
                } else {
                    this.makeDraggable(target);

                }
                console.log("update event", $("#" + data.transitionId + " .events .event_block .block"), data);

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
                methodTemplateData.argumentList = argumentList;
                methodTemplateData.defaultArgumentName = data.methodArguments[data.defaultArgument];
                methodTemplateData.defaultArgumentId = data.defaultArgument;
                methodTemplateData.methodTextId = data.methodId + "_text";
                if (data.targetMethod == "spawn") {
                    methodTemplateData.methodNumberId = data.methodId + "_num";
                }

                var html = methodTemplate(methodTemplateData);
                if (data.targetTransition) {
                    $($('#' + data.targetTransition).find(".methods")[0]).prepend(html);

                } else {

                    $('#' + self.id).prepend(html);

                }
                this.makeDraggable($("#" + data.methodId));

                console.log("get text box by id", document.getElementById(methodTemplateData.methodTextId), methodTemplateData.methodTextId);
                EditableSelect.createEditableSelect(document.getElementById(methodTemplateData.methodTextId));

                console.log("method added event", $("#" + data.targetTransition + " .methods .block"), data, $('#' + methodTemplateData.methodTextId));
                $('#' +  methodTemplateData.methodTextId).change(function() {
                    console.log("change!");
                    self.methodArgumentChanged(self.id, data.transitionId, data.methodId, data.targetMethod);
                });
                $('#' + data.methodId + "_num").change(function() {
                    console.log("change!");
                    self.methodArgumentChanged(self.id, data.transitionId, data.methodId, data.targetMethod);
                });
            }

            removeMethod(data) {
                console.log("method:", $('#' + data.methodId));
                $('#' + data.methodId).remove();
            }



            methodArgumentChanged(behaviorId, transitionId, methodId, targetMethod) {
                var methodHTML = $('#' + methodId);

                var currentArgument = $('#' + methodId + "_text").val();
                console.log("method argument changed for ", methodId, currentArgument);
                var args = [currentArgument];
                if (targetMethod == "spawn") {
                    args.push($('#' + methodId + "_num").val());
                }

                this.trigger("ON_METHOD_ARGUMENT_CHANGE", [behaviorId, transitionId, methodId, targetMethod, args]);
            }

            updateMapping(data) {

            }

            //TODO: I think remove unbinds events of child elements but need to confirm here
            removeMapping(data) {
                console.log("mapping to remove", $("#" + data.mappingId), data.mappingId);
                var mapping = $("#" + data.mappingId);
                mapping.remove();
                this.instance.repaintEverything();

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
                            console.log("sensor prop or generator dropped");
                            var referenceId = target.attr("id");
                            var expressionId = target.attr("parent_id");
                            if (expressionId) {
                                var mappingId = $("#" + expressionId).attr("parent_id");
                                var expression = this.expressions[mappingId];
                                expression.removeReference(referenceId);
                                var expressionPropertyList = expression.getPropertyList();
                                var expressionText = expression.getText();

                                this.trigger("ON_MAPPING_REFERENCE_REMOVED", [this.id, expressionId, expressionPropertyList, expressionText]);
                            }
                            break;

                        case "method":
                            this.trigger("ON_METHOD_REMOVED", [this.id, target.attr("id")]);
                            break;
                        case "transition":
                            this.trigger("ON_TRANSITION_EVENT_REMOVED", [this.id, target.attr("parent_id")]);
                            break;

                    }
                }
            }

            initializeBehavior(data) {
                console.log("initialize behavior");
                console.trace();
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
                }
                this.instance.bind("connection", function(info) {
                    console.log("state transition made", info);
                    info.connection.setParameter("id", info.connection.getId());
                    self.trigger("ON_STATE_CONNECTION", [info.connection.getId(), info.sourceId, $(info.source).attr("name"), info.targetId, self.id]);
                });

                for (var k = 0; k < data.mappings.length; k++) {
                    var mapping_data = data.mappings[k];
                    this.addMapping(mapping_data);
                    var els = this.expressions[mapping_data.mappingId].updateReferences(mapping_data.expressionText, mapping_data.expressionPropertyList);
                    els.every(function(el) {
                        console.log("el to make draggable", el);
                        self.makeDraggable(el);
                    });
                }

                  for (var m = 0; m< data.methods.length; m++) {
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
                                            console.log(o);
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

                            //data.name = name;
                            self.trigger("ON_TRANSITION_EVENT_ADDED", [id, eventName, displayName, sourceId, sourceName, targetId, self.id]);
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
                        var targetMethod = $(ui.draggable).attr('name');
                        console.log("type=", type);

                        if (type == 'action') {

                            //data.name = name;
                            self.trigger("ON_METHOD_ADDED", [behaviorId, transitionId, methodId, targetMethod, null]);
                            $(ui.helper).remove(); //destroy clone
                            $(ui.draggable).remove(); //remove from list

                        }
                    }
                });

                connection.getOverlay("transition_" + id).hide();



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