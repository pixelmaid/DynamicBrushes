//SocketController.js
'use strict';
define(['emitter'],

function(EventEmitter) {

  var PaletteModel = class {

    constructor() {
      this.emitter = new EventEmitter();
      this.selected = "states";
      this.data ={
        "states":{
          items: [{
            item_class: "block palette state_palette jsplumb-draggable" ,
            name: "state"
          }, {
            item_class: "block palette die_palette jsplumb-draggable",
            name: "die"
          }, {
            item_class: "block palette start_palette jsplumb-draggable",
            name: "setup"
          }]
        },

        "sensor_properties":{
          items: [{
            item_class: "block property jsplumb-draggable",
            name: "x"
          }, {
            item_class: " block property jsplumb-draggable",
            name: "y"
          }, {
            item_class: " block property jsplumb-draggable",
            name: "force"
          }]
        },

        "brush_properties":{
           items: [{
            item_class: "block property jsplumb-draggable",
            name: "delta x"
          }, {
            item_class: " block property jsplumb-draggable",
            name: "delta y"
          }, 
          {
          item_class: " block property jsplumb-draggable",
            name: "rotation"
          }, 
          {
            item_class: " block property jsplumb-draggable",
            name: "scale"
          }, 
          {
            item_class: " block property jsplumb-draggable",
            name: "weight"
          }]
        }, 

         "generators":{
           items: [{
            item_class: "block property generator jsplumb-draggable",
            name: "sine wave"
          }, {
            item_class: " block property generator jsplumb-draggable",
            name: "uniform random"
          }, 
          {
          item_class: " block property generator jsplumb-draggable",
            name: "range"
          },      
          {
            item_class: " block property generator jsplumb-draggable",
            name: "alternate"
          },
           {
            item_class: " block property generator jsplumb-draggable",
            name: "random walk"
          }]
        }, 
        "brush_actions":{
           items: [{
            item_class: "block method  jsplumb-draggable",
            name: "spawn"
          }, {
            item_class: " block method jsplumb-draggable",
            name: "setOrigin"
          }, 
          {
          item_class: " block method jsplumb-draggable",
            name: "newStroke"
          }, 
          {
           item_class: " block method jsplumb-draggable",
            name: "startTimer"
          },
           {
             item_class: " block method jsplumb-draggable",
            name: "stopTimer"
          },
          ]
        },

        "transitions":{
          items: [{
            item_class: "block transition palette jsplumb-draggable",
            name: "tick"
          }, {
            item_class: "block transition palette jsplumb-draggable",
            name: "stateComplete"
          },
          {
           item_class: "block transition palette jsplumb-draggable",
            name: "onStylusDown"
          },
          {
           item_class: "block transition palette jsplumb-draggable",
            name: "onStylusUp"
          },
          {
          item_class: "block transition palette jsplumb-draggable",
            name: "onStylusMove"
          }]
        }
      };
    }
  };


return PaletteModel;

});