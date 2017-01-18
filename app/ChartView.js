//flowchartview     
"use strict";
define(["jquery", "jquery-ui", "jsplumb", "handlebars", "hbs!app/templates/state", "hbs!app/templates/start", "hbs!app/templates/transition", "hbs!app/templates/mapping"],



    function($, ui, jsPlumb, Handlebars, stateTemplate, startTemplate, transitionTemplate, mappingTemplate) {

        var block_was_dragged = null;

        console.log("start template", startTemplate);
        console.log("state template", stateTemplate);

        var state_counter = 0;
        var ChartView = function(id) {
            $( "#canvas" ).append( $("<div class= 'behavior_container' id='"+id+"'></div>"));

            //queue for storing behavior changes
            this.behavior_queue = [];
            //timer for running behavior changes
            this.behaviorTimer = false;
            this.currrentState = null;
            this.prevState = null;

            var self = this;
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

                    ],
                    Container: id
                });

                self.instance.registerConnectionType("basic", {
                    anchor: "Continuous",
                    connector: "StateMachine"
                });

                self.instance.registerConnectionType("state", {
                    anchor: "Continuous",
                    connector: "StateMachine"
                });



                window.jsp = self.instance;
                var canvas = document.getElementById("canvas");
                var windows = jsPlumb.getSelector(".statemachine .w");
    

                // bind a double click listener to "canvas"; add new node when this occurs.
                jsPlumb.on(canvas, "dblclick", function(e) {
                    self.newNode(e.offsetX, e.offsetY);
                });


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



                // suspend drawing and initialise.
                self.instance.batch(function() {
                    for (var i = 0; i < windows.length; i++) {
                        self.initNode(windows[i], true);
                    }
                });

            });

        };


        //
        // initialise element as connection targets and source.
        //
        ChartView.prototype.initNode = function(el) {

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
                    faces: ["top", "bottom"]
                }],
                allowLoopback: true
            });


        };

        ChartView.prototype.newNode = function(x, y, state_data) {
            if (!state_data) {
                state_data = {
                    name: "state " + state_counter,
                    id: guid(),
                    mappings: []
                };
                state_counter++;
            }
            var html;
            var d = document.createElement("div");
            var id = state_data.id;
            d.className = "w";

            if (state_data.name == "start") {
                d.className = "start w";
                html = startTemplate(state_data);
            } else if (state_data.name == "die") {
                d.className = "die w";
                html = startTemplate(state_data);
            } else {
                html = stateTemplate(state_data);
            }
            d.id = id;
            d.innerHTML = html;

            d.style.left = x + "px";
            d.style.top = y + "px";
            this.instance.getContainer().appendChild(d);
            this.initNode(d);
            for (var i = 0; i < state_data.mappings.length; i++) {
                console.log("mapping to add", state_data.mappings[i]);
                this.addMapping(d.id, state_data.mappings[i]);
            }
            return d;
        };

        ChartView.prototype.addMapping = function(target_state, mapping_data) {
            var html = mappingTemplate(mapping_data);
            console.log("target_state = ", target_state);
            $("#" + target_state + " .state .mappings").append(html);
            var self = this;
            $(".block").each(function(index) {
                self.instance.draggable($(this));

                $(this).on("mousedown", function(e) {
                    var styles = {
                        left: e.offsetX + "px",
                        top: e.offsetX + "px"
                    };
                    $(this).css(styles);
                    $(this).addClass("block-draggable");
                    block_was_dragged = $(this);

                });

            });

        };

        ChartView.prototype.initializeBehavior = function(data) {
            var self = this;
            for (var i = 0; i < data.states.length; i++) {
                this.newNode(400 * i + 60, 100, data.states[i]);
            }
            for (var j = 0; j < data.transitions.length; j++) {
                console.log("connecting ", data.transitions[j].toState, "to", data.transitions[j].fromState);
                var connection = this.instance.connect({
                    source: data.transitions[j].fromState,
                    target: data.transitions[j].toState,
                    type: "basic"
                });
                var connection_id = data.transitions[j].id;
                console.log("connection id",connection_id,name);
                connection.addOverlay(["Custom", {
                    create: function(component) {
                        console.log("transition html = ", data.transitions[j]);
                        var html = transitionTemplate(data.transitions[j]);
                        return $(html);
                    },
                    location: 0.5,
                    id: "transition_"+connection_id
                }]);

                connection.addOverlay(["Custom", {
                    create: function(component) {

                        var html = "<div><div class = 'transition_toggle'>+</div></div>";
                        return $(html);
                    },
                    location: 0.5,
                    id: "toggle_"+connection_id,
                    events:{
          click:function(customOverlay, originalEvent) { 
            console.log("connection",connection_id,customOverlay);
            connection.getOverlay("transition_"+connection_id).show(); 
          }
        }
                }]);

                connection.getOverlay("transition_"+connection_id).hide();

            }



        };

        ChartView.prototype.behaviorChange = function(behaviorEvent, data) {
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

        };

        ChartView.prototype.animateBehaviorChange = function(self) {
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
        };


        function guid() {
            function s4() {
                return Math.floor((1 + Math.random()) * 0x10000)
                    .toString(16)
                    .substring(1);
            }
            return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
                s4() + '-' + s4() + s4() + s4();
        }


        return ChartView;
    });