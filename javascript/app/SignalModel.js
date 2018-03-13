//SignalModel.js
'use strict';
define(['emitter', 'app/id', 'app/Emitter', 'app/DatasetLoader'],

  function(EventEmitter, ID, Emitter,DatasetLoader) {

    var SignalModel = class extends Emitter {

      constructor() {
        super();
        this.selected = "live_input";
        this.lastAuthoringRequest = null;
        this.data={};
        this.datasetLoader = new DatasetLoader();
        this.datasetLoader.addListener("ON_DATA_LOADED",  function(id,items,data) {
                    this.onDatasetLoaded(id,items,data);
                }.bind(this));
        this.setupData();
      }

      onDatasetLoaded(id,items,data){

        this.data["datasets"] = {items:items};
        console.log("data_loaded",items,this);
        this.trigger("ON_DATASET_READY",[id,data]);
      }

      setupData(){
        this.data = {
         
          "live_input": {
            items: [
            //originally brush_properties
            {
                item_class: "block property palette",
                name: "delta x",
                item_name: "dx",
                type: "brush_prop"
              }, {
                item_class: " block property palette",
                name: "delta y",
                item_name: "dy",
                type: "brush_prop"

              }, {
                item_class: "block property palette",
                name: "x",
                item_name: "x",
                type: "brush_prop"
              }, {
                item_class: " block property palette",
                name: "y",
                item_name: "y",
                type: "brush_prop"

              },
               {
                item_class: "block property palette",
                name: "radius",
                item_name: "radius",
                type: "brush_prop"
              }, {
                item_class: " block property palette",
                name: "theta",
                item_name: "theta",
                type: "brush_prop"
              }, {
                item_class: " block property palette",
                name: "rotation",
                item_name: "rotation",
                type: "brush_prop"

              }, {
                item_class: " block property palette",
                name: "scale x",
                item_name: "sx",
                type: "brush_prop"

              }, {
                item_class: " block property palette",
                name: "scale y",
                item_name: "sy",
                type: "brush_prop"

              },

              {
                item_class: " block property palette",
                name: "diameter",
                item_name: "diameter",
                type: "brush_prop"

              },
              /*{
                           item_class: " block property palette",
                           name: "color",
                           item_name: "color",
                           type:"brush_prop"

                         }*/
              {
                item_class: " block property palette",
                name: "hue",
                item_name: "hue",
                type: "brush_prop"

              }, {
                item_class: " block property palette",
                name: "lightness",
                item_name: "lightness",
                type: "brush_prop"

              }, {
                item_class: " block property palette",
                name: "saturation",
                item_name: "saturation",
                type: "brush_prop"

              }, {
                item_class: " block property palette",
                name: "alpha",
                item_name: "alpha",
                type: "brush_prop"

              },
              //originally sensor input
              {
              item_class: "palette block property sensor",
              item_name: "stylus_dx",
              name: "stylus delta x",
              type: "stylus",
              help_text: "returns the change in stylus x position each time the stylus is moved"
            }, {
              item_class: "block property palette sensor",
              item_name: "stylus_dy",
              name: "stylus delta y",
              type: "sensor_prop",
              help_text: "returns the change in stylus y position each time the stylus is moved"

            }, {
              item_class: "palette block property sensor",
              item_name: "stylus_x",
              name: "stylus x",
              type: "sensor_prop",
              help_text: "returns the change in stylus x position each time the stylus is moved"
            }, {
              item_class: "block property palette sensor",
              item_name: "stylus_y",
              name: "stylus y",
              type: "sensor_prop",
              help_text: "returns the change in stylus y position each time the stylus is moved"

            },{
              item_class: "block property palette sensor",
              item_name: "stylus_force",
              name: "force",
              type: "sensor_prop",
              help_text: "returns the current force (pressure) value of the stylus"

            }, {
              item_class: "block property palette sensor",
              item_name: "stylus_angle",
              name: "angle",
              type: "sensor_prop",
              help_text: "returns the current angle of the stylus."

            }, {
              item_class: "block property palette sensor",
              item_name: "stylus_speed",
              name: "speed",
              type: "sensor_prop",
              help_text: "returns the speed of the stylus."

            }, {
              item_class: "block property palette sensor",
              item_name: "stylus_deltaAngle",
              name: "deltaAngle",
              type: "sensor_prop",
              help_text: "returns the angle of the direction the stylus is moving."
            },
            //originally ui_inputs
            {
              item_class: "palette block property ui",
              item_name: "ui_hue",
              name: "hue",
              type: "ui"
            }, {
              item_class: "block property palette ui",
              item_name: "ui_saturation",
              name: "saturation",
              type: "ui"
            }, {
              item_class: "block property palette ui",
              item_name: "ui_lightness",
              name: "lightness",
              type: "ui"
            }, {
              item_class: " block property palette ui",
              item_name: "ui_diameter",
              name: "diameter",
              type: "ui"

            }, {
              item_class: " block property palette ui",
              item_name: "ui_alpha",
              name: "alpha",
              type: "ui"

            }
            ]
          },

          "generators": {
            items: [{
                item_class: "block property generator palette",
                name: "sine wave",
                item_name: "sine",
                type: "generator",
                help_text: "<img src ='images/sine_wave.gif'/>"
              },
              {
                item_class: "block property generator palette",
                name: "square wave",
                item_name: "square",
                type: "generator",
                help_text: "<img src ='images/square_wave.gif'/>"
              },
                {
                item_class: "block property generator palette",
                name: "triangle wave",
                item_name: "triangle",
                type: "generator",
                help_text: "<img src ='images/triangle_wave.gif'/>"
              },
              {
                item_class: " block property generator palette",
                name: "sawtooth wave",
                item_name: "range",
                type: "generator",
                help_text: "<img src ='images/sawtooth_wave.gif'/>"
              }, 
               {
                item_class: " block property generator palette",
                name: "random",
                item_name: "random",
                type: "generator",
                help_text: "returns a series of uniform random values"
              }, {
                item_class: " block property generator palette",
                name: "alternate",
                item_name: "alternate",
                type: "generator",
                help_text: "returns a series of alternating values"
              },
              /*{
                           item_class: " block property generator palette",
                           name: "random walk",
                           item_name: "random_walk",
                           type:"generator",
                           help_text: "returns a succession of random steps"
                         },*/
              {
                item_class: " block property generator palette",
                name: "spawn index",
                item_name: "index",
                type: "generator",
                help_text: "returns the index of the brush instance"
              }, {
                item_class: " block property generator palette",
                name: "sibling count",
                item_name: "siblingcount",
                type: "generator",
                help_text: "returns the number of siblings of the brush instance"
              },
              {
                item_class: " block property generator palette",
                name: "spawn level",
                item_name: "level",
                type: "generator",
                help_text: "returns the number of connections between the brush instance and the root brush"
              },
              /*({ item_class: " block property generator palette",
                name: "ease",
                item_name: "ease",
                type:"generator",
                help_text: "generator that eases in and out"
              }*/
            ]
          },

         
        };

      

        
      }

     



    };


    return SignalModel;

  });