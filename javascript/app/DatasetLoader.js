//DataLoader.js
//Load in and process datasets

'use strict';
define(["jquery", 'emitter', 'app/id', 'app/Emitter'],

	function($, EventEmitter, ID, Emitter) {
		var DatasetLoader = class extends Emitter {

			constructor(	) {
				super();
				 //todo: should read this dynamically from the file folder
				this.filenames = ["BrainDrain.json","meteor.json","moment_formatted.json","MapMyRun.json"];
			}

			loadDataset(filename){
				var self = this;
				$.getJSON("app/sample_datasets/"+filename, function(data) {

					var id = data["meta"]["view"]["id"]
					var columns = data["meta"]["view"]["columns"];
					var items = [];
					for (var i=0; i<columns.length;i++) {
							if(columns[i]["dataTypeName"]!="meta_data"){
							//if (c["fieldName"] == "mass" || c["fieldName"] == "reclat" || c["fieldName"] == "reclong" || c["fieldName"] == "year") {
								items.push({
									item_class: "block dataset palette",
									item_name:  id+"_"+columns[i]["item_name"],
									name:columns[i]["name"],
									type: "dataset"

								});
							}
							
						}
					
					console.log("loaded data",columns, items);

					self.trigger("ON_DATA_LOADED",[id,items,data]);
				});

			}
		};

		return DatasetLoader;

	});