//ChartViewManager.js
'use strict';
define(["jquery","app/ChartView"],

    function($,ChartView) {

        var ChartViewManager= class {

            constructor(model, element) {
                this.el = $(element);
                this.model = model;
               this.views = [];
               this.currentView = null;
                var self = this;

              
                this.model.addListener("ON_INITIALIZE_STATE", function(x,y,data) {this.addState(x,y,data);}.bind(this));
                this.model.addListener("ON_INITIALIZE_BEHAVIOR", function(data) {this.addBehavior(data);}.bind(this));

                //this.model.addListener("ON_ADD_CHART", this.addChart);

            }

            destroyAllCharts() {
             /* for(var i=0;i<this.views.length;i++){
                this.views[i].destroy();
               }*/
               $('#canvas').empty();
               this.views.length = 0;
            }

            addBehavior(data){
                console.log("add behavior",data,this);
                var chartView = new ChartView(data.id);
                chartView[data.id] = chartView;
                chartView.initializeBehavior(data); 
                this.views.push(chartView);
               this.currentView = chartView;
                console.log("add behavior",data,this.currentView);

            }

            addState(x,y,data){
                console.log("add state",x,y,data);
                this.currentView.newNode(x,y,data);
            }


            behaviorChange(data){
                 if(this.views[data.behavior_id]){
                        console.log("behavior found for ",data.brush_name);
                        this.views[data.behavior_id].behaviorChange(data.event,data.data);
                    }
            }



        };

        return ChartViewManager;

    });