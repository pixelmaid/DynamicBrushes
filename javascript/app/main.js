'use strict';

define(["jquery", "paper", "handlebars", "app/id", "app/DebuggerModelCollection", "app/DebuggerView", "app/SaveManager", "app/SaveView", "app/SignalView", "app/SocketController", "app/SocketView", "app/ChartViewManager", "app/graph", "app/PositionSeries", "app/AngleSeries", "app/AreaChart", "app/DatasetView", "app/SignalModel", "app/KeypressHandler", "hbs!app/templates/brushInspector","hbs!app/templates/inputInspector","hbs!app/templates/outputInspector"],
 
    function($, paper, Handlebars, ID, DebuggerModelCollection, DebuggerView, SaveManager, SaveView, SignalView, SocketController, SocketView, ChartViewManager, Graph, PositionSeries, AngleSeries, AreaChart, DatasetView, SignalModel, KeypressHandler,brushInspectorTemplate,inputInspectorTemplate,outputInspectorTemplate) {

        var socketController = new SocketController();
        var socketView = new SocketView(socketController, "#socket");
        var signalModel = new SignalModel();
        var signalView = new SignalView(signalModel, "#scripts");
        var chartViewManager = new ChartViewManager(signalModel, "#canvas");
        var saveManager = new SaveManager();
        var saveView = new SaveView(saveManager, "#save-menu");
        var codename;
        var dataView = new DatasetView(signalModel.datasetLoader, "#dataset_select");
        var keypressHandler = new KeypressHandler(debuggerModelCollection);
        var debuggerModelCollection = new DebuggerModelCollection();
        var debuggerBrushView = new DebuggerView(debuggerModelCollection.brushModel, "#inspector-brush", brushInspectorTemplate, "brush", keypressHandler);
        var debuggerInputView = new DebuggerView(debuggerModelCollection.inputModel, "#inspector-input", inputInspectorTemplate, "inputGlobal", keypressHandler);
        // note -- make one for inputLocal? 
        var debuggerOutputView = new DebuggerView(debuggerModelCollection.outputModel, "#inspector-output", outputInspectorTemplate, "output", keypressHandler);

        //sets up interface by initializing palette, removing overlay etc.
        var setupInterface = function() {

            requestFileList(codename);
            requestExampleFileList();
            
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

                if (data.authoring_type == "signal_initialized") {
                    console.log("process signal authoring response");
                    signalView.processAuthoringResponse(data);
                } else if (data.authoring_type == "dataset_loaded") {
                    console.log("process signal authoring response");
                    console.log("process dataset loaded authoring response");

                    signalModel.datasetLoader.loadCollection(data.dataset);

                } else {
                    chartViewManager.processAuthoringResponse(data);
                }

            } else if (data.type == "inspector_data") {
                if(data.data.type == "signal_data"){
                    chartViewManager.processInspectorData(data.data);

                } else if (data.data.type == "highlight") {
                    debuggerModelCollection.processInspectorData(data.data);
                }
                else{
                    debuggerModelCollection.processInspectorDataQueue(data.data);
                }

            } else if (data.type == "synchronize") {
                hideOverlay();
                signalView.clearPalette();
                var currentBehaviorName = data["currentBehaviorName"];
                var currentBehaviorFile = data["currentFile"];
                console.log("currentBehaviorName=", currentBehaviorName, currentBehaviorFile);
                chartViewManager.synchronize(data.data.behaviors);
                signalModel.datasetLoader.loadCollection(data.data.collections);
                saveManager.setCurrentFilename(currentBehaviorName, currentBehaviorFile);
                debuggerModelCollection.clearInspectorDataQueue();
                updateSelectedBehaviorAndBrush();


            } else if (data.type == "collection_data") {
                signalModel.datasetLoader.loadCollection(data.data.collections);
            } else if (data.type == "storage_data") {
                saveManager.loadStorageData(data);
            }else if (data.type == "data_request_response"){
                 chartViewManager.updateProperties(data);
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
            updateSelectedBehaviorAndBrush();

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
                    targetFolder: "saved_files/" + artistName + "/behaviors/",
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

        var stepForward = function(){
              var step_data = {
                type: "debug_request",
                requester: "authoring",
                data: {
                    type: "stepForward",
                }

            };
            socketController.sendMessage(step_data);
        };

        var updateSelectedBehaviorAndBrush = function(){
            var instance_data = {
                type: "debug_request",
                requester: "authoring",
                data: {
                    type:"selectedBehaviorAndBrushUpdate",
                    activeInstance: debuggerModelCollection.selectedIndex,
                    currentlySelectedBehaviorId: chartViewManager.currentView.id
                }
            };

            socketController.sendMessage(instance_data);

        };

        var onHighlightRequest= function(data){
            var instance_data = {
                type: "debug_request",
                requester: "authoring",
                data: {
                    type:"highlightRequest",
                    data: data
                }
            };

            socketController.sendMessage(instance_data);

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

        var onKeyNotRecognized = function() {
            codename = prompt("login key not recognized, please re-enter your key");
            if (codename !== null) {
                saveManager.setCodeName(codename);
                socketController.connect(codename);
            }
        };

        var onDataReady = function(dataset) {
            console.log("transmit_data set data", dataset);
            var data = {
                dataset: dataset,
                type: "dataset_loaded"
            };
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
        socketController.addListener("ON_KEY_NOT_RECOGNIZED", onKeyNotRecognized);
        socketController.addListener("ON_KEY_RECOGNIZED", onKeyRecognized);

        chartViewManager.addListener("ON_AUTHORING_EVENT", onAuthoringEvent);
        keypressHandler.addListener("STEP_FORWARD", stepForward);

        chartViewManager.addListener("ON_DATA_REQUEST_EVENT", onDataRequestEvent);

        signalView.addListener("ON_AUTHORING_EVENT", onAuthoringEvent);

        saveManager.addListener("ON_SAVE_EVENT", onStorageEvent);
        debuggerModelCollection.addListener("ON_ACTIVE_INSTANCE_CHANGED",updateSelectedBehaviorAndBrush);

        debuggerModelCollection.addListener("ON_HIGHLIGHT_REQUEST",onHighlightRequest);

        signalModel.datasetLoader.addListener("ON_IMPORTED_DATASET_READY", onDataReady);
        promptConnect();

        $( ".palette block" ).mousedown(function() {
          $(".reference_expression expression").css("border", "1 px solid #00ff00");
          console.log("mousedown palette");
        });
        $( ".palette block" ).mouseup(function() {
            $(".reference_expression expression").css("border", "1 px solid #ccc");
          console.log("mouseup palette");
        });


    }
    );