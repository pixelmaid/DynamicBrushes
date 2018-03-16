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
            {
              item_class: "palette block property sensor",
              fieldName: "stylus_x",
              displayName: "stylus x",
              collectionName: "stylus",
              classType: "live",
              help_text: "returns the change in stylus x position each time the stylus is moved"
            }, {
              item_class: "block property palette sensor",
              fieldName: "stylus_y",
              displayName: "stylus y",
              collectionName: "stylus",
              classType: "live",
              help_text: "returns the change in stylus y position each time the stylus is moved"

            },
            {
              item_class: "palette block property sensor",
              fieldName: "stylus_dx",
              displayName: "stylus delta x",
              collectionName: "stylus",
              classType: "live",
              help_text: "returns the change in stylus x position each time the stylus is moved"
            }, {
              item_class: "block property palette sensor",
              fieldName: "stylus_dy",
              displayName: "stylus delta y",
              collectionName: "stylus",
              classType: "live",
              help_text: "returns the change in stylus y position each time the stylus is moved"

            }, {
              item_class: "block property palette sensor",
              fieldName: "stylus_force",
              displayName: "force",
              collectionName: "stylus",
              classType: "live",
              help_text: "returns the current force (pressure) value of the stylus"

            }, {
              item_class: "block property palette sensor",
              fieldName: "stylus_angle",
              displayName: "angle",
              collectionName: "stylus",
              classType: "live",
              help_text: "returns the current angle of the stylus."

            }, {
              item_class: "block property palette sensor",
              fieldName: "stylus_speed",
              displayName: "speed",
              collectionName: "stylus",
              classType: "live",
              help_text: "returns the speed of the stylus."

            }, {
              item_class: "block property palette sensor",
              fieldName: "stylus_deltaAngle",
              displayName: "deltaAngle",
              collectionName: "stylus",
              classType: "live",
              help_text: "returns the angle of the direction the stylus is moving."
            },
            //originally ui_inputs
            {
              item_class: "palette block property ui",
              fieldName: "ui_hue",
              displayName: "hue",
              collectionName: "ui",
              classType: "live"
            }, {
              item_class: "block property palette ui",
              fieldName: "ui_saturation",
              displayName: "saturation",
              collectionName: "ui",
              classType: "live"
            }, {
              item_class: "block property palette ui",
              fieldName: "ui_lightness",
              displayName: "lightness",
              collectionName: "ui",
              classType: "live"
            }, {
              item_class: " block property palette ui",
              fieldName: "ui_diameter",
              displayName: "diameter",
              collectionName: "ui",
              classType: "live"

            }, {
              item_class: " block property palette ui",
              fieldName: "ui_alpha",
              displayName: "alpha",
              collectionName: "ui",
              classType: "live"
            }
            ]
          },

          "generators": {
            items: [{
                item_class: "block property generator palette",
                displayName: "sine wave",
                fieldName: "sine",
                classType: "generator",
                help_text: "<img src ='images/sine_wave.gif'/>"
              },
              {
                item_class: "block property generator palette",
                displayName: "square wave",
                fieldName: "square",
                classType: "generator",
                help_text: "<img src ='images/square_wave.gif'/>"
              },
                {
                item_class: "block property generator palette",
                displayName: "triangle wave",
                fieldName: "triangle",
                classType: "generator",
                help_text: "<img src ='images/triangle_wave.gif'/>"
              },
              {
                item_class: " block property generator palette",
                displayName: "sawtooth wave",
                fieldName: "range",
                classType: "generator",
                help_text: "<img src ='images/sawtooth_wave.gif'/>"
              }, 
               {
                item_class: " block property generator palette",
                displayName: "random",
                fieldName: "random",
                classType: "generator",
                help_text: "returns a series of uniform random values"
              }, {
                item_class: " block property generator palette",
                displayName: "alternate",
                fieldName: "alternate",
                classType: "generator",
                help_text: "returns a series of alternating values"
              },

            ]
          },

          "brushes": {
            items: [//originally brush_properties
            {
                item_class: "block property palette",
                displayName: "delta x",
                fieldName: "dx",
                classType: "brush"
              }, {
                item_class: " block property palette",
                displayName: "delta y",
                fieldName: "dy",
                classType: "brush"

              }, {
                item_class: "block property palette",
                displayName: "x",
                fieldName: "x",
                classType: "brush"
              }, {
                item_class: " block property palette",
                displayName: "y",
                fieldName: "y",
                classType: "brush"

              },
               {
                item_class: "block property palette",
                displayName: "radius",
                fieldName: "radius",
                classType: "brush"
              }, {
                item_class: " block property palette",
                displayName: "theta",
                fieldName: "theta",
                classType: "brush"
              }, {
                item_class: " block property palette",
                displayName: "rotation",
                fieldName: "rotation",
                classType: "brush"

              }, {
                item_class: " block property palette",
                displayName: "scale x",
                fieldName: "sx",
                classType: "brush"

              }, {
                item_class: " block property palette",
                displayName: "scale y",
                fieldName: "sy",
                classType: "brush"

              },

              {
                item_class: " block property palette",
                displayName: "diameter",
                fieldName: "diameter",
                classType: "brush"

              },

              {
                item_class: " block property palette",
                displayName: "hue",
                fieldName: "hue",
                classType: "brush"

              }, {
                item_class: " block property palette",
                displayName: "lightness",
                fieldName: "lightness",
                classType: "brush"

              }, {
                item_class: " block property palette",
                displayName: "saturation",
                fieldName: "saturation",
                classType: "brush"

              }, {
                item_class: " block property palette",
                displayName: "alpha",
                fieldName: "alpha",
                classType: "brush"

              },
             {
                item_class: " block property generator palette",
                displayName: "spawn index",
                fieldName: "index",
                classType: "brush",
                help_text: "returns the index of the brush instance"
              }, {
                item_class: " block property generator palette",
                displayName: "sibling count",
                fieldName: "siblingcount",
                classType: "brush",
                help_text: "returns the number of siblings of the brush instance"
              },
              {
                item_class: " block property generator palette",
                displayName: "spawn level",
                fieldName: "level",
                classType: "brush",
                help_text: "returns the number of connections between the brush instance and the root brush"
              },
            ]
          },

          "drawings": {
            items: [
            ]
          },
         
        };

      

        
      }

     



    };


    return SignalModel;

  });