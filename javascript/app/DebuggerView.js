//Debugger

"use strict";

define(["jquery", "handlebars", "app/Emitter"],

  function($, Handlebars, Emitter) {


    var DebuggerView = class extends Emitter {


      constructor(model, element, template, groupName, keyHandler) {
        super();
        this.el = $(element);
        this.model = model;
        this.pastConstraint = null;
        this.inspectorInit = false;
        this.keyHandler = keyHandler;
        this.groupName = groupName; //brush, input, or output
        this.template = template;
        var self = this;
       


        switch (this.groupName) {
          case "brush":
            this.keyHandler.addListener("VIZ_BRUSH_STEP_THROUGH", function() {
              console.log("! called brush step through");
              let currentConstraint = this.model.brushVizQueue.shift();
              this.visualizeStepThrough(currentConstraint, this.pastConstraint, model.data);
              this.pastConstraint = currentConstraint;
            }.bind(this));
            break;
          case "inputGlobal":
            break;
          case "inputLocal":
            break;
          case "output":
            break;
        }

        this.model.addListener("DATA_UPDATED", function() {
          this.dataUpdatedHandler();
        }.bind(this));
      }



      dataUpdatedHandler() {
        this.initInspector(this.model.data);
      }


      /* getDataGroup(inputArray, val) {
         var group = inputArray.find(function(e) {
           return e["groupName"] == val;
         });
         return group;
       }

       getBlockGroup(inputArray, val) {
         //eg getBlockGroup(this.DataGroup["blocks"], "geometry")
         var group = inputArray.find(function(e) {
           return e["blockName"] == val;
         });
         return group;
       }

       getParam(group, key) {
         for (var i = 0; i < group["blocks"].length; i++) {
           var v;
           //iterate through blocks 
           var params = group["blocks"][i]["params"];
           params.find(function(e) {
             if (e["id"] == key) {
               console.log("~~ param found", e["val"]);
               v = e["val"];
               return v;
             }
           });
         }
       }*/

      initInspector(data) {
        console.log("adding inspector with data", data);
        var html = this.template(data);
        this.el.html(html);
      }



      visualizeStepThrough(constraint, pastConstraint, data) {
        console.log("! visualizing constraints ", data, " past constraint ", pastConstraint);
        var arrowObject;
        if (pastConstraint) {
          switch (pastConstraint.type) {
            case "method":
              $("#" + pastConstraint.methodId).removeClass("method-inspect");
              break;
            case "binding":
              $("#" + pastConstraint.constraintId).removeClass("debug");
              $("#param-" + pastConstraint.relativePropertyName).removeClass("debug-inspect");
              break;
            case "transition":
              if (pastConstraint.transitionId == "start") {
                $(".setup").children().eq(1).removeClass("start-highlight");
              } else if ($("#" + pastConstraint.transitionId).hasClass("transition_statement")) {
                $("#" + pastConstraint.transitionId).children().first().removeClass("method-inspect");
              } else { //it's a state
                $("#" + pastConstraint.transitionId).children().eq(1).removeClass("active");
              }
              //remove arrow highlight                     
              arrowObject = $("#" + pastConstraint.transitionId).parent().prev();
              arrowObject.children().eq(1).attr("stroke", "#efac1f");
              arrowObject.children().eq(2).attr("stroke", "#efac1f");
              arrowObject.children().eq(2).attr("fill", "#efac1f");
              break;
          }
        }

        switch (constraint.type) {
          case "method":
            console.log("!!VIZ METHOD ", constraint);
            $("#" + constraint.methodId).addClass("method-inspect");
            break;
          case "binding":
            $("#" + constraint.constraintId).addClass("debug");
            $("#param-" + constraint.relativePropertyName).addClass("debug-inspect");
            // console.log("data is ", this.model.data);
            $("#" + data.currentState).children(".state").addClass("active");

            let id = constraint.relativePropertyName;


            break;
          case "transition":
            console.log("!!VIZ TRANSITION ", constraint, pastConstraint);
            if (constraint.transitionId == "start") {
              $(".setup").children().eq(1).addClass("start-highlight");
            }
            if ($("#" + constraint.transitionId).hasClass("transition_statement")) {
              //outline header
              $("#" + constraint.transitionId).children().first().addClass("method-inspect");
            } else { //it's a state
              $("#" + constraint.transitionId).children().eq(1).addClass("active");
            }
            //add arrow highlight                     
            arrowObject = $("#" + constraint.transitionId).parent().prev();
            arrowObject.children().eq(1).attr("stroke", "aqua");
            arrowObject.children().eq(2).attr("stroke", "aqua");
            arrowObject.children().eq(2).attr("fill", "aqua");
            break;
        }

      }

    };

    return DebuggerView;


  });