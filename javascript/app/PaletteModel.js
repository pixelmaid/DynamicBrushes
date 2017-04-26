//SocketController.js
'use strict';
define(['emitter', 'app/id', 'app/Emitter'],

  function(EventEmitter, ID, Emitter) {

    var PaletteModel = class extends Emitter {

      constructor() {
        super();
        this.selected = "states";
        this.lastAuthoringRequest = null;
        this.data = {
          "states": {
            items: [{
              item_class: "block palette state_palette",
              item_name: "state",
              name: "state",
              type:"state"
            }/*, {
              item_class: "block palette die_palette",
              item_name: "die",
              name: "die",
              type:"state"
            }, {
              item_class: "block palette setup_palette",
              item_name: "setup",
              name: "setup",
              type:"state"
            }*/]
          },

          "sensor_properties": {
            items: [{
              item_class: "palette block property sensor",
              item_name: "stylus_dx",
              name: "dx",
              type:"sensor_prop"
            }, {
              item_class: "block property palette sensor",
              item_name: "stylus_dy",
              name: "dy",
              type:"sensor_prop"
            }, {
              item_class: "block property palette sensor",
              item_name: "stylus_force",
              name: "force",
              type:"sensor_prop"
            }]
          },

          "brush_properties": {
            items: [{
              item_class: "block property palette",
              name: "delta x",
              item_name: "dx",
              type:"brush_prop"
            }, {
              item_class: " block property palette",
              name: "delta y",
              item_name: "dy",
              type:"brush_prop"

            }, {
              item_class: " block property palette",
              name: "rotation",
              item_name: "rotation",
              type:"brush_prop"

            }, {
              item_class: " block property palette",
              name: "scale",
              item_name: "scale",
              type:"brush_prop"

            }, {
              item_class: " block property palette",
              name: "diameter",
              item_name: "diameter",
              type:"brush_prop"

            }, /*{
              item_class: " block property palette",
              name: "color",
              item_name: "color",
              type:"brush_prop"

            }*/{
              item_class: " block property palette",
              name: "hue",
              item_name: "hue",
              type:"brush_prop"

            },
            {
              item_class: " block property palette",
              name: "lightness",
              item_name: "lightness",
              type:"brush_prop"

            },
            {
              item_class: " block property palette",
              name: "saturation",
              item_name: "saturation",
              type:"brush_prop"

            },
            {
              item_class: " block property palette",
              name: "alpha",
              item_name: "alpha",
              type:"brush_prop"

            }]
          },

          "generators": {
            items: [{
              item_class: "block property generator palette",
              name: "sine wave",
              item_name: "sine",
              type:"generator",
              help_text: "returns a series of values corresponding to a sine wave"
            }, {
              item_class: " block property generator palette",
              name: "random",
              item_name: "random",
              type:"generator",
              help_text: "returns a series of uniform random values"
            }, {
              item_class: " block property generator palette",
              name: "range",
              item_name: "range",
              type:"generator",
               help_text: "returns cycling range of values"
            }, {
              item_class: " block property generator palette",
              name: "alternate",
              item_name: "alternate",
              type:"generator",
              help_text: "returns a series of alternating values"
            }, /*{
              item_class: " block property generator palette",
              name: "random walk",
              item_name: "random_walk",
              type:"generator",
              help_text: "returns a succession of random steps"
            },*/
            { item_class: " block property generator palette",
              name: "index",
              item_name: "index",
              type:"generator",
              help_text: "returns the index of the brush instance"
            }
            ]
          },

          "brush_actions": {
            items: [{
              item_class: "block method palette",
              name: "spawn",
              item_name: "spawn",
              argument: true,
              type:"action"
            }, {
              item_class: " block method palette",
              name: "setOrigin",
              item_name: "setOrigin",
              argument: true,
              type:"action"
            }, {
              item_class: " block method palette",
              name: "newStroke",
              item_name: "newStroke",
              argument: true,
              type:"action"
            }, {
              item_class: " block method palette",
              name: "startTimer",
              item_name: "startTimer",
              argument: false,
              type:"action"
            }, {
              item_class: " block method palette",
              name: "stopTimer",
              item_name: "stopTimer",
              argument: false,
              type:"action"
            }, ]
          },

          "transitions": {
            items: [
            {
              item_class: "block transition palette",
              item_name: "STYLUS_DOWN",
              name: "stylusDown",
              type:"transition"
            }, {
              item_class: "block transition palette",
              item_name: "STYLUS_UP",
              name: "stylusUp",
              type:"transition"
            }, {
              item_class: "block transition palette",
              item_name: "STYLUS_MOVE_BY",
              name: "stylusMoveBy",
              type:"transition"
            },
             {
              item_class: "block transition palette",
              item_name: "STYLUS_X_MOVE_BY",
              name: "stylusXMoveBy",
              type:"transition"
            },
             {
              item_class: "block transition palette",
              item_name: "STYLUS_Y_MOVE_BY",
              name: "stylusYMoveBy",
              type:"transition"
            },
            {
              item_class: "block transition palette",
              item_name: "TIME_INTERVAL",
              name: "timeInterval",
              type:"transition"
            },
             {
              item_class: "block transition palette",
              item_name: "DISTANCE_INTERVAL",
              name: "distanceInterval",
              type:"transition"
            },
              {
              item_class: "block transition palette",
              item_name: "INTERSECTION",
              name: "intersection",
              type:"transition"
            }]
          }
        };
      }

     


    
    };


    return PaletteModel;

  });