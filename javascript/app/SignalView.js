//SignalView.js
'use strict';
define(["jquery", "jquery-ui", "handlebars", "hbs!app/templates/palette", "app/id" ,"app/Emitter", 'lib/CollapsibleLists.js'],

    function($, jqueryui, Handlebars, paletteTemplate, ID, Emitter) {


        var live_btn, recordings_btn, datasets_btn, generator_btn, brushes_btn, drawings_btn;

        var SignalView = class extends Emitter {

            constructor(model, element) {
                super();
                this.el = $(element);
                this.initQueue = [];
                this.model = model;
                var self = this;
                self.updateSelectedPalette(model.data[model.selected]);

                live_btn = this.el.find('#live_input');
                recordings_btn = this.el.find('#recordings');
                datasets_btn = this.el.find('#datasets');
                generator_btn = this.el.find('#generators');
                brushes_btn = this.el.find('#brushes');
                drawings_btn = this.el.find('#drawings');
                

                this.btn_list = [live_btn, recordings_btn, datasets_btn, generator_btn, brushes_btn, drawings_btn];

                this.el.droppable({
                    drop: function(event, ui) {
                        console.log("dropped on canvas", ui);
                        $(ui.helper).remove(); //destroy clone
                        $(ui.draggable).remove(); //remove from list
                    }
                });

                this.generatePalette();

               this.model.addListener("ON_DATASET_READY",function(id, data) {
                    console.log("ON_DATA_READY called");
                    var currClass = $("#palette_menu").find(".selected").attr('id');
                    var dataClass = data.items[0].classType;
                    if ((currClass === "recordings" && dataClass === "recording") || 
                        (currClass === "datasets" && dataClass === "imported") ||
                        (currClass === "generators" && dataClass === "generator") ||
                        (currClass === "live_input" && dataClass === "live")) {
                        this.updateSelectedPalette(self.model.data[currClass]);
                        console.log("updating palette in ON_DATA_READY");
                    }
                }.bind(this));
            }

            clearPalette(){
                this.model.setupData();
                console.log("palette cleared");
            }

            generatePalette(){
                console.log("generate palette called");
                var self = this;
                for (var i = 0; i < this.btn_list.length; i++) {
                   this.btn_list[i].click(function(event) {
                        for (var j = 0; j < self.btn_list.length; j++) {
                            self.btn_list[j].removeClass("selected");
                        }
                        self.model.selected = $(event.target).attr('id');
                        $(event.target).addClass("selected");
                        console.log("model selected",self.model.selected,self.model.data);
                        self.updateSelectedPalette(self.model.data[self.model.selected]);
                    });
                }
            }

            updateSelectedPalette(data) {
                var self = this;
                console.log("update selected palette called with data ", data);

                var html = paletteTemplate(data);
                this.el.find('#selected_palette').html(html);
                // console.log("CollapsibleLists is", CollapsibleLists);

              CollapsibleLists.apply(true);
                this.el.find(".palette").mousedown(function(event) {
                   // if (!$(event.target).hasClass("tooltiptext")) {
                        var clone = $("<div></div>");

                        clone.html($(event.target).attr('displayName'));
                        clone.attr("type", $(event.target).attr('type'));
                        clone.attr("name", $(event.target).attr('name'));
                        clone.attr("class", $(event.target).attr('class'));
                        clone.attr("blockstyle", $(event.target).attr('blockstyle'));

                        clone.addClass("drag-n-drop");

                        if ($(event.target).attr('class').indexOf("recording") >= 0) {
                            console.log("CLONE EVENT RECORDING ",  $(event.target).parent().siblings());
                            
                            var recording_title = $(event.target).parent(".data-block").siblings(".data-label").text();
                            console.log("CLONE EVENT RECORDING ", recording_title);
                            clone.attr("title", recording_title);
                        }

                        console.log("cloning", clone);

                        clone.draggable();
                        clone.offset($(event.target).offset());
                        clone.prependTo("body").css('position', 'absolute');
                        clone.trigger(event);
                        var fieldName =  $(event.target).attr('fieldName');
                        var collectionId = $(event.target).attr('collectionId');
                        var classType = $(event.target).attr('type');
                        var displayName = $(event.target).attr('displayName');

                        var id = ID();
                     self.initQueue.push(clone);
                    var transmit_data = {
                   
                        type: "signal_initialized",
                        fieldName: fieldName,
                        displayName: displayName,
                        collectionId: collectionId,
                        classType:classType,
                        id:id
                    };

                

                self.trigger("ON_AUTHORING_EVENT", [transmit_data]);
                    //}

            

                });
            }

            processAuthoringResponse(data){
                 console.log("signal view process authoring response", data, data.result);
                 var lastSignal = this.initQueue.shift();
                 lastSignal.attr('id', data.data.id);
                 this.highlightExpressionAreas(data.data.id);
 
            }

            highlightExpressionAreas(id){
                $(".reference_expression").css("border", "2px solid #00ff00");
                console.log("id is ", $( "#"+id ));
                $( "#"+id ).mouseover(function() {
                    console.log("% mouseover palette");
                    $(".reference_expression").css("border", "2px solid #00ff00");
                    // console.log("new exps ", $(".reference_expression"));

                    // var expressions = $(".reference_expression");
                    // for (var i = 0; i < expressions.length; i++){
                    //     expressions[i].css("border", "1 px solid #00ff00");
                    //     console.log("changed css of ", expressions[i]);
                    // }
                    // console.log("% ref exps are ", $(".reference_expression"));
                });

                $( "#"+id  ).mouseout(function() {
                  console.log("% mouseout palette");
                    $(".reference_expression").css("border", "1px solid #ccc");


                  // var expressions = $(".reference_expression");
                  //   for (var i = 0; i < expressions.length; i++){
                  //       expressions[i].css("border", "1 px solid #ccc");
                  //       console.log("changed css of ", expressions[i]);
                  //   }
                });

                console.log("% highlight expression drops")
            }


        };

        return SignalView;

    });