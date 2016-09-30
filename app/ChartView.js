//flowchartview
"use strict";
define(["jquery", "jquery-ui", "jsplumb", "handlebars", "hbs!app/templates/state", "hbs!app/templates/transition", "hbs!app/templates/mapping"],



    function($, ui, jsPlumb, Handlebars, stateTemplate, transitionTemplate, mappingTemplate) {
        var default_state = {
            id: "state_3",
            name: "State 3",
            mappings: [{
                    id: "m1",
                    reference: "stylus.x",
                    reference_text: "*10",
                    relative: "x"
                }

            ]
        };

        var default_transition = {
            id: "t_1",
            name: "Transition 1",
            condition_name: "onComplete",
            condition_id: "condition_1",
            method: []
        };

        var block_was_dragged = null;


        var ChartView = function() {
            var self = this;
            jsPlumb.ready(function() {

                // setup some defaults for jsPlumb.
                self.instance = jsPlumb.getInstance({
                    Endpoint: ["Rectangle", {
                        width: 10,
                        height: 10,
                        cssClass: "transendpoint"
                    }],
                    Connector: ["Flowchart", {
                        stub: [40, 60],
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
                    Container: "canvas"
                });

                self.instance.registerConnectionType("basic", {
                    anchor: "Continuous",
                    connector: ["Flowchart", {
                        stub: [40, 60],
                        gap: 10,
                        cornerRadius: 5,
                        alwaysRespectStubs: true
                    }],
                });

                window.jsp = self.instance;
                var canvas = document.getElementById("canvas");
                var windows = jsPlumb.getSelector(".statemachine .w");



                // bind a click listener to each connection; the connection is deleted. you could of course
                // just do this: jsPlumb.bind("click", jsPlumb.detach), but I wanted to make it clear what was
                // happening.
                self.instance.bind("click", function(c) {
                    self.instance.detach(c);
                });

                // bind a connection listener. note that the parameter passed to this function contains more than
                // just the new connection - see the documentation for a full list of what is included in 'info'.
                // this listener sets the connection's internal
                // id as the label overlay's text.
                self.instance.bind("connection", function(info) {
                    info.connection.getOverlay("label").setLabel(info.connection.id);
                    info.connection.connection.addOverlay(["Custom", {
                            create: function(component) {
                                var html = transitionTemplate(default_transition);
                                return $(html);
                            },
                            location: 0.5,
                            id: "customOverlay"
                        }]);
                });

                // bind a double click listener to "canvas"; add new node when this occurs.
                jsPlumb.on(canvas, "dblclick", function(e) {
                    self.newNode(e.offsetX, e.offsetY, default_state);
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
                    /* var c1 = instance.connect({
                          source: "state_1",
                          target: "state_2",
                          type: "basic"
                      });*/
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
                anchor: "Continuous",
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
                anchor: "Continuous",
                allowLoopback: true
            });


        };

        ChartView.prototype.newNode = function(x, y, state_data) {
            var html = stateTemplate(state_data);
            var d = document.createElement("div");
            var id = state_data.id; 
            d.className = "w";
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
            console.log("target_state = ",target_state);
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

        ChartView.prototype.initializeBehavior = function(data){
            var self = this;
            for(var i=0; i<data.states.length; i++){
                this.newNode(400*i+60,100,data.states[i]);
            }
             for(var j=0; j<data.transitions.length; j++){
               console.log("connecting ",data.transitions[j].toState, "to", data.transitions[j].fromState);
               var connection = this.instance.connect({
                          source: data.transitions[j].fromState,
                          target: data.transitions[j].toState,
                          type: "basic"
                      });
               connection.addOverlay(["Custom", {
                            create: function(component) {
                                var html = transitionTemplate(data.transitions[j]);
                                return $(html);
                            },
                            location: 0.5,
                            id: "customOverlay"
                        }]);
                //$("#"+data.transitions[j]+" .block").each(function(index) {
                //self.instance.draggable($(this));

               // $(this).on("mousedown", function(e) {
                   /// var styles = {
                      //  left: e.offsetX + "px",
                        //top: e.offsetX + "px"
                   // };
                   // $(this).css(styles);
                   // $(this).addClass("block-draggable");
                    //block_was_dragged = $(this);

              //  });

            //});

            }



        };



        return ChartView;
    });