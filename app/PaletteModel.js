//SocketController.js
'use strict';
define(['emitter', 'app/id', 'app/Model'],

  function(EventEmitter, ID, Model) {

    var PaletteModel = class extends Model {

      constructor() {
        super();
        this.selected = "states";
        this.lastAuthoringRequest = null;
        this.data = {
          "states": {
            items: [{
              item_class: "block palette state_palette",
              item_name: "state",
              name: "state"
            }, {
              item_class: "block palette die_palette",
              item_name: "die",
              name: "die"
            }, {
              item_class: "block palette start_palette",
              item_name: "setup",
              name: "setup"
            }]
          },

          "sensor_properties": {
            items: [{
              item_class: "palette block property",
              item_name: "stylus_x",
              name: "x"
            }, {
              item_class: "block property palette",
              item_name: "stylus_y",
              name: "y"
            }, {
              item_class: "block property palette",
              item_name: "stylus_force",
              name: "force"
            }]
          },

          "brush_properties": {
            items: [{
              item_class: "block property palette",
              name: "delta x",
              item_name: "delta_x"
            }, {
              item_class: " block property palette",
              name: "delta y",
              item_name: "delta_y"

            }, {
              item_class: " block property palette",
              name: "rotation",
              item_name: "rotation"

            }, {
              item_class: " block property palette",
              name: "scale",
              item_name: "scale"

            }, {
              item_class: " block property palette",
              name: "weight",
              item_name: "weight"

            }, {
              item_class: " block property palette",
              name: "color",
              item_name: "color"

            }]
          },

          "generators": {
            items: [{
              item_class: "block property generator palette",
              name: "sine wave",
              item_name: "sine"
            }, {
              item_class: " block property generator palette",
              name: "uniform random",
              item_name: "uniform_random"

            }, {
              item_class: " block property generator palette",
              name: "range",
              item_name: "range"
            }, {
              item_class: " block property generator palette",
              name: "alternate",
              item_name: "alternate"
            }, {
              item_class: " block property generator palette",
              name: "random walk",
              item_name: "random_walk"
            }]
          },
          "brush_actions": {
            items: [{
              item_class: "block method palette",
              name: "spawn",
              item_name: "spawn"
            }, {
              item_class: " block method palette",
              name: "setOrigin",
              item_name: "setOrigin"
            }, {
              item_class: " block method palette",
              name: "newStroke",
              item_name: "newStroke"
            }, {
              item_class: " block method palette",
              name: "startTimer",
              item_name: "startTimer"
            }, {
              item_class: " block method palette",
              name: "stopTimer",
              item_name: "stopTimer"
            }, ]
          },

          "transitions": {
            items: [{
              item_class: "block transition palette",
              name: "tick",
              item_name: "tick"
            }, {
              item_class: "block transition palette",
              name: "stateComplete",
              item_name: "stateComplete"
            }, {
              item_class: "block transition palette",
              name: "onStylusDown",
              item_name: "onStylusDown"
            }, {
              item_class: "block transition palette",
              name: "onStylusUp",
              item_name: "onStylusUp"
            }, {
              item_class: "block transition palette",
              name: "onStylusMove",
              item_name: "onStylusMove"
            }]
          }
        };
      }

      elementDropped(x, y, data) {
        switch (data.type) {
          case "state":
            var name = data.name;
            var id = data.id;
            var type = "state_added";
            var transmit_data = {
              name: name,
              id: id,
              type: type
            };
            console.log("state created", transmit_data);
            this.lastAuthoringRequest = {
              x: x,
              y: y,
              data: transmit_data
            };
            this.emitter.emit("ON_STATE_ADDED", transmit_data);

            break;

        }
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

            case "state_added":
              console.log("initialize state called");
              console.log("adding state", this.lastAuthoringRequest.x, this.lastAuthoringRequest.y, this.lastAuthoringRequest.data);
              this.emitter.trigger("ON_INITIALIZE_STATE", [this.lastAuthoringRequest.x, this.lastAuthoringRequest.y, this.lastAuthoringRequest.data]);

              break;

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