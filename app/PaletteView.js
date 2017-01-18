//PaletteView.js
'use strict';
define(["jquery", "handlebars", "hbs!app/templates/palette"],

    function($, Handlebars, paletteTemplate) {

        var states_btn, generator_btn, brush_properties_btn, sensor_properties_btn, brush_actions_btn, transitions_btn;
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
               
                for (var i = 0; i < btn_list.length; i++) {

                    btn_list[i].click(function(event) {
                         for(var j = 0;j<btn_list.length;j++){
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
            }


        };

        return PaletteView;

    });