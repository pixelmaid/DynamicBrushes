//ChartViewManager.js
'use strict';
define(["jquery", "app/id", "app/Emitter"],

	function($, ID, Emitter) {

		var GeneratorInspector = class extends Emitter {

			constructor(model, element) {
				super();
			}


			addDefaultValues(type,data){
				switch (type){
					case "random":
					data.min = 1;
					data.max = 100;
					break;
					case "alternate":
					data.values = [1,100];
					break;
					case "range":
					data.min = 1;
					data.max = 100;
					data.start = 1;
					data.stop = 100;
					break;
					case "random":
					data.min = 0;
					data.max = 100;
					break;
					case "sine":
					data.freq = 2;
					data.amp = 10;
					data.phase = 0
					break;

				}
				return data;
			}



		};
		return GeneratorInspector;
	});