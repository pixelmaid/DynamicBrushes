//SocketController.js
'use strict';
define(['emitter', 'app/id', 'app/Emitter', 'app/DatasetLoader'],

  function(EventEmitter, ID, Emitter,DatasetLoader) {

    var PaletteModel = class extends Emitter {

      constructor() {
        super();
        this.selected = "states";
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
          "states": {
            items: [{
              item_class: "block palette state_palette",
              fieldName: "state",
              name: "state",
              type: "state"
            }]
          },

          "sensor_properties": {
            items: [{
              item_class: "palette block property sensor",
              fieldName: "stylus_dx",
              name: "stylus delta x",
              type: "stylus",
              help_text: "returns the change in stylus x position each time the stylus is moved"
            }, {
              item_class: "block property palette sensor",
              fieldName: "stylus_dy",
              name: "stylus delta y",
              type: "sensor_prop",
              help_text: "returns the change in stylus y position each time the stylus is moved"

            }, {
              item_class: "palette block property sensor",
              fieldName: "stylus_x",
              name: "stylus x",
              type: "sensor_prop",
              help_text: "returns the change in stylus x position each time the stylus is moved"
            }, {
              item_class: "block property palette sensor",
              fieldName: "stylus_y",
              name: "stylus y",
              type: "sensor_prop",
              help_text: "returns the change in stylus y position each time the stylus is moved"

            },{
              item_class: "block property palette sensor",
              fieldName: "stylus_force",
              name: "force",
              type: "sensor_prop",
              help_text: "returns the current force (pressure) value of the stylus"

            }, {
              item_class: "block property palette sensor",
              fieldName: "stylus_angle",
              name: "angle",
              type: "sensor_prop",
              help_text: "returns the current angle of the stylus."

            }, {
              item_class: "block property palette sensor",
              fieldName: "stylus_speed",
              name: "speed",
              type: "sensor_prop",
              help_text: "returns the speed of the stylus."

            }, {
              item_class: "block property palette sensor",
              fieldName: "stylus_deltaAngle",
              name: "deltaAngle",
              type: "sensor_prop",
              help_text: "returns the angle of the direction the stylus is moving."

            }]
          },
          "ui_properties": {
            items: [{
              item_class: "palette block property ui",
              fieldName: "ui_hue",
              name: "hue",
              type: "ui"
            }, {
              item_class: "block property palette ui",
              fieldName: "ui_saturation",
              name: "saturation",
              type: "ui"
            }, {
              item_class: "block property palette ui",
              fieldName: "ui_lightness",
              name: "lightness",
              type: "ui"
            }, {
              item_class: " block property palette ui",
              fieldName: "ui_diameter",
              name: "diameter",
              type: "ui"

            }, {
              item_class: " block property palette ui",
              fieldName: "ui_alpha",
              name: "alpha",
              type: "ui"

            }]
          },  


          "brush_properties": {
            items: [{
                item_class: "block property palette",
                name: "delta x",
                fieldName: "dx",
                type: "brush_prop"
              }, {
                item_class: " block property palette",
                name: "delta y",
                fieldName: "dy",
                type: "brush_prop"

              }, {
                item_class: "block property palette",
                name: "x",
                fieldName: "x",
                type: "brush_prop"
              }, {
                item_class: " block property palette",
                name: "y",
                fieldName: "y",
                type: "brush_prop"

              },
               {
                item_class: "block property palette",
                name: "radius",
                fieldName: "radius",
                type: "brush_prop"
              }, {
                item_class: " block property palette",
                name: "theta",
                fieldName: "theta",
                type: "brush_prop"
              }, {
                item_class: " block property palette",
                name: "rotation",
                fieldName: "rotation",
                type: "brush_prop"

              }, {
                item_class: " block property palette",
                name: "scale x",
                fieldName: "sx",
                type: "brush_prop"

              }, {
                item_class: " block property palette",
                name: "scale y",
                fieldName: "sy",
                type: "brush_prop"

              },

              {
                item_class: " block property palette",
                name: "diameter",
                fieldName: "diameter",
                type: "brush_prop"

              },
              /*{
                           item_class: " block property palette",
                           name: "color",
                           fieldName: "color",
                           type:"brush_prop"

                         }*/
              {
                item_class: " block property palette",
                name: "hue",
                fieldName: "hue",
                type: "brush_prop"

              }, {
                item_class: " block property palette",
                name: "lightness",
                fieldName: "lightness",
                type: "brush_prop"

              }, {
                item_class: " block property palette",
                name: "saturation",
                fieldName: "saturation",
                type: "brush_prop"

              }, {
                item_class: " block property palette",
                name: "alpha",
                fieldName: "alpha",
                type: "brush_prop"

              }
            ]
          },

          "generators": {
            items: [{
                item_class: "block property generator palette",
                name: "sine wave",
                fieldName: "sine",
                type: "generator",
                help_text: "<img src ='images/sine_wave.gif'/>"
              },
              {
                item_class: "block property generator palette",
                name: "square wave",
                fieldName: "square",
                type: "generator",
                help_text: "<img src ='images/square_wave.gif'/>"
              },
                {
                item_class: "block property generator palette",
                name: "triangle wave",
                fieldName: "triangle",
                type: "generator",
                help_text: "<img src ='images/triangle_wave.gif'/>"
              },
              {
                item_class: " block property generator palette",
                name: "sawtooth wave",
                fieldName: "range",
                type: "generator",
                help_text: "<img src ='images/sawtooth_wave.gif'/>"
              }, 
               {
                item_class: " block property generator palette",
                name: "random",
                fieldName: "random",
                type: "generator",
                help_text: "returns a series of uniform random values"
              }, {
                item_class: " block property generator palette",
                name: "alternate",
                fieldName: "alternate",
                type: "generator",
                help_text: "returns a series of alternating values"
              },
              /*{
                           item_class: " block property generator palette",
                           name: "random walk",
                           fieldName: "random_walk",
                           type:"generator",
                           help_text: "returns a succession of random steps"
                         },*/
              {
                item_class: " block property generator palette",
                name: "spawn index",
                fieldName: "index",
                type: "generator",
                help_text: "returns the index of the brush instance"
              }, {
                item_class: " block property generator palette",
                name: "sibling count",
                fieldName: "siblingcount",
                type: "generator",
                help_text: "returns the number of siblings of the brush instance"
              },
              {
                item_class: " block property generator palette",
                name: "spawn level",
                fieldName: "level",
                type: "generator",
                help_text: "returns the number of connections between the brush instance and the root brush"
              },
              /*({ item_class: " block property generator palette",
                name: "ease",
                fieldName: "ease",
                type:"generator",
                help_text: "generator that eases in and out"
              }*/
            ]
          },

          "brush_actions": {
            items: [{
              item_class: "block method palette",
              name: "spawn",
              fieldName: "spawn",
              argument: true,
              type: "action"
            }, {
              item_class: " block method palette",
              name: "setOrigin",
              fieldName: "setOrigin",
              argument: true,
              type: "action"
            }, {
              item_class: " block method palette",
              name: "newStroke",
              fieldName: "newStroke",
              argument: true,
              type: "action"
            }, {
              item_class: " block method palette",
              name: "startTimer",
              fieldName: "startTimer",
              argument: false,
              type: "action"
            }, {
              item_class: " block method palette",
              name: "stopTimer",
              fieldName: "stopTimer",
              argument: false,
              type: "action"
            }, ]
          },

          "transitions": {
            items: [{
              item_class: "block transition palette",
              fieldName: "STYLUS_DOWN",
              name: "stylusDown",
              type: "transition"
            }, {
              item_class: "block transition palette",
              fieldName: "STYLUS_UP",
              name: "stylusUp",
              type: "transition"
            }, {
              item_class: "block transition palette",
              fieldName: "STYLUS_MOVE_BY",
              name: "stylusMoveBy",
              type: "transition"
            }, {
              item_class: "block transition palette",
              fieldName: "STYLUS_X_MOVE_BY",
              name: "stylusXMoveBy",
              type: "transition"
            }, {
              item_class: "block transition palette",
              fieldName: "STYLUS_Y_MOVE_BY",
              name: "stylusYMoveBy",
              type: "transition"
            }, {
              item_class: "block transition palette",
              fieldName: "TIME_INTERVAL",
              name: "timeInterval",
              type: "transition"
            }, {
              item_class: "block transition palette",
              fieldName: "DISTANCE_INTERVAL",
              name: "distanceInterval",
              type: "transition"
            }, {
              item_class: "block transition palette",
              fieldName: "INTERSECTION",
              name: "intersection",
              type: "transition"
            }]
          }
        };

      

        
      }

     



    };


    return PaletteModel;

  });