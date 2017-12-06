'use strict';

define(["app/Emitter"],

	function(Emitter) {

		class InspectorDataController extends Emitter {
			constructor() {
				super();
				this.inspectorData = [];
				this.targetId = null;
				this.behaviorId = null;
				this.currentValues = null;
			}

			setData(data) {
				console.log("inspector reveived data")
				this.inspectorData.push(data);
				this.trigger("DATA_UPDATED");
			}

			getLastData() {
				return this.inspectorData[this.inspectorData.length - 1];
			}


		}

		const instance = new InspectorDataController();
		Object.freeze(instance);

		return instance;
	});