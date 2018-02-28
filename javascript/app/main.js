'use strict';
define(["jquery", "paper", "handlebars", "app/id", "app/SaveManager", "app/SaveView", "app/PaletteModel", "app/PaletteView", "app/SocketController", "app/SocketView", "app/ChartViewManager", "app/graph", "app/PositionSeries", "app/AngleSeries", "app/AreaChart", "app/DatasetView"],


    function($, paper, Handlebars, ID, SaveManager, SaveView, PaletteModel, PaletteView, SocketController, SocketView, ChartViewManager, Graph, PositionSeries, AngleSeries, AreaChart,DatasetView) {

        var socketController = new SocketController();
        var socketView = new SocketView(socketController, "#socket");
        var paletteModel = new PaletteModel();
        var paletteView = new PaletteView(paletteModel, "#scripts");
        var chartViewManager = new ChartViewManager(paletteModel, "#canvas");
        var saveManager = new SaveManager();
        var saveView = new SaveView(saveManager, "#save-menu");
        var codename;
        var dataView = new DatasetView(paletteModel.datasetLoader, "#dataset_select");
        var testingMode = false;
        //sets up interface by initializing palette, removing overlay etc.
        var setupInterface = function(){
            if(testingMode){
                loadDummyData();
            }
            else{
            requestFileList(codename);
            requestExampleFileList();
            }
        };

        var loadDummyData = function(){
            $.getJSON("app/behavior_templates/dummy_data/recording_template.json", function(data) {
                    var sync_data = {data:data,type:"synchronize"};
                    onMessage(sync_data);
                });
        };

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

            }  else if (data.type == "inspector_data") {

                chartViewManager.processInspectorData(data.data);

            }

            else if (data.type == "synchronize") {
                hideOverlay();
                var currentBehaviorName = data["currentBehaviorName"];
                var currentBehaviorFile = data["currentFile"];
                console.log("currentBehaviorName=",currentBehaviorName,currentBehaviorFile);
                console.log("get dummy data",data);

                chartViewManager.synchronize(data);
                saveManager.setCurrentFilename(currentBehaviorName,currentBehaviorFile);

            } else if (data.type == "storage_data") {
                saveManager.loadStorageData(data);
            }

        };  



        var onConnection = function() {
            console.log("connection made");
        };

        var onKeyRecognized = function() {
           setupInterface();
        };

        var onConnectionError = function() {
            if (confirm('There was an error trying to connect. Try again?')) {
                if (codename) {
                    socketController.connect(codename);
                } else {
                    promptConnect();
                }

            } else {
                // Do nothing!
            }
        };



        var onDrawingClientConnected = function() {
            console.log("drawing client connected");
            var transmit_data = {
                type: "synchronize_request",
                requester: "authoring",
                data: {}

            };
           setupInterface();
            socketController.sendMessage(transmit_data);
            
            hideOverlay();

        };

        var onDrawingClientDisconnected = function() {
            console.log("drawing client disconnected");
            showOverlay();
        };

        var onDisconnect = function() {
            if (confirm('You were disconnected. Try to reconnect?')) {
                if (codename) {
                    socketController.connect(codename);
                } else {
                    promptConnect();
                }

            } else {
                // Do nothing!
            }
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

        var onDataRequestEvent = function(data) {
            console.log("transmit_data", data);

            var transmit_data = {
                type: "data_request",
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

        var requestFileList = function(artistName) {
            var file_request_data = {
                type: "storage_request",
                requester: "authoring",
                data: {
                    targetFolder: "saved_files/"+artistName+"/behaviors/",
                    type: "filelist_request",
                    list_type: "behavior_list"
                }

            };
            socketController.sendMessage(file_request_data);
        };

 var requestExampleFileList = function(artistName) {
            var file_request_data = {
                type: "storage_request",
                requester: "authoring",
                data: {
                    targetFolder: "examples/",
                    type: "filelist_request",
                    list_type: "behavior_list"
                }

            };
            socketController.sendMessage(file_request_data);
        };
        var promptConnect = function() {

            codename = prompt("please enter your login key");
            if (codename !== null) {
                saveManager.setCodeName(codename);
                socketController.connect(codename);
            }

        };

        var showOverlay = function() {
            $("#overlay").removeClass("invisible");
            $("#overlay_dialog").removeClass("invisible");
        };

        var hideOverlay = function() {
            $("#overlay").addClass("invisible");
            $("#overlay_dialog").addClass("invisible");
        };

        var onKeyNotRecognized = function(){
             codename = prompt("login key not recognized, please re-enter your key");
            if (codename !== null) {
                saveManager.setCodeName(codename);
                socketController.connect(codename);
            }
        };

        var onDataReady = function(id,dataset){
               console.log("transmit_data set data", dataset);
               var data = {id:id,dataset:dataset,type:"dataset_loaded"};
            var transmit_data = {
                type: "authoring_request",
                requester: "authoring",
                data: data
            };
            socketController.sendMessage(transmit_data);
        };



        socketController.addListener("ON_MESSAGE", onMessage);
        socketController.addListener("ON_DISCONNECT", onDisconnect);

        socketController.addListener("ON_CLIENT_CONNECTED", onDrawingClientConnected);
        socketController.addListener("ON_CLIENT_DISCONNECTED", onDrawingClientDisconnected);
        socketController.addListener("ON_CONNECTION", onConnection);
        socketController.addListener("ON_CONNECTION_ERROR", onConnectionError);
        socketController.addListener("ON_KEY_NOT_RECOGNIZED",onKeyNotRecognized);
        socketController.addListener("ON_KEY_RECOGNIZED",onKeyRecognized);

        chartViewManager.addListener("ON_AUTHORING_EVENT", onAuthoringEvent);
        chartViewManager.addListener("ON_DATA_REQUEST_EVENT", onDataRequestEvent);

        saveManager.addListener("ON_SAVE_EVENT", onStorageEvent);
        paletteModel.addListener("ON_DATASET_READY",onDataReady);
        promptConnect();


    });