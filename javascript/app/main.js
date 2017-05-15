'use strict';
define(["jquery", "paper", "handlebars", "app/id", "app/SaveManager", "app/SaveView", "app/PaletteModel", "app/PaletteView", "app/SocketController", "app/SocketView", "app/ChartViewManager", "app/graph", "app/PositionSeries", "app/AngleSeries", "app/AreaChart"],


    function($, paper, Handlebars, ID, SaveManager, SaveView, PaletteModel, PaletteView, SocketController, SocketView, ChartViewManager, Graph, PositionSeries, AngleSeries, AreaChart) {

        var socketController = new SocketController();
        var socketView = new SocketView(socketController, "#socket");
        var paletteModel = new PaletteModel();
        var paletteView = new PaletteView(paletteModel, "#scripts");
        var chartViewManager = new ChartViewManager(paletteModel, "#canvas");
        var saveManager = new SaveManager();
        var saveView = new SaveView(saveManager,"#save-menu");

        var codename = prompt("please enter your login key");
                if (codename !== null) {
                 socketController.connect(codename);
         }

        var onMessage = function(data) {
            console.log("ON MESSGE CALLED", data);
            if (data.type == "behavior_data") {
                chartViewManager.destroyAllViews();
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


            } else if (data.type == "synchronize") {


                chartViewManager.synchronize(data);


            }
            else if (data.type == "storage_data"){
                saveManager.loadStorageData(data);
            }
        };

        var onConnection = function() {
            console.log("connection made");
            requestFileList();
        };

        var onDrawingClientConnected = function() {
            console.log("drawing client connected");
            var transmit_data = {
                type: "synchronize_request",
                requester: "authoring",
                data: {}

            };
            socketController.sendMessage(transmit_data);
            requestFileList();
           
        };

        var onDrawingClientDisconnected = function() {
            //TODO: handle disconnect
        };

        var onAuthoringEvent = function(data) {
            console.log("transmit_data", data);

            var transmit_data = {
                type: "authoring_request",
                requester: "authoring",
                data: data

            };
            socketController.sendMessage(transmit_data);
            
        };
         var onStorageEvent = function(data) {
            console.log("storage_data", data);

            var transmit_data = {
                type: "storage_request",
                requester: "authoring",
                data: data

            };
            socketController.sendMessage(transmit_data);
        };

        var requestFileList = function(){
              var file_request_data = {
                type: "storage_request",
                requester: "authoring",
                data: {
                    targetFolder:"saved_files",
                    type: "filelist_request"
                }

            };
            socketController.sendMessage(file_request_data);
        };




        socketController.addListener("ON_MESSAGE", onMessage);
        socketController.addListener("ON_CLIENT_CONNECTED", onDrawingClientConnected);
        socketController.addListener("ON_CLIENT_DISCONNECTED", onDrawingClientDisconnected);
        socketController.addListener("ON_CONNECTION", onConnection);
        chartViewManager.addListener("ON_AUTHORING_EVENT", onAuthoringEvent);
        saveManager.addListener("ON_SAVE_EVENT", onStorageEvent);



    });