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
				var self = this;
				var collections =  data["collections"];

				for (var i=0; i<collections.length; i++) {
					var classType = collections[i]["classType"];
					var collectionId = collections[i]["id"];
					var collectionName = collections[i]["name"];
					var collectionSignals = collections[i]["signals"];
					var item_class = "block palette"
					switch (classType) {
						case "live":
						 	item_class = "palette block property sensor";
						 	if (collectionName === "ui") item_class =  "palette block property ui";
						 	break;
						case "generator":
						    item_class = "block property generator palette";
						    break;
						case "brush":
							item_class = "block property palette";
							if (collectionName === "spawn properties") item_class = "block property generator palette";
							break;
						case "recording":
							item_class = "block recording palette";
							break;
						case "imported":
							item_class = "block dataset palette";
							break;
					}


					var items = [];
					items.push({
	                classType: classType,
	                collectionId: collectionId,
	                collectionName: collectionName,
	                signals: [],
	            	});

					var signals = [];
					for (var j=0; j<collectionSignals.length;j++) {
								signals.push({
								  item_class: item_class,
				                  fieldName: collectionSignals[j]["fieldName"],
				                  displayName: collectionSignals[j]["displayName"],
				                  help_text: ""
								});
							}								
					items[0].signals = signals;
					
					console.log("read from json", items);

					self.trigger("ON_DATA_LOADED",[collectionId,items,data]);

				}
			}

			loadCollectionFromFilename(filename) {
				var self = this;
				$.getJSON("app/sample_datasets/"+filename, function(data) {
					self.loadCollection(data);
				});			
			}

			loadDataset(filename){
				console.log("load dataset called ");
				var self = this;
				$.getJSON("app/sample_datasets/"+filename, function(data) {

					var id = data["meta"]["id"];
					var name = data["meta"]["name"];
					var columns = data["meta"]["columns"];
					var items = [];
					items.push({
		                classType: "imported",
		                collectionId: id,
		                collectionName: name,
		                signals: [],
		            	});
					var signals = [];
					for (var i=0; i<columns.length;i++) {
							if(columns[i]["dataTypeName"]!="meta_data"){
							//if (c["fieldName"] == "mass" || c["fieldName"] == "reclat" || c["fieldName"] == "reclong" || c["fieldName"] == "year") {
								signals.push({
									item_class: "block dataset palette",
									fieldName:  id+"_"+columns[i]["fieldName"],
									displayName:columns[i]["name"],
									classType: "imported"

								});
							}
							
						}
					items[0].signals = signals;
					
					console.log("loaded data",columns, items);

					self.trigger("ON_DATA_LOADED",[id,items,data]);
				});

			}
		};

		return DatasetLoader;

	});