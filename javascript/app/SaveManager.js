//Save Manager
"use strict";
define(["app/Emitter"],

	function(Emitter) {

		var saved_params, s3, bucket;


		var SaveManager = class extends Emitter {
			constructor() {
				super();
				this.saved_files = {};
				this.example_files = {};
				this.backup_files = {};
				this.currentFile = null;
				this.currentName = "my_project";
				this.codename = null;
			}


			save(filename) {
				if (this.codename !== null) {
					this.currentname = filename;
					var data = {
						type: "save_request",
						filename: filename,
						artistName: this.codename

					};
					this.emitter.emit("ON_SAVE_EVENT", data);
				} else {
					alert("cannot save, no artistname");
				}

			}

			loadRequest(filename) {

				if (this.codename !== null) {

					var data = {
						type: "load_request",
						filename: filename,
						artistName: this.codename

					};
					this.emitter.emit("ON_SAVE_EVENT", data);
				} else {
					alert("cannot load, no artistname");
				}



			}

			setCurrentFilename(filename,fileval) {
				this.currentName = filename;
				this.currentFile = fileval;
				console.log("current name =",this.currentName,this.currentFile);
				this.emitter.emit("ON_NEW_FILE_SELECTED");
			}

			loadSavedFile(fileval) {
				var filename = this.saved_files[fileval];
				this.currentFile = fileval;
				this.currentName = filename;
				this.loadRequest(fileval);
			}

			loadSavedExampleFile(fileval) {
				var filename = this.example_files[fileval];
				console.log("load saved example file",filename,fileval)
				this.currentFile = fileval;
				this.currentName = filename;
				this.loadRequest(fileval);
			}

			
			updateFileList(storage_data) {
				var cleanedFiles = {};
				for (var file in storage_data.filelist){
					if(storage_data.filelist.hasOwnProperty(file)){
						console.log(storage_data.filelist[file]);
						if(storage_data.filelist[file]!=="old_saved"){
							cleanedFiles[file] = storage_data.filelist[file];
						}
					}
				}
				this.saved_files = cleanedFiles;

				this.trigger("ON_SAVED_FILES_UPDATED");
			}

			updateExampleList(storage_data) {
				this.example_files = storage_data.filelist;

				this.trigger("ON_EXAMPLE_FILES_UPDATED");
			}

			setCodeName(codename) {
				this.codename = codename;
				console.log("set save manager codename to", codename);
			}

			savedFileExists(filename) {
				for (var key in this.saved_files) {
					if (this.saved_files.hasOwnProperty(key)) {
						var name = this.saved_files[key];
						if (name == filename) {
							return true;
						}
					}
				}
				return false;
			}

			loadStorageData(data) {
				console.log("load storage data called", data);
				var storage_data = data.data;
				var filelist = storage_data.filelist;
				var type = storage_data.type;
				if (type == "save") {
					console.log("type = save");
					this.currentFile = storage_data.filename;
					this.currentName = this.currentFile.split("/")[1];
					this.updateFileList(storage_data);
				} else if (type == "backup") {
					this.backup_files = filelist;
				} else if (type == "filelist") {
					if(storage_data.targetFolder == "examples/"){
						this.updateExampleList(storage_data);
					}
					else{
						this.updateFileList(storage_data);
					}
				}
			}



		};
		return SaveManager;



	});