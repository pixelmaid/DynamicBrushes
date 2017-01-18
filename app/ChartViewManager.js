//ChartViewManager.js
'use strict';
define(["jquery","app/ChartView"],

    function($,ChartView) {

        var ChartViewManager= class {

            constructor(model, element) {
                this.el = $(element);
                this.model = model;
               this.views = [];

                var self = this;

              
                //this.model.addListener("ON_DESTROY_ALL_CHARTS", this.destroyCharts);
                //this.model.addListener("ON_ADD_CHART", this.addChart);

            }

            destroyAllCharts() {
             /* for(var i=0;i<this.views.length;i++){
                this.views[i].destroy();
               }*/
               $('#canvas').empty()
               this.views.length = 0;
            }


            addChart(data) {
                var chartView = new ChartView(data.id);
            chartView[data.id] = chartView;
            chartView.initializeBehavior(data); 
            this.views.push(chartView);
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