//PaletteView.js
'use strict';
define(["jquery", "jquery-ui", "handlebars", "hbs!app/templates/palette", 'app/id'],

    function($, jqueryui, Handlebars, paletteTemplate, ID) {

        var  states_btn, generator_btn, brush_properties_btn, sensor_properties_btn, brush_actions_btn, transitions_btn;
        var btn_list;

        var PaletteView = class {

            constructor(model, element) {
                this.el = $(element);
                this.model = model;
                var self = this;
                self.updateSelectedPalette(model.data[model.selected]);

                states_btn = this.el.find('#states');
                generator_btn = this.el.find('#generators');
                brush_properties_btn = this.el.find('#brush_properties');
                sensor_properties_btn = this.el.find('#sensor_properties');
                brush_actions_btn = this.el.find('#brush_actions');
                transitions_btn = this.el.find('#transitions');
                btn_list = [states_btn, generator_btn, brush_properties_btn, sensor_properties_btn, brush_actions_btn, transitions_btn];

                
                this.el.droppable({
                    drop: function(event, ui) {
                        console.log("dropped on canvas",ui);
                        $(ui.helper).remove(); //destroy clone
                        $(ui.draggable).remove(); //remove from list
                    }
                });

               

                for (var i = 0; i < btn_list.length; i++) {

                    btn_list[i].click(function(event) {
                        for (var j = 0; j < btn_list.length; j++) {
                            btn_list[j].removeClass("selected");
                        }
                        self.model.selected = $(event.target).attr('id');
                        $(event.target).addClass("selected");
                        self.updateSelectedPalette(self.model.data[self.model.selected]);
                    });
                }
            }


            updateSelectedPalette(data) {
                var html = paletteTemplate(data);
                this.el.find('#selected_palette').html(html);
                this.el.find(".palette").mousedown(function(event) {
                    var clone = $("<div id=" + $(event.target).attr('id') + "></div>");

                    var attributes = $(event.target).prop("attributes");

                    $.each(attributes, function() {
                        clone.attr(this.name, this.value);
                    });
                    clone.html($(event.target).attr('display_name'));
                    clone.addClass("drag-n-drop");
                    console.log("cloning", clone);

                    clone.draggable();
                    clone.offset($(event.target).offset());
                    clone.prependTo("body").css('position', 'absolute');
                    clone.trigger(event);



                });
            }


        };

        return PaletteView;

    });