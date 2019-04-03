//DatasetView.js
'use strict';
define(["jquery", "jquery-ui", "handlebars"],

	function($, jqueryui, Handlebars) {



		var DatasetView = class {

			constructor(model, element) {
				this.el = $(element);
				this.model = model;
				var self = this;

				for (var name of this.model.filenames) {
					this.el.append('<option value="'+name+'">'+name+'</option>');
				}
				this.el.change(function() {
					console.log("loading called on ", self.el.val());
					if(self.el.val()!==""){
						self.model.loadCollectionFromFilename(self.el.val());
					}
				});


			}


		};

		return DatasetView;

	});