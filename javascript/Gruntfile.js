module.exports = function(grunt) {

  grunt.initConfig({
    jshint: {
      files: ['Gruntfile.js', 'app/**/*.js'],
      options: {
        globals: {
          jQuery: true
        }
      }
    },
    watch: {
      files: ['<%= jshint.files %>'],
      tasks: ['jshint']
    },
    clean: { options: {
      force: true
    },
      folder:["/Applications/XAMPP/xamppfiles/htdocs/PaletteKnife_desktop/"]
    },
    copy: {
  files: {
    cwd: '.',  // set working folder / root to copy
    src: '**/*',           // copy all files and subfolders
    dest: '/Applications/XAMPP/xamppfiles/htdocs/PaletteKnife_desktop',    // destination folder
    expand: true           // required when using cwd
  }
},
handlebars: {
    all: {
        files: {
            "app/templates.js": ["templates/**/*.hbs"]
        }
    }
}

  });

  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks("grunt-contrib-clean");
 // grunt.loadNpmTasks('grunt-contrib-handlebars');


    grunt.registerTask("build", [
        "clean", "copy", 
    ]);

  grunt.registerTask('default', ['jshint']);

};