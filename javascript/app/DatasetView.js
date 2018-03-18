//DatasetView.js
'use strict';
define(["jquery", "jquery-ui", "handlebars", 'app/id'],

	function($, jqueryui, Handlebars, paletteTemplate, ID) {



		var DatasetView = class {

			constructor(model, element) {
				this.el = $(element);
				this.model = model;
				var self = this;

				for (var name of this.model.filenames) {
					this.el.append('<option value="'+name+'">'+name+'</option>');
				}
				this.el.change(function() {
					if(self.el.val()==="sample_collection.json"){
						self.model.loadCollection(self.el.val())
					}
					else if(self.el.val()!==""){
						self.model.loadDataset(self.el.val());
					}
				});


			}


		};

		return DatasetView;

	});