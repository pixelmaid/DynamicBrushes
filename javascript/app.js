 // For any third party dependencies, like jQuery, place them in the lib folder.

// Configure loading modules from the lib directory,
// except for 'app' ones, which are in a sibling
// directory.
requirejs.config({
	baseUrl: 'lib',
	paths: {
		hbs: 'require-handlebars-plugin/hbs',
		'paper': 'paper-full',
		'jquery': 'jquery',
		'emitter': 'EventEmitter',
		'heir': 'heir',
		'd3' : 'd3.min',
		'svg':'svg',
		'handlebars':'handlebars',
		'jsplumb' : 'jsPlumb',
		'text': 'text',
		'jquery-ui': 'jquery-ui',
		'codemirror': 'codemirror',
		'editableselect': 'editableselect',	
		'contextmenu': 'jquery.contextMenu',
		'aws-sdk-js':'aws-sdk-js/dist/aws-sdk.min',
		app: '../app'
	},

	shim:{
		 "aws-sdk-js": {
            exports: "AWS"
        }
	},
	hbs: { // optional
    		helpers: true,            // default: true
    		helperDirectory : "../templates/helpers/",
    		templateExtension: 'hbs', // default: 'hbs'
    		partialsUrl: ''           // default: ''
		}
});

// Start loading the main app file. Put all of
// your application logic in there.
requirejs(['app/main']);

