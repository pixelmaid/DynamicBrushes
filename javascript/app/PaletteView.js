//PaletteView.js
'use strict';
define(["jquery", "jquery-ui", "handlebars", "hbs!app/templates/palette", "app/id"],

    function($, jqueryui, Handlebars, paletteTemplate, ID) {

    const CollapsibleLists = (function(){

      // Makes all lists with the class 'collapsibleList' collapsible. The
      // parameter is:
      //
      // doNotRecurse - true if sub-lists should not be made collapsible
      function apply(doNotRecurse){

        [].forEach.call(document.getElementsByTagName('ul'), node => {

          if (node.classList.contains('collapsibleList')){

            applyTo(node, true);

            if (!doNotRecurse){

              [].forEach.call(node.getElementsByTagName('ul'), subnode => {
                subnode.classList.add('collapsibleList')
              });

            }

          }

        })

      }

      // Makes the specified list collapsible. The parameters are:
      //
      // node         - the list element
      // doNotRecurse - true if sub-lists should not be made collapsible
      function applyTo(node, doNotRecurse){
        [].forEach.call(node.getElementsByTagName('li'), li => {
            console.log("applied to called!!")

          if (!doNotRecurse || node === li.parentNode){


            li.style.userSelect       = 'none';
            li.style.MozUserSelect    = 'none';
            li.style.msUserSelect     = 'none';
            li.style.WebkitUserSelect = 'none';

            li.addEventListener('click', handleClick.bind(null, li));

            toggle(li);

          }

        });

      }

      // Handles a click. The parameter is:
      //
      // node - the node for which clicks are being handled
      function handleClick(node, e){

        let li = e.target;
        while (li.nodeName !== 'LI'){
          li = li.parentNode;
        }

        if (li === node){
          toggle(node);
        }

      }

      // Opens or closes the unordered list elements directly within the
      // specified node. The parameter is:
      //
      // node - the node containing the unordered list elements
      function toggle(node){

        const open = node.classList.contains('collapsibleListClosed');
        const uls  = node.getElementsByTagName('ul');

        [].forEach.call(uls, ul => {

          let li = ul;
          while (li.nodeName !== 'LI'){
            li = li.parentNode;
          }

          if (li === node){
            ul.style.display = (open ? 'block' : 'none');
          }

        });

        node.classList.remove('collapsibleListOpen');
        node.classList.remove('collapsibleListClosed');

        if (uls.length > 0){
          node.classList.add('collapsibleList' + (open ? 'Open' : 'Closed'));
        }

      }

      return {apply, applyTo};

    })();


        console.log("!!!!!!!! CollapsibleLists", CollapsibleLists);

        var live_btn, recordings_btn, datasets_btn, generator_btn, brushes_btn, drawings_btn;

        var PaletteView = class {

            constructor(model, element) {
                this.el = $(element);
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

                /* old buttons
                // states_btn = this.el.find('#states');
                generator_btn = this.el.find('#generators');
                brush_properties_btn = this.el.find('#brush_properties');
                sensor_properties_btn = this.el.find('#sensor_properties');
                ui_properties_btn = this.el.find('#ui_properties');
                brush_actions_btn = this.el.find('#brush_actions');
                transitions_btn = this.el.find('#transitions');
                datasets_btn = this.el.find('#datasets');
                this.btn_list = [states_btn, generator_btn, datasets_btn, brush_properties_btn, sensor_properties_btn, ui_properties_btn, brush_actions_btn, transitions_btn];
                */

                this.el.droppable({
                    drop: function(event, ui) {
                        console.log("dropped on canvas", ui);
                        $(ui.helper).remove(); //destroy clone
                        $(ui.draggable).remove(); //remove from list
                    }
                });

                this.generatePalette();

               this.model.addListener("ON_DATA_READY",function(data) {
                    this.updateSelectedPalette(data);
                }.bind(this));
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
                var html = paletteTemplate(data);
                this.el.find('#selected_palette').html(html);
                CollapsibleLists.apply(true);
                this.el.find(".palette").mousedown(function(event) {
                    if (!$(event.target).hasClass("tooltiptext")) {
                        var clone = $("<div id=" + $(event.target).attr('id') + "></div>");


                        clone.html($(event.target).attr('display_name'));
                        clone.attr("type", $(event.target).attr('type'));
                        clone.attr("name", $(event.target).attr('name'));
                        clone.attr("class", $(event.target).attr('class'));

                        clone.addClass("drag-n-drop");
                        console.log("cloning", clone);

                        clone.draggable();
                        clone.offset($(event.target).offset());
                        clone.prependTo("body").css('position', 'absolute');
                        clone.trigger(event);
                    }


                });
            }


        };

        return PaletteView;

    });