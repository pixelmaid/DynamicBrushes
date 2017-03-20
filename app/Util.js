'use strict';
define([],

	function($) {


		var Util = class {


			static charToLineCh(string, char) {
				var stringUpToChar = string.substr(0, char);
				var lines = stringUpToChar.split("\n");
				return {
					line: lines.length - 1,
					ch: lines[lines.length - 1].length
				};
			}


		};
		return Util;

	});