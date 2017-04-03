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
              item_class: "palette block property",
              item_name: "stylus_dx",
              name: "dx",
              type:"sensor_prop"
            }, {
              item_class: "block property palette",
              item_name: "stylus_dy",
              name: "dy",
              type:"sensor_prop"
            }, {
              item_class: "block property palette",
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
              name: "weight",
              item_name: "weight",
              type:"brush_prop"

            }, {
              item_class: " block property palette",
              name: "color",
              item_name: "color",
              type:"brush_prop"

            }]
          },

          "generators": {
            items: [{
              item_class: "block property generator palette",
              name: "sine wave",
              item_name: "sine",
              type:"generator"
            }, {
              item_class: " block property generator palette",
              name: "uniform random",
              item_name: "uniform_random",
              type:"generator"

            }, {
              item_class: " block property generator palette",
              name: "range",
              item_name: "range",
              type:"generator"
            }, {
              item_class: " block property generator palette",
              name: "alternate",
              item_name: "alternate",
              type:"generator"
            }, {
              item_class: " block property generator palette",
              name: "random walk",
              item_name: "random_walk",
              type:"generator"
            }]
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
            items: [{
              item_class: "block transition palette",
              item_name: "TICK",
              name: "tick",
              type:"transition"
            }, /*{
              item_class: "block transition palette",
              item_name: "STATE_COMPLETE",
              name: "stateComplete",
              type:"transition"
            },*/ {
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
              item_name: "STYLUS_MOVE",
              name: "stylusMove",
              type:"transition"
            }]
          }
        };
      }

     


    
    };


    return PaletteModel;

  });