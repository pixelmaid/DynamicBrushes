//InspectorView.js
'use strict';
define(["jquery", "jquery-ui", "handlebars", "app/id","hbs!app/templates/propertyInspector"],

    function($, jqueryui, Handlebars, ID, propertyInspectorTemplate) {


        var InspectorView = class {

            constructor(model) {
                this.model = model;
                this.el = $(propertyInspectorTemplate({id:this.model.targetId,value:this.model.currentValue}));
                $("#canvas").append(this.el);
                var self = this;
               
                this.model.addListener("DATA_UPDATED", function() {
                    this.dataUpdatedHandler();
                }.bind(this));
            }

           

            dataUpdatedHandler() {
                    var currentData = this.model.currentValue;
                    this.el.html(currentData.toFixed(2));        
            }


        };

        return InspectorView;

    });