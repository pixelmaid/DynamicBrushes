/************************************************************************************************************
	Editable select
	Copyright (C) September 2005  DHTMLGoodies.com, Alf Magne Kalleland
	
	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
	
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Lesser General Public License for more details.
	
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
	
	Dhtmlgoodies.com., hereby disclaims all copyright interest in this script
	written by Alf Magne Kalleland.
	
	Alf Magne Kalleland, 2006
	Owner of DHTMLgoodies.com
		
	************************************************************************************************************/


// Path to arrow images
var arrowImage = './images/dropdown_arrow.png'; // Regular arrow


var selectBoxIds = 0;
var currentlyOpenedOptionBox = false;
var editableSelect_activeArrow = false;
var activeOption;

define(["jquery"],
	function($) {

		var EditableSelect = class {

			constructor() {

			}

			/*static selectBox_switchImageUrl() {
				if (this.src.indexOf(arrowImage) >= 0) {
					this.src = this.src.replace(arrowImage, arrowImageOver);
				} else {
					this.src = this.src.replace(arrowImageOver, arrowImage);
				}


			}*/

			static selectBox_showOptions() {
				if (editableSelect_activeArrow && editableSelect_activeArrow != this) {
					editableSelect_activeArrow.src = arrowImage;

				}
				editableSelect_activeArrow = this;

				var numId = this.id.replace(/[^\d]/g, '');
				var optionDiv = document.getElementById('selectBoxOptions' + numId);
				if (optionDiv.style.display == 'block') {
					optionDiv.style.display = 'none';
					if (navigator.userAgent.indexOf('MSIE') >= 0) {
						document.getElementById('selectBoxIframe' + numId).style.display = 'none';
					}
					//this.src = arrowImageOver;
				} else {
					optionDiv.style.display = 'block';
					if (navigator.userAgent.indexOf('MSIE') >= 0) {
						document.getElementById('selectBoxIframe' + numId).style.display = 'block';
					}
					//this.src = arrowImageDown;
					if (currentlyOpenedOptionBox && currentlyOpenedOptionBox != optionDiv) {
						currentlyOpenedOptionBox.style.display = 'none';
					}
					currentlyOpenedOptionBox = optionDiv;
				}
			}

			static selectOptionValue() {
				var parentNode = this.parentNode.parentNode;
				var textInput = parentNode.getElementsByTagName('INPUT')[0];
				console.log("select option value changed ", textInput.id);

				textInput.value = this.innerHTML;
				$('#' + textInput.id).attr("argumentId", this.id);
				$('#' + textInput.id).attr("value", this.innerHTML);
				
				this.parentNode.style.display = 'none';
				//document.getElementById('arrowSelectBox' + parentNode.id.replace(/[^\d]/g, '')).src = arrowImageOver;

				if (navigator.userAgent.indexOf('MSIE') >= 0) {
					document.getElementById('selectBoxIframe' + parentNode.id.replace(/[^\d]/g, '')).style.display = 'none';
				}
				$('#' + textInput.id).trigger("change",[true]);

			}
			static highlightSelectBoxOption() {
				if (this.style.backgroundColor == 'rgba(0, 0, 0, 0.25') {
					this.style.backgroundColor = '';
					this.style.color = '';
				} else {
					this.style.backgroundColor = 'rgba(0, 0, 0, 0.25)';
					this.style.color = '#FFF';
				}

				if (activeOption) {
					activeOption.style.backgroundColor = '';
					activeOption.style.color = '';
				}
				activeOption = this;

			}

			static createEditableSelect(dest) {
				console.log("dest=",dest.offsetWidth,dest); 
				dest.className = 'selectBoxInput';
				var div = document.createElement('DIV');
				div.style.styleFloat = 'left';
				div.style.width = '90px';
				div.style.position = 'relative';
				div.id = 'selectBox' + selectBoxIds;
				var parent = dest.parentNode;
				parent.insertBefore(div, dest);
				div.appendChild(dest);
				div.className = 'selectBox';
				div.style.zIndex = 10000 - selectBoxIds;

				var img = document.createElement('IMG');
				img.src = arrowImage;
				img.className = 'selectBoxArrow';

				//img.onmouseover = this.selectBox_switchImageUrl;
				//img.onmouseout = this.selectBox_switchImageUrl;
				img.onclick = this.selectBox_showOptions;
				img.id = 'arrowSelectBox' + selectBoxIds;

				div.appendChild(img);

				var optionDiv = document.createElement('DIV');
				optionDiv.id = 'selectBoxOptions' + selectBoxIds;
				optionDiv.className = 'selectBoxOptionContainer';
				optionDiv.style.width = 'auto';
				div.appendChild(optionDiv);

				if (navigator.userAgent.indexOf('MSIE') >= 0) {
					var iframe = document.createElement('<IFRAME src="about:blank" frameborder=0>');
					iframe.style.width = optionDiv.style.width;
					iframe.style.height = optionDiv.offsetHeight + 'px';
					iframe.style.display = 'none';
					iframe.id = 'selectBoxIframe' + selectBoxIds;
					div.appendChild(iframe);
				}

				if (dest.getAttribute('selectBoxOptions')) {
					var options = dest.getAttribute('selectBoxOptions').split(';');
					var optionsTotalHeight = 0;
					var optionArray = [];
					for (var no = 0; no < options.length; no++) {
						var name = options[no].split("|")[1];
						var id = options[no].split("|")[0];
						var anOption = document.createElement('DIV');
						anOption.innerHTML = name;
						anOption.id = id;
						anOption.className = 'selectBoxAnOption';
						anOption.onclick = this.selectOptionValue;
						anOption.style.width = 'auto';
						anOption.onmouseover = this.highlightSelectBoxOption;
						optionDiv.appendChild(anOption);
						optionsTotalHeight = optionsTotalHeight + anOption.offsetHeight;
						optionArray.push(anOption);
					}
					if (optionsTotalHeight > optionDiv.offsetHeight) {
						for (var i = 0; i < optionArray.length; i++) {
							optionArray[i].style.width = optionDiv.style.width.replace('px', '') - 22 + 'px';
						}
					}
					optionDiv.style.display = 'none';
					optionDiv.style.visibility = 'visible';
				}
				
			
				$('#' + dest.id).change(function(event,isSelect){
					if(!isSelect){
						console.log("method destination changed",dest.id);
						$('#' + dest.id).attr("argumentId", "nil");
						$('#' + dest.id).attr("value", $('#' + dest.id).val());

					}
				});

				selectBoxIds = selectBoxIds + 1;
			}
		};
		return EditableSelect;

	});