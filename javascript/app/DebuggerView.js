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
        this.currInspectorActive = '';
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

      findBuddies(rowId) {
        var buddy = ''
        switch (rowId) {
          case 'param-ox':
            buddy = 'param-oy';
          break;
          case 'param-oy':
            buddy = 'param-ox';
          break;
          case 'param-styx':
            buddy = 'param-styy';
          break;
          case 'param-styy':
            buddy = 'param-styx';
          break;
          case 'param-posx':
            buddy = 'param-posy';
          break;
          case 'param-posy':
            buddy = 'param-posx';
          break;
          case 'param-x':
            buddy = 'param-y';
          break;
          case 'param-y':
            buddy = 'param-x';
          break;

        }
        return buddy;
      }

      setUpHighlightClicks(inspectorKind) {
        let self = this;
        console.log("~~ before change id ", self.model.collection.getCurrHighlighted(), inspectorKind, self.currInspectorActive);
  

        $('li').click(function(e) {
          let rowId = e.target.id
          var skip = false;
          if (rowId.includes("param-")) {
            let activeInspector = $('#'+rowId).parent().parent().parent().parent()[0].id.slice(10);
            // console.log("~ active ", activeInspector, inspectorKind, rowId);
            if (activeInspector == inspectorKind) { //if match 
              var buddy = self.findBuddies(rowId);
              for (var i = 0; i < self.model.collection.getCurrHighlighted().length; i++) {
                console.log("unlighting ~ ");
                self.unhighlightParamRow(self.model.collection.getCurrHighlighted()[i]);
                self.model.collection.updateHighlight([self.model.collection.getCurrHighlighted()[i], false]);   
                if (rowId == self.model.collection.getCurrHighlighted()[i]) { //unhighlight self
                  skip = true;
                  self.unhighlightParamRow(buddy);
                  self.model.collection.updateHighlight([buddy, false]);   
                }
              }
              self.model.collection.resetCurrHighlighted();
              if (!skip) {
                self.highlightParamRow(rowId);
                self.model.collection.pushCurrHighlighted(rowId);
                self.model.collection.updateHighlight([rowId, true]);   
                if (buddy != '') {
                  self.highlightParamRow(buddy);
                  self.model.collection.pushCurrHighlighted(buddy); 
                  self.model.collection.updateHighlight([buddy, true]);                
                }
              }
              self.currInspectorActive = activeInspector;
            } 
          }
        })
      }

      highlightParamRow(rowId) {
        $('#'+rowId).css('outline', '1px solid #0f0');
        console.log("~~~ highlighted ", rowId);
      }

      unhighlightParamRow(unhighlightRowId) {
        $('#'+unhighlightRowId).css('outline', '');
      }


      dataUpdatedHandler() {
        var self = this;
        this.initInspector(this.model.data);
        var prev = null;

        $('input[name="'+(this.groupName == "inputGlobal" ? "generator": this.groupName)+'tabs"]').each(function (index,value) { 
            value.addEventListener('change', function() {
               (prev) ? console.log("%%%",prev.value): null;
               if (this !== prev) {
                 prev = this;
               }
              console.log("%%%",index);
              self.model.updateSelectedIndex(index);
            });
        });
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
        let self = this;
        var html = this.template(data);
        this.el.html(html);
        if (data['groupName'] == 'brush') {          
          $('#param-dx')[0].previousElementSibling.id = 'param-posy';
          $('#param-posy')[0].previousElementSibling.id = 'param-posx';   
          this.setUpHighlightClicks('brush');
        } 
        else if (data['groupName'] != 'output' && data['global']['name'] == 'Global Input') {
          $('#param-force')[0].previousElementSibling.id = 'param-styy';
          $('#param-styy')[0].previousElementSibling.id = 'param-styx'; 
          this.setUpHighlightClicks('input');  
        } else {
          this.setUpHighlightClicks('output');
        }

        //rehighlight
        for (var i = 0; i < self.model.collection.getCurrHighlighted().length; i++) {
          console.log("~ rehighlighting ", self.model.collection.getCurrHighlighted()[i]);
          self.highlightParamRow(self.model.collection.getCurrHighlighted()[i]);
        }

      }



      onTabChange(){

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