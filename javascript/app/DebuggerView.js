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

      findBuddies(rowId) {
        var buddy = '';
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
              for (var i = 0; i < self.model.collection.getCurrHighlighted().length; i++) {
                // console.log("unlighting ~ ");
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
                if (buddy !== '') {
                  self.highlightParamRow(buddy);
                  self.model.collection.pushCurrHighlighted(buddy); 
                  self.model.collection.updateHighlight([buddy, true]);                
                }
              } 
              self.currInspectorActive = activeInspector;
            } 
          }
        });
      }

      highlightParamRow(rowId) {
       // $('#'+rowId).css('outline', '1px solid #0f0');
       $('#'+rowId).css('border', '1px solid #00ff03');
      }

      unhighlightParamRow(unhighlightRowId) {
        $('#'+unhighlightRowId).css('border', '');
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
        console.log("~~~ data is ", data);
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
          $('#param-dx')[0].previousElementSibling.id = 'param-posy';
          $('#param-posy')[0].previousElementSibling.id = 'param-posx';
        }
          this.setUpHighlightClicks('brush');
      }
      
      modifyInspectorInput() {
        if ($('#param-force').length) {
          $('#param-force')[0].previousElementSibling.id = 'param-styy';
          $('#param-styy')[0].previousElementSibling.id = 'param-styx';           
        }
          this.setUpHighlightClicks('input');  
      }
      modifyInspectorOutput() {
        $('#param-h')[0].previousElementSibling.id = 'param-outweight';                        
        this.setUpHighlightClicks('output');
      }



      onTabChange(){

      }

      

    };

    return DebuggerView;


  });