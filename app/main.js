'use strict';
define(["jquery", "paper", "handlebars", "app/id", "app/PaletteModel", "app/PaletteView", "app/SocketController", "app/SocketView", "app/ChartViewManager", "app/graph", "app/PositionSeries", "app/AngleSeries", "app/AreaChart"],


    function($, paper, Handlebars, ID, PaletteModel, PaletteView, SocketController, SocketView, ChartViewManager, Graph, PositionSeries, AngleSeries, AreaChart) {

        var socketController = new SocketController();
        var socketView = new SocketView(socketController, "#socket");
        var paletteModel = new PaletteModel();
        var paletteView = new PaletteView(paletteModel, "#palette");
        var chartViewManager = new ChartViewManager(paletteModel, "#canvas");


        var onMessage = function(data) {
            console.log("ON MESSGE CALLED", data);
            if (data.type == "behavior_data") {
                chartViewManager.destroyAllCharts();
                if (data.data instanceof Array) {
                    for (var i = 0; i < data.data.length; i++) {
                        console.log("data at", i, data.data[i]);
                        chartViewManager.addBehavior(data.data[i]);
                    }
                } else {
                    chartViewManager.addBehavior(data.data);
                }


            } else if (data.type == "behavior_change") {

            } else if (data.type == "authoring_response") {
                   
                   
                        chartViewManager.processAuthoringResponse(data);
                        
                
            }
        };

        var onConnection = function() {
            console.log("connection made");
        };

        var onAuthoringEvent = function(data) {
            console.log("transmit_data", data);

            var transmit_data = {
                type: "authoring_request",
                requester: "authoring",
                data: data

            };
            socketController.sendMessage(transmit_data);
             chartViewManager.processAuthoringResponse(transmit_data);
        };




        socketController.addListener("ON_MESSAGE", onMessage);
        socketController.addListener("ON_CONNECTION", onConnection);
        chartViewManager.addListener("ON_AUTHORING_EVENT", onAuthoringEvent);
       


    });



