//SaveView.js
'use strict';
define(["jquery"],

    function($) {
        var save_btn, saveas_btn, file_select;
        var project_counter = 1;

        var SaveView = class {

            constructor(model, element) {
                this.el = $(element);
                this.model = model;
                save_btn = $("#save");
                saveas_btn= $("#saveas");
                file_select = $("#fileselect");
                var self = this;
                console.log("el,savebutton",this.el,save_btn,model);
                this.model.addListener("ON_SAVED_FILES_UPDATED", function(){
                    this.onSavedFilesUpdated();
                }.bind(this));

                file_select.change(function(event){
                    console.log("file select change",file_select.val());
                    self.model.loadSavedFile(file_select.val());
                });

                $("#save").click(function(event) {
                    console.log("save button click",self.model.currentName);
                    if (!self.model.currentName) {
                        self.model.currentName = prompt("give your project a name", "myproject_" + project_counter);
                        project_counter++;
                    }
                    if (self.model.currentName !== null) {
                        self.model.save(self.model.currentName);

                    }

                });

                /*saveas_btn.click(function(event) {
                   
                        currentName = prompt("give your project a name", "myproject_" + project_counter);
                
                    if (currentName !== null) {
                        this.model.save(currentName);

                    }

                });*/


            }

            onSavedFilesUpdated(){
                console.log("saved files updated called");
                var filelist = this.model.saved_files;
                file_select.find('option').remove();
                for (var key in filelist){
                    if(filelist.hasOwnProperty(key)){
                        var name = filelist[key];
                        if(name !== ""){
                            file_select.append($('<option>', {value:key, text:name}));
                        }
                    }
                }
                if(this.model.currentFile){
                file_select.val(this.model.currentFile);
                console.log("currentfile",this.model.currentFile,this.model.currentName);
                }
            }



        };

        return SaveView;

    });