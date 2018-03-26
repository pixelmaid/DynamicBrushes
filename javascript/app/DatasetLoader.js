//DataLoader.js
//Load in and process datasets

'use strict';
define(["jquery", 'emitter', 'app/id', 'app/Emitter'],

	function($, EventEmitter, ID, Emitter) {
		var DatasetLoader = class extends Emitter {

			constructor(	) {
				super();
				 //todo: should read this dynamically from the file folder
				this.filenames = ["BrainDrain.json","meteor.json","moment_formatted.json","MapMyRun.json", "sample_collection.json"];
			}

			loadCollection(data) {
				console.log("!!! LOAD COLLECTION", data);
				var self = this;
				var collections =  data;

				for (var i=0; i<collections.length; i++) {
					console.log("!!! inside collections ", collections[i]);
					var classType = collections[i]["classType"];
					var collectionId = collections[i]["id"];
					var collectionName = collections[i]["name"];
					var collectionSignals = collections[i]["signals"];

					//stylus, ui, generator, recording, dataset
					// switch (classType) {
					// 	case "live":
					// 	 	item_class = "palette block property sensor";
					// 	 	if (collectionName === "ui") item_class =  "palette block property ui";
					// 	 	break;
					// 	case "generator":
					// 	    item_class = "block property generator palette";
					// 	    break;
					// 	case "brush":
					// 		item_class = "block property palette";
					// 		if (collectionName === "spawn properties") item_class = "block property generator palette";
					// 		break;
					// 	case "recording":
					// 		item_class = "block recording palette";
					// 		break;
					// 	case "imported":
					// 		item_class = "block dataset palette";
					// 		break;
					// }


					var items = [];
					items.push({
	                classType: classType,
	                collectionId: collectionId,
	                collectionName: collectionName,
	                signals: [],
	            	});

					var signals = Array(collectionSignals.length);
					for (var j=0; j<collectionSignals.length;j++) {
							var signalClassType = collectionSignals[j]["classType"];
							var order = collectionSignals[j]["order"];
							var style = collectionSignals[j]["style"];
							var item_class = style + " palette block property "

							// console.log("! signal order is ", order);
							if (signalClassType === "TimeSignal") continue;
							signals[order] = {
							  item_class: item_class,
							  classType: signalClassType,
			                  fieldName: collectionSignals[j]["fieldName"],
			                  displayName: collectionSignals[j]["displayName"],
			                  help_text: "",
			                  style: style,
							};
						}								
					items[0].signals = signals;
					
					console.log("read from json", items);

					self.trigger("ON_DATA_LOADED",[collectionId,items,data]);

				}
			}

			loadCollectionFromFilename(filename) {
				var self = this;
				$.getJSON("app/sample_datasets/"+filename, function(data) {
					console.log("data loader loading json from file",data)
					self.trigger("ON_IMPORTED_DATASET_READY",[data])
				});			
			}

			// loadDataset(filename){
			// 	console.log("load dataset called ");
			// 	var self = this;
			// 	$.getJSON("app/sample_datasets/"+filename, function(data) {

			// 		var id = data["meta"]["id"];
			// 		var name = data["meta"]["name"];
			// 		var columns = data["meta"]["columns"];
			// 		var items = [];
			// 		items.push({
		 //                classType: "imported",
		 //                collectionId: id,
		 //                collectionName: name,
		 //                signals: [],
		 //            	});
			// 		var signals = [];
			// 		for (var i=0; i<columns.length;i++) {
			// 				if(columns[i]["dataTypeName"]!="meta_data"){
			// 				//if (c["fieldName"] == "mass" || c["fieldName"] == "reclat" || c["fieldName"] == "reclong" || c["fieldName"] == "year") {
			// 					signals.push({
			// 						item_class: "block dataset palette",
			// 						fieldName:  id+"_"+columns[i]["fieldName"],
			// 						displayName:columns[i]["name"],
			// 						classType: "imported"

			// 					});
			// 				}
							
			// 			}
			// 		items[0].signals = signals;
					
			// 		console.log("loaded data",columns, items);

			// 		self.trigger("ON_DATA_LOADED",[id,items,data]);
			// 	});

			// }
		};

		return DatasetLoader;

	});