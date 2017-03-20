//Expression.js
/* View class that describes mathematical expression built on top of CodeMirror 
(http://codemirror.net/
Some code here references expressions in Apparatus: https://github.com/cdglabs/apparatus
*/

"use strict";
define(["jquery","codemirror","app/Emitter"],
	

	function($,CodeMirror,Emitter){

		var Expression = class extends Emitter{


			constructor(el,id){
				 super();
				this.el = el;
				this.mappingId = id;
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
                


		}

		onChange(){
			console.log("code mirror",this.mappingId,"changed",this.mirror.getValue());
		}

		onMirrorMouseDown(){
			console.log("mirror mouse down");
		}

		addReference(data){
			this.mirror.setValue("%"+data.itemName+"%"+this.mirror.getValue());
			  var el = document.createElement("span");
                el.innerHTML = data.itemName;
                el.setAttribute("class", "block property " + data.reference_type);
              
                this.mirror.markText({
                    line: 0,
                    ch: 0
                }, {
                    line: 0,
                    ch: data.itemName.length
                }, {
                    replacedWith: el,
                    handleMouseEvents: true
                });

                return el;
            }


		};

		return Expression;

	

});