//DataLoader.js
//Load in and process datasets

'use strict';
define(["jquery", 'emitter', 'app/id', 'app/Emitter'],

	function($, EventEmitter, ID, Emitter) {
		var DataLoader = class extends Emitter {

			constructor() {
				super();
			}

			loadData(){
				var self = this;
				$.getJSON("app/sample_datasets/BrainDrain.json", function(data) {
					var meteor_data = data;

					var id = data["meta"]["view"]["id"]
					var columns = meteor_data["meta"]["view"]["columns"];
					var items = [];
					for (var i=0; i<columns.length;i++) {
							if(columns[i]["dataTypeName"]!="meta_data"){
							//if (c["fieldName"] == "mass" || c["fieldName"] == "reclat" || c["fieldName"] == "reclong" || c["fieldName"] == "year") {
								items.push({
									item_class: "block data palette",
									item_name:  id+"_"+columns[i]["name"],
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

		return DataLoader;

	});