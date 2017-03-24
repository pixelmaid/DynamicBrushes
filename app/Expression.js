//Expression.js
/* View class that describes mathematical expression built on top of CodeMirror 
(http://codemirror.net/
Some code here references expressions in Apparatus: https://github.com/cdglabs/apparatus
*/

"use strict";
define(["jquery","codemirror","app/Emitter","app/id"],
	

	function($,CodeMirror,Emitter,ID){

		var Expression = class extends Emitter{


			constructor(el,mappingId,expressionId){
				 super();
				this.el = el;
                this.addReferenceCheck = false;
				this.mappingId = mappingId;
                this.id = expressionId;
                this.references = [];
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

                this.mirror.setSize(100, 24);
  				this.mirror.on("change", function(){this.onChange();}.bind(this));
			  	this.mirror.on("mousedown", function(){this.onMirrorMouseDown();}.bind(this));
                this.mirror.setValue("");


		}

		onChange(){
            //does not trigger if change is the result of adding a reference
            if(!this.addReferenceCheck){
			console.log("code mirror",this.mappingId,"changed",this.mirror.getValue());
            this.trigger("ON_TEXT_CHANGED",[this]);
            }
		}

		onMirrorMouseDown(){
			console.log("mirror mouse down");
		}

        getText(){
            return this.mirror.getValue();
        }

        getPropertyList(){
            return this.references;
        }

		addReference(type,referenceName,referenceProperties,referencePropId,displayName){
            this.references.push([referenceName,referenceProperties]);
            this.addReferenceCheck = true;
			this.mirror.setValue("%"+referencePropId+"%"+this.mirror.getValue());
            this.addReferenceCheck = false;
			  var el = document.createElement("span");
                el.innerHTML = displayName;
                el.setAttribute("class", "block property " + type);
              
                this.mirror.markText({
                    line: 0,
                    ch: 0
                }, {
                    line: 0,
                    ch: referencePropId.length+2
                }, {
                    replacedWith: el,
                    handleMouseEvents: true
                });

                return el;
            }


		};



		return Expression;

	

});