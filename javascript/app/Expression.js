//Expression.js
/* View class that describes mathematical expression built on top of CodeMirror 
(http://codemirror.net/
Some code here references expressions in Apparatus: https://github.com/cdglabs/apparatus
*/

"use strict";
define(["jquery", "codemirror", "app/Emitter", "app/id"],


    function($, CodeMirror, Emitter, ID) {

        var Expression = class extends Emitter {


            constructor(el, mappingId, expressionId) {
                super();
                this.el = el;
                this.addReferenceCheck = false;
                this.mappingId = mappingId;
                this.id = expressionId;
                this.references = {};
                this.marks = {};
                this.mirror = CodeMirror.fromTextArea(el, {
                    mode: "javascript",

                    // Needed for auto-expanding height to work properly.
                    viewportMargin: Infinity,

                    // Use tabs to indent.
                    smartIndent: true,
                    indentUnit: 2,
                    tabSize: 2,
                    indentWithTabs: true,

                    // Disable scrolling
                    lineWrapping: true,
                    scrollbarStyle: "null",

                    // Disable undo
                    undoDepth: 0

                });

                this.mirror.setSize("auto", 24);
                this.mirror.on("change", function() {
                    this.onChange();
                }.bind(this));
                this.mirror.on("mousedown", function() {
                    this.onMirrorMouseDown();
                }.bind(this));
                this.mirror.setValue("");


            }

            onChange() {
                //does not trigger if change is the result of adding a reference
                if (!this.addReferenceCheck) {
                    console.log("code mirror", this.mappingId, "changed", this.mirror.getValue());
                     var removedReferences = [];
                     var text = this.getText();
                     for(var p in this.references){
                        if(this.references.hasOwnProperty(p)){
                            var inText = text.search(p);
                            if(inText == -1){
                                removedReferences.push(p);
                            }
                        }

                    }

                    console.log("changed",removedReferences,text);
                    this.trigger("ON_TEXT_CHANGED", [this,removedReferences]);
                }
            }

            onMirrorMouseDown() {
                console.log("mirror mouse down");
            }

            getText() {
                return this.mirror.getValue();
            }

            getPropertyList() {
                var propList = [];
                for (var key in this.references){
                 if(this.references.hasOwnProperty(key)){
                        propList.push(key);
                    }
                }
                return propList;
            }

            containsActive(){
                for(var p in this.references){
                    if(this.references.hasOwnProperty(p)){
                        if(this.references[p][0] == "stylus" || this.references[p][0] == "ui" ){
                            return true;
                        }
                    }
                }
                return false;
            }

            removeReference(referenceId) {
                this.addReferenceCheck = true;

                delete this.references[referenceId];
                delete this.marks[referenceId];
                var referenceString = '%' + referenceId + '%';
                var currentText = this.getText();
                var newText = currentText.replace(referenceString, "");
                console.log("old text, new text", currentText, newText);
                this.mirror.setValue(newText);
                this.renderMarks();
                this.addReferenceCheck = false;

            }

            renderMarks() {
                this.clearAllMarks();

                this.addReferenceCheck = true;
                var currentText = this.getText();

                for (var key in this.marks) {
                    if (this.marks.hasOwnProperty(key)) {
                        var markText = '%' + key + '%';

                        var startIndex = currentText.indexOf(markText);
                        var endIndex = startIndex + markText.length;
                        console.log("start index, end index", startIndex, endIndex);
                        var el = this.marks[key];
                        this.mirror.markText({
                            line: 0,
                            ch: startIndex
                        }, {
                            line: 0,
                            ch: endIndex
                        }, {
                            replacedWith: el,
                            handleMouseEvents: true
                        });


                    }
                }

                this.addReferenceCheck = false;


            }

            clearAllMarks() {
                this.addReferenceCheck = true;
                var text = this.getText();
                this.mirror.setValue("");
                this.mirror.setValue(text);
                this.addReferenceCheck = false;


            }

            updateReferences(expressionText, expressionPropertyList) {
                this.addReferenceCheck = true;
                this.mirror.setValue(expressionText);
                this.addReferenceCheck = false;
                this.references = expressionPropertyList;
               var els = [];
                for (var key in expressionPropertyList) {
                    if (expressionPropertyList.hasOwnProperty(key)) {
                        var propList = expressionPropertyList[key];
                        var type;
                        if (propList[0] == "stylus") {
                            type = "sensor_prop";
                        } 
                        else if (propList[0] == "ui") {
                            type = "ui_prop";
                        } else {
                            type = "generator";
                        }
                        var name = propList[1][0];
                         var referenceDisplayName = propList[2][0];
                      
                        els.push($(this.addMark(referenceDisplayName, type, key, name, propList[0])));
                    }
                }
                this.renderMarks();
                return els;
            }


            addMark(referenceId, referenceType, referenceDisplayName) {
                var el = document.createElement("span");
                el.innerHTML = referenceDisplayName;
                el.setAttribute("class", "block property " + referenceType);
                el.setAttribute("type", referenceType);
                el.setAttribute("parent_id", this.id);
                el.setAttribute("id", referenceId);
                this.marks[referenceId] = el;
                return el;
            }

            addReference(referenceId, referenceType, referenceDisplayName) {
                this.references[referenceId] = [referenceType, referenceDisplayName];
                console.log("added reference", referenceDisplayName);
                this.addReferenceCheck = true;
                this.mirror.setValue(this.mirror.getValue() + "%" + referenceId + "%");
                this.addReferenceCheck = false;
                var el = this.addMark(referenceId, referenceType, referenceDisplayName);

                this.renderMarks();
                return $(el);
            }


        };



        return Expression;



    });