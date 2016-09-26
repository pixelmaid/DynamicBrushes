//flowchartview
"use strict";
define(["jquery", "jquery-ui","jsplumb", "handlebars", "hbs!app/templates/state", "hbs!app/templates/transition", "hbs!app/templates/mapping"

    ],
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
            method: [{
                name: "newStroke()",
                id: "newStroke_1"
            }]
        };

        var ChartView = function() {
            jsPlumb.ready(function() {

                // setup some defaults for jsPlumb.
                var instance = jsPlumb.getInstance({
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
                        }],
                        ["Custom", {
                            create: function(component) {
                                var html = transitionTemplate(default_transition);
                                return $(html);
                            },
                            location: 0.5,
                            id: "customOverlay"
                        }]
                    ],
                    Container: "canvas"
                });

                instance.registerConnectionType("basic", {
                    anchor: "Continuous",
                    connector: ["Flowchart", {
                        stub: [40, 60],
                        gap: 10,
                        cornerRadius: 5,
                        alwaysRespectStubs: true
                    }],
                });

                window.jsp = instance;

                var canvas = document.getElementById("canvas");
                var windows = jsPlumb.getSelector(".statemachine .w");



                // bind a click listener to each connection; the connection is deleted. you could of course
                // just do this: jsPlumb.bind("click", jsPlumb.detach), but I wanted to make it clear what was
                // happening.
                instance.bind("click", function(c) {
                    instance.detach(c);
                });

                // bind a connection listener. note that the parameter passed to this function contains more than
                // just the new connection - see the documentation for a full list of what is included in 'info'.
                // this listener sets the connection's internal
                // id as the label overlay's text.
                instance.bind("connection", function(info) {
                    info.connection.getOverlay("label").setLabel(info.connection.id);
                });

                // bind a double click listener to "canvas"; add new node when this occurs.
                jsPlumb.on(canvas, "dblclick", function(e) {
                    newNode(e.offsetX, e.offsetY, default_state);
                });

                //
                // initialise element as connection targets and source.
                //
                var initNode = function(el) {

                    // initialise draggable elements.
                    instance.draggable(el);

                    instance.makeSource(el, {
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

                    instance.makeTarget(el, {
                        dropOptions: {
                            hoverClass: "dragHover"
                        },
                        anchor: "Continuous",
                        allowLoopback: true
                    });


                };

                var newNode = function(x, y, state_data) {


                    var html = stateTemplate(state_data);
                    var d = document.createElement("div");
                    var id = jsPlumbUtil.uuid();
                    d.className = "w";
                    d.id = id;
                    d.innerHTML = html;
                   
                    d.style.left = x + "px";
                    d.style.top = y + "px";
                    instance.getContainer().appendChild(d);
                    initNode(d);
                     for(var i=0;i<state_data.mappings.length; i++){
                        console.log("mapping to add",state_data.mappings[i]);
                        addMapping(d.id,state_data.mappings[i]);
                    }
                    return d;
                };

                var addMapping = function(target_state, mapping_data){
                       var html = mappingTemplate(mapping_data);
                       $("#"+target_state+" .state .mappings").append(html);
                       $( ".block" ).each(function( index ) {
                        instance.draggable($(this));
                        //$(this).addClass("jsplumb-draggable jsplumb-droppable");
                        //$( this ).draggable();
                     });

                };

                // suspend drawing and initialise.
                instance.batch(function() {
                    for (var i = 0; i < windows.length; i++) {
                        initNode(windows[i], true);
                    }
                    /* var c1 = instance.connect({
                          source: "state_1",
                          target: "state_2",
                          type: "basic"
                      });*/


                });


            });
        };
        return ChartView;
    });