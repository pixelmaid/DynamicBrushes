//Debugger View

"use strict";

define(["jquery", "handlebars", "app/Emitter"],

  function($, Handlebars, Emitter) {


    var DebuggerView = class extends Emitter {


      constructor(model, element, template, groupName, keyHandler) {
        super();
        this.el = $(element);
        this.model = model;
        
        this.inspectorInit = false;
        this.groupName = groupName; //brush, input, or output
        this.template = template;
        this.currInspectorActive = '';
        var self = this;

        this.model.addListener("DATA_UPDATED", function() {
          this.dataUpdatedHandler();
        }.bind(this));

        this.model.addListener("DATA_HIGHLIGHTED", function(data) {
          console.log("~~~~ data highlighted  in view ", data);
          this.highlightParamRow(data);            
          self.model.collection.pushCurrHighlighted(data);
        }.bind(this));

        this.model.addListener("DATA_UNHIGHLIGHTED", function() {
          console.log("~~~~ data unhighlighted  in view ");
          for (var i = 0; i < this.model.collection.getCurrHighlighted().length; i++) {
            let p = this.model.collection.getCurrHighlighted()[i];
            this.unhighlightParamRow(p);
          }
          this.model.collection.resetCurrHighlighted();
        }.bind(this));
      }

      findMethodBuddy(rowId) {
         var buddy = "";
        switch (rowId) {
          case 'param-ox':
            buddy = 'setOrigin';
          break;
          case 'param-oy':
            buddy = 'setOrigin';
          break;
          case 'param-pen':
            buddy = 'penDown';
          break;
        }
        return buddy;
      }

      findDataBuddy(rowId) {
        var buddy = "";
        switch (rowId) {
          case 'gen-sawtooth':
            buddy = 'sawtooth wave';
          break;
          case 'gen-sine':
            buddy = 'sine wave';
          break;
          case 'gen-triangle':
            buddy = 'triangle wave';
          break;
          case 'gen-random':
            buddy = 'random';
          break;
          case 'gen-square':
            buddy = 'square wave';
          break;
          case 'param-stydy':
            buddy = 'stylus y';
          break;
          case 'param-stydx':
            buddy = 'stylus delta x';
          break;
          case 'param-styy':
            buddy = 'stylus delta y';
          break;
          case 'param-styx':
            buddy = 'stylus x';
          break;
           case 'param-force':
            buddy = 'stylus force';
          break;
          case 'param-stylusEvent':
            buddy = 'stylus event';
          break;


        }
        return buddy;
      }

      findMappingBuddies(rowId) {
        var buddy = "";
        switch (rowId) {
          case 'param-dx':
            buddy = 'dx';
          break;
          case 'param-dy':
            buddy = 'dy';
          break;
          case 'param-sx':
            buddy = 'sx';
          break;
           case 'param-sy':
            buddy = 'sy';
          break;
          case 'param-sy':
            buddy = 'param-sy';
          break; 
          case 'param-rotation':
            buddy = 'rotation';
          break;
          case 'param-dx':
            buddy = 'param-dy';
          break;
          case 'param-dy':
            buddy = 'param-dx';
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


      findBuddies(rowId) {
        var buddy = "";
        switch (rowId) {
          case 'param-ox':
            buddy = 'param-oy';
          break;
          case 'param-oy':
            buddy = 'param-ox';
          break;
          case 'param-dx':
            buddy = 'param-dy';
          break;
          case 'param-dy':
            buddy = 'param-dx';
          break;
          case 'param-styx':
            buddy = 'param-styy';
          break;
          case 'param-styy':
            buddy = 'param-styx';
          break;
          case 'param-dx':
            buddy = 'param-dy';
          break;
          case 'param-dy':
            buddy = 'param-dx';
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


      setUpGeneratorClicks() {
        let self = this;
        $('.sub-sub-group-inspector').click(function(e){
          let rowId = e.target.id;
          var skip = false;

          //unhighlight others
          for (var i = 0; i < self.model.collection.getCurrHighlighted().length; i++) {
            self.unhighlightParamRow(self.model.collection.getCurrHighlighted()[i]);
            self.model.collection.updateHighlight([self.model.collection.getCurrHighlighted()[i], false]);   
            if (rowId == self.model.collection.getCurrHighlighted()[i]) { //unhighlight self
              skip = true;
            }
          }
          self.model.collection.resetCurrHighlighted();

          if (!skip) {
            //highlight self 
               
            self.highlightParamRow(rowId);

            self.model.collection.pushCurrHighlighted(rowId);
            self.model.collection.updateHighlight([rowId, true]);   
        
          }  

        });
      }

      setUpHighlightClicks(inspectorKind) {
        let self = this;
        // console.log("~~ before change id ", self.model.collection.getCurrHighlighted(), inspectorKind, self.currInspectorActive);

        $('li').click(function(e) {
          let rowId = e.target.id;
          var skip = false;
          if (rowId.includes("param-")) {
            let activeInspector = $('#'+rowId).parent().parent().parent().parent()[0].id.slice(10);
            if (activeInspector == inspectorKind) { //if match 
              console.log("~ active ", activeInspector, inspectorKind, rowId);
              var buddy = self.findBuddies(rowId);
              var mappingBuddy = self.findMappingBuddies(rowId);
              var methodBuddy = self.findMethodBuddy(rowId);
              var dataBuddy = self.findDataBuddy(rowId);

              for (var i = 0; i < self.model.collection.getCurrHighlighted().length; i++) {
                // console.log("unlighting ~ ");
                self.unhighlightParamRow(self.model.collection.getCurrHighlighted()[i]);
                self.unhighlightMappingBuddy(self.model.collection.getCurrHighlightedMappings()[i]);
                self.unhighlightMethodBuddy(self.model.collection.getCurrHighlightedMethods()[i]);
                self.unhighlightDataBuddy(self.model.collection.getCurrHighlightedData()[i]);

                self.model.collection.updateHighlight([self.model.collection.getCurrHighlighted()[i], false]);   
                if (rowId == self.model.collection.getCurrHighlighted()[i]) { //unhighlight self
                  skip = true;
                  self.unhighlightParamRow(buddy);
                  self.unhighlightMappingBuddy(mappingBuddy);
                  self.unhighlightMethodBuddy(methodBuddy);
                  self.unhighlightDataBuddy(dataBuddy);
                  self.model.collection.updateHighlight([buddy, false]);   
                }
              }
              self.model.collection.resetCurrHighlighted();
              self.model.collection.resetCurrHighlightedMethods();
              self.model.collection.resetCurrHighlightedMappings();
              self.model.collection.resetCurrHighlightedData();


              if (!skip) {
                self.highlightParamRow(rowId);

                self.model.collection.pushCurrHighlighted(rowId);
                self.model.collection.updateHighlight([rowId, true]);   
                if (buddy !== '') {
                  self.highlightParamRow(buddy);
                  self.model.collection.pushCurrHighlighted(buddy); 
                  self.model.collection.updateHighlight([buddy, true]);                
                }
                if (mappingBuddy !== '') {
                  self.highlightMappingBuddy(mappingBuddy);
                   self.model.collection.pushCurrHighlightedMappings(mappingBuddy);          
                }
                if (methodBuddy !== '') {
                  self.highlightMethodBuddy(methodBuddy);  
                  self.model.collection.pushCurrHighlightedMethods(methodBuddy);          
        
                }
                if (dataBuddy !== '') {
                  self.highlightDataBuddy(dataBuddy);
                  self.model.collection.pushCurrHighlightedData(dataBuddy);          
          
                }
              } 
              self.currInspectorActive = activeInspector;
            } 
          }
        });
      }

      highlightParamRow(rowId) {
      
       $('#'+rowId).css('border', 'px solid #00ff03');
      }

      unhighlightParamRow(rowId) {
        $('#'+rowId).css('border', '');
      }

      highlightMethodBuddy(rowId) { 
        $('[fieldName='+rowId+']').css('border', '3px solid #00ff03');
      }

      unhighlightMethodBuddy(rowId) {
         $('[fieldName='+rowId+']').css('border', '');
      }

      highlightMappingBuddy(rowId) { 
        $('[name='+rowId+']').css('border', '3px solid #00ff03');
      }

      unhighlightMappingBuddy(rowId) {
         $('[name='+rowId+']').css('border', '');
      }

      highlightDataBuddy(rowId) { 
        $('span:contains('+rowId+')').css('border', '3px solid #00ff03');
      }

      unhighlightDataBuddy(rowId) {
         $('span:contains('+rowId+')').css('border', '');
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
        console.log("~~~ init inspector, data is ", data);
        if (!data){ return;}
        var groupName;
        let self = this;
        var html = this.template(data);
        this.el.html(html);


        if (data["groupName"]) {
          groupName = data["groupName"];
        } else {
          groupName = data["global"]["groupName"]; //inputGlobal
          if (data["local"]["groupName"] == "generator") {
            self.setUpGeneratorClicks();
          }
        }

        if (groupName == 'inputGlobal') {
          self.modifyInspectorInput();          
        }
        else if (groupName == 'brush') {
          self.modifyInspectorBrush();          
        }
        else if (groupName == 'output') {
          self.modifyInspectorOutput();          
        }

        //rehighlight
        for (var i = 0; i < this.model.collection.getCurrHighlighted().length; i++) {
          // console.log("~ rehighlighting ", self.model.collection.getCurrHighlighted()[i]);
          this.highlightParamRow(this.model.collection.getCurrHighlighted()[i]);

        }      
      }

      

      modifyInspectorBrush() {
        if ($('#param-dx').length) {
          $('#param-dx')[0].previousElementSibling.id = 'param-rotation';
          $('#param-dy')[0].previousElementSibling.id = 'param-dx';
        }
          this.setUpHighlightClicks('brush');

        let selectables = ["#param-ox", "#param-oy", "#param-sx", "#param-sy",
          "#param-rotation", "#param-dx", "#param-dy"];
        for (var i = 0; i < selectables.length; i++) {
          $(selectables[i]).css("font-weight","Bold");
        }
      }
      
      modifyInspectorInput() {
        if ($('#param-force').length) {
          $('#param-force')[0].previousElementSibling.id = 'param-stydy';
          $('#param-stydy')[0].previousElementSibling.id = 'param-stydx';           
          $('#param-stydx')[0].previousElementSibling.id = 'param-styy';           
          $('#param-styy')[0].previousElementSibling.id = 'param-styx';           

        }
          this.setUpHighlightClicks('input');  

        let selectables = ["#param-styx", "#param-styy", "#param-force"];
        for (var i = 0; i < selectables.length; i++) {
          $(selectables[i]).css("font-weight","Bold");
        }
      }

      modifyInspectorOutput() {
        let selectables = ["#param-x", "#param-y"];
        for (var i = 0; i < selectables.length; i++) {
          $(selectables[i]).css("font-weight","Bold");
        }

        $('#param-h')[0].previousElementSibling.id = 'param-outweight';                        
        this.setUpHighlightClicks('output');
      }



      onTabChange(){

      }

      

    };

    return DebuggerView;


  });