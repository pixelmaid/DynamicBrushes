
var fs    = require('fs');
var path  = require('path');

var File = exports.File = function(filePath) {
	this.indent  = null;
	this.data    = void(0);
	this.path    = path.normalize(filePath);
};

exports.read = function(filePath, callback) {
	var file = new File(filePath);
	if (callback) {
		file.read(callback);
	} else {
		file.readSync();
	}
	return file;
};

// ------------------------------------------------------------------
//  File I/O

File.prototype.read = function(callback) {
	fs.readFile(this.path, 'utf8', this._afterRead.bind(this, callback));
};

File.prototype._afterRead = function(callback, err, json) {
	if (err) {
		return callback(err);
	}
	this._processJson(json);
	callback();
};

File.prototype.readSync = function(callback) {
	this._processJson(
		fs.readFileSync(this.path, 'utf8')
	);
};

File.prototype._processJson = function(json) {
	this.data = JSON.parse(json);
	this.indent = determineWhitespace(json);
};

File.prototype.write = function(callback, replacer, space) {
	var space = space || this.indent,
		json = JSON.stringify(this.data, replacer, space);
	fs.writeFile(this.path, json, callback);
};

File.prototype.writeSync = function(replacer, space) {
	var space = space || this.indent,
		json = JSON.stringify(this.data, replacer, space);
	fs.writeFileSync(this.path, json);
};

// ------------------------------------------------------------------
//  Property editing

File.prototype.get = function(key) {
	return this._resolve(key, function(scope, key, value) {
		return value;
	});
};

File.prototype.set = function(key, value) {
	this._resolve(key, function(scope, key) {
		scope[key] = value;
	});
	return this;
};

// Has a callback, but is NOT async
File.prototype._resolve = function(key, callback) {
	var current = this.data;
	var keys = key.split('.');
	key = keys.pop();
	keys.forEach(function(key) {
		current = current[key];
	});
	return callback(current, key, current[key]);
};

// ------------------------------------------------------------------

var findWhitespace = /^(\s+)/;
function determineWhitespace(contents) {
	var whitespace = 0;
	contents = contents.split('\n');
	for (var i = 0, c = contents.length; i < c; i++) {
		var match = findWhitespace.exec(contents);
		if (match && typeof match[1] === 'string') {
			if (match[1][0] === '\t') {
				whitespace = '\t';
				break;
			} else if (match[1].length < whitespace || ! whitespace) {
				whitespace = match[1].length;
			}
		}
	}
}

