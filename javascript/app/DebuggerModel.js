//Debugger

"use strict";

define(["app/Emitter"],

    function(Emitter) {


        var DebuggerModel = class extends Emitter {


            constructor() {
                super();
                this.data = {};
            }

            update(data) {
                this.data = data;
                this.trigger("DATA_UPDATED");
            }
        };


        return DebuggerModel;


    });