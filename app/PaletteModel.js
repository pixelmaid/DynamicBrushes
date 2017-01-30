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
            }, {
              item_class: "block palette die_palette",
              item_name: "die",
              name: "die",
              type:"state"
            }, {
              item_class: "block palette start_palette",
              item_name: "setup",
              name: "setup",
              type:"state"
            }]
          },

          "sensor_properties": {
            items: [{
              item_class: "palette block property",
              item_name: "stylus_x",
              name: "x",
              type:"sensor_prop"
            }, {
              item_class: "block property palette",
              item_name: "stylus_y",
              name: "y",
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
              item_name: "delta_x",
              type:"brush_prop"
            }, {
              item_class: " block property palette",
              name: "delta y",
              item_name: "delta_y",
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
              type:"action"
            }, {
              item_class: " block method palette",
              name: "setOrigin",
              item_name: "setOrigin",
              type:"action"
            }, {
              item_class: " block method palette",
              name: "newStroke",
              item_name: "newStroke",
              type:"action"
            }, {
              item_class: " block method palette",
              name: "startTimer",
              item_name: "startTimer",
              type:"action"
            }, {
              item_class: " block method palette",
              name: "stopTimer",
              item_name: "stopTimer",
              type:"action"
            }, ]
          },

          "transitions": {
            items: [{
              item_class: "block transition palette",
              name: "tick",
              item_name: "tick",
              type:"transition"
            }, {
              item_class: "block transition palette",
              name: "stateComplete",
              item_name: "stateComplete",
              type:"transition"
            }, {
              item_class: "block transition palette",
              name: "onStylusDown",
              item_name: "onStylusDown",
              type:"transition"
            }, {
              item_class: "block transition palette",
              name: "onStylusUp",
              item_name: "onStylusUp",
              type:"transition"
            }, {
              item_class: "block transition palette",
              name: "onStylusMove",
              item_name: "onStylusMove",
              type:"transition"
            }]
          }
        };
      }

     


      addBehavior() {
        var id = ID();
        var data = {
          type: "behavior_added",
          name: "behavior_" + id,
          id: id,
          states: [],
          transitions: []

        };
        this.lastAuthoringRequest = {
          data: data
        };
        this.emitter.emit("ON_BEHAVIOR_ADDED", data);
      }

      processAuthoringResponse(data) {
        console.log("process authoring_response called", data.result == "success", this.lastAuthoringRequest.data.type);
        if (data.result == "success") {
          switch (this.lastAuthoringRequest.data.type) {

            case "behavior_added":
              console.log("initialize behavior called");

              this.emitter.emit("ON_INITIALIZE_BEHAVIOR", this.lastAuthoringRequest.data);

              break;



          }

          this.lastAuthoringRequest = null;
        } else if (data.result == "fail") {

          //TODO: error handling code for authoring fail here
        }

      }
    };


    return PaletteModel;

  });