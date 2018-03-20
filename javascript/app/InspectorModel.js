//InspectorModel.js
'use strict';
define(["jquery", "jquery-ui", "app/Emitter", "handlebars", 'app/id',"app/InspectorDataController", "app/InspectorView"],

    function($, jqueryui, Emitter, Handlebars, ID, InspectorDataController, InspectorView) {


        var InspectorModel = class extends Emitter {

            constructor(behaviorId,targetId) {
                super();
                console.log("inspector model created",behaviorId,targetId);
                this.targetId = targetId;
                this.behaviorId = behaviorId;
                this.currentData = null;
                this.currentValue = 0;
                this.view = new InspectorView(this);

                var self = this;
                
                InspectorDataController.addListener("DATA_UPDATED", function(data) {
                    this.dataUpdatedHandler();
                }.bind(this));
            }

           
            


            dataUpdatedHandler() {
                
                //todo:updating data handler 
                    var data = InspectorDataController.getLastData();
                    console.log("last data for ",this.targetId,"=",data);
                    for (var key in data) {
                        if (data.hasOwnProperty(key)) {
                            var listeners = data[key]["listeners"];
                            var values = data[key]["values"];
                            if (listeners[this.behaviorId] !== undefined) {
                                if (listeners[this.behaviorId].indexOf(this.targetId) != -1) {
                                    console.log("found self as listener",values);
                                    this.currentData = values;
                                    this.value = this.currentData[0];
                                    clearInterval(this.updateInteval);
                                    this.startUpdateInterval();
                                    return;

                                }

                            }

                        }
                    }
                

                   // var currentData = InspectorDataController.currentVal;
                    //this.el.html(currentData);
                    //clearInterval(this.updateInteva);
                    //startUpdateInterval();
                
            }

            startUpdateInterval() {
                this.updateInteval = setInterval(function() {
                    this.update();
                }.bind(this), 100);
            }


            update(){
                console.log("update called for for ",this.targetId,"=",this.currentValue);

                if(this.currentData.length>0){
                    this.currentValue = this.currentData.shift();
                    this.trigger("DATA_UPDATED");
                }
                else{
                    clearInterval(this.updateInteval);
                }
            }

            


        };

        return InspectorModel;

    });