//Debugger

"use strict";

define(["app/Emitter"],

    function(Emitter) {


        var DebuggerModel = class extends Emitter {


            constructor(collection) {
                super();
                this.data = {};
                this.collection = collection;
            }

            update(data) {
                this.data = data;
                this.trigger("DATA_UPDATED");
            }

            highlight(type, isOn) {
                if (isOn) {
                    this.trigger("DATA_HIGHLIGHTED", [type]);
                } else {
                    this.trigger("DATA_UNHIGHLIGHTED");
                }
            }

            updateSelectedIndex(index){
               this.collection.updateSelectedIndex(index) 
            }
        };


        return DebuggerModel;


    });